package matching

import (
	"crypto/sha1"
	"fmt"
	"github.com/codeEmitter/gitrob/common"
	"io"
)

type Finding struct {
	Id              string
	FilePath        string
	Action          string
	Description     string
	Comment         string
	RepositoryOwner string
	RepositoryName  string
	CommitHash      string
	CommitMessage   string
	CommitAuthor    string
	FileUrl         string
	CommitUrl       string
	RepositoryUrl   string
}

func (f *Finding) setupUrls(isGithubSession bool) {
	if isGithubSession {
		f.RepositoryUrl = fmt.Sprintf("https://github.com/%s/%s", f.RepositoryOwner, f.RepositoryName)
		f.FileUrl = fmt.Sprintf("%s/blob/%s/%s", f.RepositoryUrl, f.CommitHash, f.FilePath)
		f.CommitUrl = fmt.Sprintf("%s/commit/%s", f.RepositoryUrl, f.CommitHash)
	} else {
		results := common.CleanUrlSpaces(f.RepositoryOwner, f.RepositoryName)
		f.RepositoryUrl = fmt.Sprintf("https://gitlab.com/%s/%s", results[0], results[1])
		f.FileUrl = fmt.Sprintf("%s/blob/%s/%s", f.RepositoryUrl, f.CommitHash, f.FilePath)
		f.CommitUrl = fmt.Sprintf("%s/commit/%s", f.RepositoryUrl, f.CommitHash)
	}
}

func (f *Finding) generateID() {
	h := sha1.New()
	io.WriteString(h, f.FilePath)
	io.WriteString(h, f.Action)
	io.WriteString(h, f.RepositoryOwner)
	io.WriteString(h, f.RepositoryName)
	io.WriteString(h, f.CommitHash)
	io.WriteString(h, f.CommitMessage)
	io.WriteString(h, f.CommitAuthor)
	f.Id = fmt.Sprintf("%x", h.Sum(nil))
}

func (f *Finding) Initialize(isGithubSession bool) {
	f.setupUrls(isGithubSession)
	f.generateID()
}
