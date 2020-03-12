package github

import (
	"context"

	"github.com/codeEmitter/gitrob/common"
	"github.com/google/go-github/github"
	"golang.org/x/oauth2"
)

type Client struct {
	apiClient *github.Client
}

func (c Client) NewClient(token string) (apiClient Client) {
	ctx := context.Background()
	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: token},
	)
	tc := oauth2.NewClient(ctx, ts)
	c.apiClient = github.NewClient(tc)
	c.apiClient.UserAgent = common.UserAgent
	return c
}

func (c Client) GetUserOrOrganization(login string) (*common.Owner, error) {
	ctx := context.Background()
	user, _, err := c.apiClient.Users.Get(ctx, login)
	if err != nil {
		return nil, err
	}
	return &common.Owner{
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

func (c Client) GetRepositoriesFromOwner(target common.Owner) ([]*common.Repository, error) {
	var allRepos []*common.Repository
	ctx := context.Background()
	opt := &github.RepositoryListOptions{
		Type: "sources",
	}

	for {
		repos, resp, err := c.apiClient.Repositories.List(ctx, *target.Login, opt)
		if err != nil {
			return allRepos, err
		}
		for _, repo := range repos {
			if !*repo.Fork {
				r := common.Repository{
					Owner:         repo.Owner.Login,
					ID:            repo.ID,
					Name:          repo.Name,
					FullName:      repo.FullName,
					CloneURL:      repo.CloneURL,
					URL:           repo.HTMLURL,
					DefaultBranch: repo.DefaultBranch,
					Description:   repo.Description,
					Homepage:      repo.Homepage,
				}
				allRepos = append(allRepos, &r)
			}
		}
		if resp.NextPage == 0 {
			break
		}
		opt.Page = resp.NextPage
	}

	return allRepos, nil
}

func (c Client) GetOrganizationMembers(target common.Owner) ([]*common.Owner, error) {
	var allMembers []*common.Owner
	ctx := context.Background()
	opt := &github.ListMembersOptions{}
	for {
		members, resp, err := c.apiClient.Organizations.ListMembers(ctx, *target.Login, opt)
		if err != nil {
			return allMembers, err
		}
		for _, member := range members {
			allMembers = append(allMembers, &common.Owner{Login: member.Login, ID: member.ID, Type: member.Type})
		}
		if resp.NextPage == 0 {
			break
		}
		opt.Page = resp.NextPage
	}
	return allMembers, nil
}
