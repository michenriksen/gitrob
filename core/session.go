package core

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"gitrob/matching"
	"runtime"
	"strings"
	"sync"
	"time"

	"gitrob/common"
	gh "gitrob/github"
	gl "gitrob/gitlab"

	"github.com/gin-gonic/gin"
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
	AccessToken string `json:"-"`
}

type GitLab struct {
	AccessToken string `json:"-"`
}

type Session struct {
	sync.Mutex

	Version         string
	Options         Options        `json:"-"` //do not unmarshal to json on save
	Out             *common.Logger `json:"-"` //do not unmarshal to json on save
	Stats           *Stats
	Github          Github         `json:"-"` //do not unmarshal to json on save
	GitLab          GitLab         `json:"-"` //do not unmarshal to json on save
	Client          common.IClient `json:"-"` //do not unmarshal to json on save
	Router          *gin.Engine    `json:"-"` //do not unmarshal to json on save
	Targets         []*common.Owner
	Repositories    []*common.Repository
	Findings        []*matching.Finding
	IsGithubSession bool                `json:"-"` //do not unmarshal to json on save
	Signatures      matching.Signatures `json:"-"` //do not unmarshal to json on save
}

func (s *Session) Initialize() {
	s.InitStats()
	s.InitLogger()
	s.InitThreads()
	s.InitAccessToken()
	s.InitSignatures()
	s.ValidateTokenConfig()
	s.InitAPIClient()
	s.InitRouter()
}

func (s *Session) InitSignatures() {
	s.Signatures = matching.Signatures{}
	err := s.Signatures.Load(*s.Options.Mode)
	if err != nil {
		s.Out.Fatal("Error loading signatures: %s\n", err)
	}
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

func (s *Session) AddFinding(finding *matching.Finding) {
	s.Lock()
	defer s.Unlock()
	const MaxStrLen = 100
	s.Findings = append(s.Findings, finding)
	s.Out.Warn(" %s: %s, %s\n", strings.ToUpper(finding.Action), "File Match: "+finding.FileSignatureDescription, "Content Match: "+finding.ContentSignatureDescription)
	s.Out.Info("  Path......................: %s\n", finding.FilePath)
	s.Out.Info("  Repo......................: %s\n", finding.CloneUrl)
	s.Out.Info("  Message...................: %s\n", common.TruncateString(finding.CommitMessage, MaxStrLen))
	s.Out.Info("  Author....................: %s\n", finding.CommitAuthor)
	if finding.FileSignatureComment != "" {
		s.Out.Info("  FileSignatureComment......: %s\n", common.TruncateString(finding.FileSignatureComment, MaxStrLen))
	}
	if finding.ContentSignatureComment != "" {
		s.Out.Info("  ContentSignatureComment...:%s\n", common.TruncateString(finding.ContentSignatureComment, MaxStrLen))
	}
	s.Out.Info("  File URL...: %s\n", finding.FileUrl)
	s.Out.Info("  Commit URL.: %s\n", finding.CommitUrl)
	s.Out.Info(" ------------------------------------------------\n\n")
	s.Stats.IncrementFindings()
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
	s.Out = &common.Logger{}
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
	if *s.Options.Load == "" {
		if s.GitLab.AccessToken != "" && s.Github.AccessToken != "" {
			s.Out.Fatal("Both a GitLab and Github token are present.  Only one may be set.\n")
		}
		if s.GitLab.AccessToken == "" && s.Github.AccessToken == "" {
			s.Out.Fatal("No valid API token was found.\n")
		}
	}
	s.IsGithubSession = s.Github.AccessToken != ""
}

func (s *Session) InitAPIClient() {
	if s.IsGithubSession {
		s.Client = gh.Client.NewClient(gh.Client{}, s.Github.AccessToken)
	} else {
		var err error
		s.Client, err = gl.Client.NewClient(gl.Client{}, s.GitLab.AccessToken, s.Out)
		if err != nil {
			s.Out.Fatal("Error initializing GitLab client: %s", err)
		}
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

	if *session.Options.Save != "" && common.FileExists(*session.Options.Save) {
		return nil, errors.New(fmt.Sprintf("File: %s already exists.", *session.Options.Save))
	}

	if *session.Options.Load != "" {
		if !common.FileExists(*session.Options.Load) {
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

	session.Version = common.Version
	session.Initialize()

	return &session, nil
}
