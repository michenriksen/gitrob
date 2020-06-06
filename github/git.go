package github

import (
	"fmt"
	"gopkg.in/src-d/go-git.v4/storage/memory"
	"io/ioutil"

	"phantomSecrets/common"

	"gopkg.in/src-d/go-git.v4"
	"gopkg.in/src-d/go-git.v4/plumbing"
)

func CloneRepository(cloneConfig *common.CloneConfiguration) (*git.Repository, string, error) {

	cloneOptions := &git.CloneOptions{
		URL:           *cloneConfig.Url,
		Depth:         *cloneConfig.Depth,
		ReferenceName: plumbing.ReferenceName(fmt.Sprintf("refs/heads/%s", *cloneConfig.Branch)),
		SingleBranch:  true,
		Tags:          git.NoTags,
	}

	var repository *git.Repository
	var err error
	var dir string
	if !*cloneConfig.InMemClone {
		dir, err := ioutil.TempDir("", "phantomSecrets")
		if err != nil {
			return nil, "", err
		}
		repository, err = git.PlainClone(dir, false, cloneOptions)
	} else {
		repository, err = git.Clone(memory.NewStorage(), nil, cloneOptions)
	}
	if err != nil {
		return nil, dir, err
	}
	return repository, dir, nil
}
