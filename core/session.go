package core

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"runtime"
	"sync"
	"time"

	"github.com/codeEmitter/gitrob/common"
	"github.com/gin-gonic/gin"
	"github.com/google/go-github/github"
	"github.com/xanzy/go-gitlab"
	"golang.org/x/oauth2"
)

const (
	GitHubAccessTokenEnvVariable = "GITROB_GITHUB_ACCESS_TOKEN"
	GitLabAccessTokenEnvVariable = "GITROB_GITLAB_ACCESS_TOKEN"
	StatusInitializing           = "initializing"
	StatusGathering              = "gathering"
	StatusAnalyzing              = "analyzing"
	StatusFinished               = "finished"
)

type Stats struct {
	sync.Mutex

	StartedAt    time.Time
	FinishedAt   time.Time
	Status       string
	Progress     float64
	Targets      int
	Repositories int
	Commits      int
	Files        int
	Findings     int
}

type Github struct {
	AccessToken string         `json:"-"`
	Client      *github.Client `json:"-"`
}

type GitLab struct {
	AccessToken string `json:"-"`
	Client      *gitlab.Client
	UserID      int64
}

type Session struct {
	sync.Mutex

	Version      string
	Options      Options `json:"-"`
	Out          *Logger `json:"-"`
	Stats        *Stats
	Github       Github
	GitLab       GitLab
	Router       *gin.Engine `json:"-"`
	Targets      []*common.Owner
	Repositories []*common.Repository
	Findings     []*Finding
}

func (s *Session) Start() {
	s.InitStats()
	s.InitLogger()
	s.InitThreads()
	s.InitAccessToken()
	s.ValidateTokenConfig()
	s.InitAPIClient()
	s.InitRouter()
}

func (s *Session) Finish() {
	s.Stats.FinishedAt = time.Now()
	s.Stats.Status = StatusFinished
}

func (s *Session) AddTarget(target *common.Owner) {
	s.Lock()
	defer s.Unlock()
	for _, t := range s.Targets {
		if *target.ID == *t.ID {
			return
		}
	}
	s.Targets = append(s.Targets, target)
}

func (s *Session) AddRepository(repository *common.Repository) {
	s.Lock()
	defer s.Unlock()
	for _, r := range s.Repositories {
		if *repository.ID == *r.ID {
			return
		}
	}
	s.Repositories = append(s.Repositories, repository)
}

func (s *Session) AddFinding(finding *Finding) {
	s.Lock()
	defer s.Unlock()
	s.Findings = append(s.Findings, finding)
}

func (s *Session) InitStats() {
	if s.Stats != nil {
		return
	}
	s.Stats = &Stats{
		StartedAt:    time.Now(),
		Status:       StatusInitializing,
		Progress:     0.0,
		Targets:      0,
		Repositories: 0,
		Commits:      0,
		Files:        0,
		Findings:     0,
	}
}

func (s *Session) InitLogger() {
	s.Out = &Logger{}
	s.Out.SetDebug(*s.Options.Debug)
	s.Out.SetSilent(*s.Options.Silent)
}

func (s *Session) InitAccessToken() {
	if *s.Options.GithubAccessToken == "" {
		s.Github.AccessToken = os.Getenv(GitHubAccessTokenEnvVariable)
	} else {
		s.Github.AccessToken = *s.Options.GithubAccessToken
	}
	if *s.Options.GitLabAccessToken == "" {
		s.GitLab.AccessToken = os.Getenv(GitLabAccessTokenEnvVariable)
	} else {
		s.GitLab.AccessToken = *s.Options.GitLabAccessToken
	}
}

func (s *Session) ValidateTokenConfig() {
	if s.GitLab.AccessToken != "" && s.Github.AccessToken != "" {
		s.Out.Fatal("Both a GitLab and Github token are present.  Only one may be set.")
	}
	if s.GitLab.AccessToken == "" && s.Github.AccessToken == "" {
		s.Out.Fatal("No valid API token was found.\n")
	}
}

func (s *Session) InitAPIClient() {
	userAgent := fmt.Sprintf("%s v%s", Name, Version)
	if s.Github.AccessToken != "" {
		ctx := context.Background()
		ts := oauth2.StaticTokenSource(
			&oauth2.Token{AccessToken: s.Github.AccessToken},
		)
		tc := oauth2.NewClient(ctx, ts)
		s.Github.Client = github.NewClient(tc)
		s.Github.Client.UserAgent = userAgent
	}
	if s.GitLab.AccessToken != "" {
		s.GitLab.Client = gitlab.NewClient(nil, s.GitLab.AccessToken)
		s.GitLab.Client.UserAgent = userAgent
	}
}

func (s *Session) InitThreads() {
	if *s.Options.Threads == 0 {
		numCPUs := runtime.NumCPU()
		s.Options.Threads = &numCPUs
	}
	runtime.GOMAXPROCS(*s.Options.Threads + 2) // thread count + main + web server
}

func (s *Session) InitRouter() {
	bind := fmt.Sprintf("%s:%d", *s.Options.BindAddress, *s.Options.Port)
	s.Router = NewRouter(s)
	go func(sess *Session) {
		if err := sess.Router.Run(bind); err != nil {
			sess.Out.Fatal("Error when starting web server: %s\n", err)
		}
	}(s)
}

func (s *Session) SaveToFile(location string) error {
	sessionJson, err := json.Marshal(s)
	if err != nil {
		return err
	}
	err = ioutil.WriteFile(location, sessionJson, 0644)
	if err != nil {
		return err
	}
	return nil
}

func (s *Stats) IncrementTargets() {
	s.Lock()
	defer s.Unlock()
	s.Targets++
}

func (s *Stats) IncrementRepositories() {
	s.Lock()
	defer s.Unlock()
	s.Repositories++
}

func (s *Stats) IncrementCommits() {
	s.Lock()
	defer s.Unlock()
	s.Commits++
}

func (s *Stats) IncrementFiles() {
	s.Lock()
	defer s.Unlock()
	s.Files++
}

func (s *Stats) IncrementFindings() {
	s.Lock()
	defer s.Unlock()
	s.Findings++
}

func (s *Stats) UpdateProgress(current int, total int) {
	s.Lock()
	defer s.Unlock()
	if current >= total {
		s.Progress = 100.0
	} else {
		s.Progress = (float64(current) * float64(100)) / float64(total)
	}
}

func NewSession() (*Session, error) {
	var err error
	var session Session

	if session.Options, err = ParseOptions(); err != nil {
		return nil, err
	}

	if *session.Options.Save != "" && FileExists(*session.Options.Save) {
		return nil, errors.New(fmt.Sprintf("File: %s already exists.", *session.Options.Save))
	}

	if *session.Options.Load != "" {
		if !FileExists(*session.Options.Load) {
			return nil, errors.New(fmt.Sprintf("Session file %s does not exist or is not readable.", *session.Options.Load))
		}
		data, err := ioutil.ReadFile(*session.Options.Load)
		if err != nil {
			return nil, err
		}
		if err := json.Unmarshal(data, &session); err != nil {
			return nil, errors.New(fmt.Sprintf("Session file %s is corrupt or generated by an old version of Gitrob.", *session.Options.Load))
		}
	}

	session.Version = Version
	session.Start()

	return &session, nil
}
