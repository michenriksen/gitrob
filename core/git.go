package core

import (
  "fmt"
  "io/ioutil"

  "gopkg.in/src-d/go-git.v4"
  "gopkg.in/src-d/go-git.v4/plumbing"
  "gopkg.in/src-d/go-git.v4/plumbing/object"
  "gopkg.in/src-d/go-git.v4/plumbing/transport/http"
  "gopkg.in/src-d/go-git.v4/utils/merkletrie"
)

const (
  EmptyTreeCommitId = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
)

func CloneRepository(url *string, branch *string, sess *Session) (*git.Repository, string, error) {
  urlVal := *url
  branchVal := *branch
  dir, err := ioutil.TempDir("", "gitrob")
  if err != nil {
    return nil, "", err
  }
  
  options := &git.CloneOptions{
    URL:           urlVal,
    Depth:         *sess.Options.CommitDepth,
    ReferenceName: plumbing.ReferenceName(fmt.Sprintf("refs/heads/%s", branchVal)),
    SingleBranch:  true,
    Tags:          git.NoTags,
  }

  if sess.GithubAccessToken != "" && *sess.Options.EnterpriseUser != "" {
    options.Auth = &http.BasicAuth{Username: *sess.Options.EnterpriseUser, Password: sess.GithubAccessToken}
  }
 
  repository, err := git.PlainClone(dir, false, options)
  if err != nil {
    return nil, dir, err
  }
  return repository, dir, nil
}

func GetRepositoryHistory(repository *git.Repository) ([]*object.Commit, error) {
  var commits []*object.Commit
  ref, err := repository.Head()
  if err != nil {
    return nil, err
  }
  cIter, err := repository.Log(&git.LogOptions{From: ref.Hash()})
  if err != nil {
    return nil, err
  }
  cIter.ForEach(func(c *object.Commit) error {
    commits = append(commits, c)
    return nil
  })
  return commits, nil
}

func GetChanges(commit *object.Commit, repo *git.Repository) (object.Changes, error) {
  parentCommit, err := GetParentCommit(commit, repo)
  if err != nil {
    return nil, err
  }

  commitTree, err := commit.Tree()
  if err != nil {
    return nil, err
  }

  parentCommitTree, err := parentCommit.Tree()
  if err != nil {
    return nil, err
  }

  changes, err := object.DiffTree(parentCommitTree, commitTree)
  if err != nil {
    return nil, err
  }
  return changes, nil
}

func GetParentCommit(commit *object.Commit, repo *git.Repository) (*object.Commit, error) {
  if commit.NumParents() == 0 {
    parentCommit, err := repo.CommitObject(plumbing.NewHash(EmptyTreeCommitId))
    if err != nil {
      return nil, err
    }
    return parentCommit, nil
  }
  parentCommit, err := commit.Parents().Next()
  if err != nil {
    return nil, err
  }
  return parentCommit, nil
}

func GetChangeAction(change *object.Change) string {
  action, err := change.Action()
  if err != nil {
    return "Unknown"
  }
  switch action {
  case merkletrie.Insert:
    return "Insert"
  case merkletrie.Modify:
    return "Modify"
  case merkletrie.Delete:
    return "Delete"
  default:
    return "Unknown"
  }
}

func GetChangePath(change *object.Change) string {
  action, err := change.Action()
  if err != nil {
    return change.To.Name
  }

  if action == merkletrie.Delete {
    return change.From.Name
  } else {
    return change.To.Name
  }
}
