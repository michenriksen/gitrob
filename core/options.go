package core

import (
  "flag"
)

type Options struct {
  CommitDepth       *int
  GithubAccessToken *string `json:"-"`
  EnterpriseURL     *string
  EnterpriseAPI     *string
  EnterpriseUpload  *string
  EnterpriseUser    *string
  NoExpandOrgs      *bool
  Threads           *int
  Save              *string `json:"-"`
  Load              *string `json:"-"`
  BindAddress       *string
  Port              *int
  Silent            *bool
  Debug             *bool
  Logins            []string
}

func ParseOptions() (Options, error) {
  options := Options{
    CommitDepth:       flag.Int("commit-depth", 500, "Number of repository commits to process"),
    GithubAccessToken: flag.String("github-access-token", "", "GitHub access token to use for API requests"),
    EnterpriseURL:     flag.String("enterprise-url", "", "URL of the GitHub Enterprise instance, e.g. https://github.yourcompany.com"),
    EnterpriseUpload:  flag.String("enterprise-upload-url", "", "Upload URL for GitHub Enterprise, e.g. https://github.yourcompany.com/api/v3/upload"),
    EnterpriseUser:    flag.String("enterprise-user", "", "Username for your GitHub Enterprise account"),
    NoExpandOrgs:      flag.Bool("no-expand-orgs", false, "Don't add members to targets when processing organizations"),
    Threads:           flag.Int("threads", 0, "Number of concurrent threads (default number of logical CPUs)"),
    Save:              flag.String("save", "", "Save session to file"),
    Load:              flag.String("load", "", "Load session file"),
    BindAddress:       flag.String("bind-address", "127.0.0.1", "Address to bind web server to"),
    Port:              flag.Int("port", 9393, "Port to run web server on"),
    Silent:            flag.Bool("silent", false, "Suppress all output except for errors"),
    Debug:             flag.Bool("debug", false, "Print debugging information"),
  }

  flag.Parse()
  options.Logins = flag.Args()

  return options, nil
}
