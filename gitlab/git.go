package gitlab

import (
	"fmt"
	"io/ioutil"

	"gopkg.in/src-d/go-git.v4"
	"gopkg.in/src-d/go-git.v4/plumbing"
)

func CloneRepository(url *string, branch *string, depth int) (*git.Repository, string, error) {
	urlVal := *url
	branchVal := *branch
	dir, err := ioutil.TempDir("", "gitrob")
	if err != nil {
		return nil, "", err
	}
	repository, err := git.PlainClone(dir, false, &git.CloneOptions{
		URL:           urlVal,
		Depth:         depth,
		ReferenceName: plumbing.ReferenceName(fmt.Sprintf("refs/heads/%s", branchVal)),
		SingleBranch:  true,
		Tags:          git.NoTags,
	})
	if err != nil {
		return nil, dir, err
	}
	return repository, dir, nil
}
