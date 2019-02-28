package core

import (
	"context"

	"github.com/google/go-github/github"
)

type GithubOwner struct {
	Login     *string
	ID        *int64
	Type      *string
	Name      *string
	AvatarURL *string
	URL       *string
	Company   *string
	Blog      *string
	Location  *string
	Email     *string
	Bio       *string
}

type GithubRepository struct {
	Owner         *string
	ID            *int64
	Name          *string
	FullName      *string
	CloneURL      *string
	URL           *string
	DefaultBranch *string
	BranchName    *string
	Description   *string
	Homepage      *string
}

func GetUserOrOrganization(login string, client *github.Client) (*GithubOwner, error) {
	ctx := context.Background()
	user, _, err := client.Users.Get(ctx, login)
	if err != nil {
		return nil, err
	}
	return &GithubOwner{
		Login:     user.Login,
		ID:        user.ID,
		Type:      user.Type,
		Name:      user.Name,
		AvatarURL: user.AvatarURL,
		URL:       user.HTMLURL,
		Company:   user.Company,
		Blog:      user.Blog,
		Location:  user.Location,
		Email:     user.Email,
		Bio:       user.Bio,
	}, nil
}

func GetRepositoriesFromOwner(login *string, client *github.Client, includeBranches *bool) ([]*GithubRepository, error) {
	var allRepos []*GithubRepository
	loginVal := *login
	ctx := context.Background()
	opt := &github.RepositoryListOptions{
		Type: "sources",
	}
	opts := &github.ListOptions{}
	for {
		repos, resp, err := client.Repositories.List(ctx, loginVal, opt)
		if err != nil {
			return allRepos, err
		}
		for _, repo := range repos {
			if !*repo.Fork {
				t := GithubRepository{
					Owner:         repo.Owner.Login,
					ID:            repo.ID,
					Name:          repo.Name,
					FullName:      repo.FullName,
					CloneURL:      repo.CloneURL,
					URL:           repo.HTMLURL,
					DefaultBranch: repo.DefaultBranch,
					BranchName:    repo.DefaultBranch,
					Description:   repo.Description,
					Homepage:      repo.Homepage,
				}
				branches, resp, err := client.Repositories.ListBranches(ctx, *t.Owner, *t.Name, opts)
				if err != nil {
					return allRepos, err
				}
				for _, branch := range branches {
					r := GithubRepository{
						Owner:         t.Owner,
						ID:            t.ID,
						Name:          t.Name,
						FullName:      t.FullName,
						CloneURL:      t.CloneURL,
						URL:           t.URL,
						DefaultBranch: t.DefaultBranch,
						BranchName:    branch.Name,
						Description:   t.Description,
						Homepage:      t.Homepage,
					}
					if *includeBranches {
						allRepos = append(allRepos, &r)
					} else {
						allRepos = append(allRepos, &t)
					}
				}
				opts.Page = resp.NextPage
			}
		}
		if resp.NextPage == 0 {
			break
		}
		opt.Page = resp.NextPage
	}

	return allRepos, nil
}

func GetOrganizationMembers(login *string, client *github.Client) ([]*GithubOwner, error) {
	var allMembers []*GithubOwner
	loginVal := *login
	ctx := context.Background()
	opt := &github.ListMembersOptions{}
	for {
		members, resp, err := client.Organizations.ListMembers(ctx, loginVal, opt)
		if err != nil {
			return allMembers, err
		}
		for _, member := range members {
			allMembers = append(allMembers, &GithubOwner{Login: member.Login, ID: member.ID, Type: member.Type})
		}
		if resp.NextPage == 0 {
			break
		}
		opt.Page = resp.NextPage
	}
	return allMembers, nil
}
