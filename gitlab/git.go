package gitlab

import (
	"fmt"
	"io/ioutil"

	"github.com/codeEmitter/gitrob/common"
	"gopkg.in/src-d/go-git.v4"
	"gopkg.in/src-d/go-git.v4/plumbing"
	"gopkg.in/src-d/go-git.v4/plumbing/transport/http"
)

func CloneRepository(cloneConfig *common.CloneConfiguration) (*git.Repository, string, error) {
	dir, err := ioutil.TempDir("", "gitrob")
	if err != nil {
		return nil, "", err
	}
	repository, err := git.PlainClone(dir, false, &git.CloneOptions{
		URL:           *cloneConfig.Url,
		Depth:         *cloneConfig.Depth,
		ReferenceName: plumbing.ReferenceName(fmt.Sprintf("refs/heads/%s", *cloneConfig.Branch)),
		SingleBranch:  true,
		Tags:          git.NoTags,
		Auth: &http.BasicAuth{
			Username: *cloneConfig.Username,
			Password: *cloneConfig.Token,
		},
	})
	if err != nil {
		return nil, dir, err
	}
	return repository, dir, nil
}
