package core

import (
  "context"
  "encoding/json"
  "errors"
  "fmt"
  "io/ioutil"
  "os"
  "runtime"
  "strings"
  "sync"
  "time"

  "github.com/gin-gonic/gin"
  "github.com/google/go-github/github"
  "golang.org/x/oauth2"
)

const (
  AccessTokenEnvVariable = "GITROB_ACCESS_TOKEN"

  StatusInitializing = "initializing"
  StatusGathering    = "gathering"
  StatusAnalyzing    = "analyzing"
  StatusFinished     = "finished"

  githubDotComURL    = "https://github.com"
  githubAPIPath      = "/api/v3/"
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

type Session struct {
  sync.Mutex

  Version           string
  Options           Options `json:"-"`
  Out               *Logger `json:"-"`
  Stats             *Stats
  GithubAccessToken string         `json:"-"`
  GithubClient      *github.Client `json:"-"`
  Router            *gin.Engine    `json:"-"`
  Targets           []*GithubOwner
  Repositories      []*GithubRepository
  Findings          []*Finding
}

func (s *Session) Start() {
  s.InitStats()
  s.InitLogger()
  s.InitThreads()
  s.InitGithubAccessToken()
  s.initEnterpriseConfig()
  s.InitGithubClient()
  if !*s.Options.NoServer {
    s.InitRouter()
  }
}

func (s *Session) Finish() {
  s.Stats.FinishedAt = time.Now()
  s.Stats.Status = StatusFinished
}

func (s *Session) AddTarget(target *GithubOwner) {
  s.Lock()
  defer s.Unlock()
  for _, t := range s.Targets {
    if *target.ID == *t.ID {
      return
    }
  }
  s.Targets = append(s.Targets, target)
}

func (s *Session) AddRepository(repository *GithubRepository) {
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

func (s *Session) InitGithubAccessToken() {
  if *s.Options.GithubAccessToken == "" {
    accessToken := os.Getenv(AccessTokenEnvVariable)
    if accessToken == "" {
      s.Out.Fatal("No GitHub access token given. Please provide via command line option or in the %s environment variable.\n", AccessTokenEnvVariable)
    }
    s.GithubAccessToken = accessToken
  } else {
    s.GithubAccessToken = *s.Options.GithubAccessToken
  }
}

func (s *Session) initEnterpriseConfig() {
	apiURL := *s.Options.EnterpriseURL
  
	if apiURL == "" {
	  return
	}
  
	apiURL = strings.TrimSuffix(apiURL, "/")
  
  *s.Options.EnterpriseURL = apiURL
  apiPath := apiURL + githubAPIPath
  s.Options.EnterpriseAPI = &apiPath
  
	uploadURL := *s.Options.EnterpriseUpload
  
	if uploadURL == "" {
	  uploadURL = *s.Options.EnterpriseAPI
	} else {
	  if !strings.HasSuffix(uploadURL, "/") {
		uploadURL += "/"
		*s.Options.EnterpriseUpload = uploadURL
	  }
	}
  
	if *s.Options.EnterpriseUser == "" && len(s.Options.Logins) > 0 {
	  *s.Options.EnterpriseUser = s.Options.Logins[0]
	}
}

func (s *Session) GithubURL() string {
  if s.Options.EnterpriseURL != nil && *s.Options.EnterpriseURL != "" {
    return *s.Options.EnterpriseURL
  }

  return githubDotComURL
}

func (s *Session) InitGithubClient() {
  ctx := context.Background()
  ts := oauth2.StaticTokenSource(
    &oauth2.Token{AccessToken: s.GithubAccessToken},
  )
  tc := oauth2.NewClient(ctx, ts)
  
  if s.Options.EnterpriseAPI != nil && *s.Options.EnterpriseAPI != "" {
    enterpriseClient, err := github.NewEnterpriseClient(*s.Options.EnterpriseAPI, *s.Options.EnterpriseUpload, tc)
    if err != nil {
      s.Out.Fatal("Error creating GitHub Enterprise client: %s\n", err)
    }
    
    s.GithubClient = enterpriseClient
  } else {
	  s.GithubClient = github.NewClient(tc)
  }

  s.GithubClient.UserAgent = fmt.Sprintf("%s v%s", Name, Version)
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
