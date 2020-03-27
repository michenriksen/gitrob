package core

import (
	"flag"
)

type Options struct {
	BindAddress       *string
	CommitDepth       *int
	Debug             *bool
	GitLabAccessToken *string `json:"-"`
	GithubAccessToken *string `json:"-"`
	InMemClone        *bool
	Load              *string `json:"-"`
	Logins            []string
	Mode              *int `json:"-"`
	NoExpandOrgs      *bool
	Port              *int
	Save              *string `json:"-"`
	Silent            *bool
	Threads           *int
}

func ParseOptions() (Options, error) {
	options := Options{
		BindAddress:       flag.String("bind-address", "127.0.0.1", "Address to bind web server to"),
		CommitDepth:       flag.Int("commit-depth", 500, "Number of repository commits to process"),
		Debug:             flag.Bool("debug", false, "Print debugging information"),
		GitLabAccessToken: flag.String("gitlab-access-token", "", "GitLab access token to use for API requests"),
		GithubAccessToken: flag.String("github-access-token", "", "GitHub access token to use for API requests"),
		InMemClone:        flag.Bool("in-mem-clone", false, "Clone repositories into memory"),
		Load:              flag.String("load", "", "Load session file"),
		Mode:              flag.Int("mode", 1, "Secrets matching mode (see documentation)."),
		NoExpandOrgs:      flag.Bool("no-expand-orgs", false, "Don't add members to targets when processing organizations"),
		Port:              flag.Int("port", 9393, "Port to run web server on"),
		Save:              flag.String("save", "", "Save session to file"),
		Silent:            flag.Bool("silent", false, "Suppress all output except for errors"),
		Threads:           flag.Int("threads", 0, "Number of concurrent threads (default number of logical CPUs)"),
	}

	flag.Parse()
	options.Logins = flag.Args()

	return options, nil
}
