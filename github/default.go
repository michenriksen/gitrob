package github

import (
	"context"

	"github.com/codeEmitter/gitrob/scm"
	"github.com/google/go-github/github"
)

func GetUserOrOrganization(login string, client *github.Client) (*scm.Owner, error) {
	ctx := context.Background()
	user, _, err := client.Users.Get(ctx, login)
	if err != nil {
		return nil, err
	}
	return &scm.Owner{
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

func GetRepositoriesFromOwner(login *string, client *github.Client) ([]*scm.Repository, error) {
	var allRepos []*scm.Repository
	loginVal := *login
	ctx := context.Background()
	opt := &github.RepositoryListOptions{
		Type: "sources",
	}

	for {
		repos, resp, err := client.Repositories.List(ctx, loginVal, opt)
		if err != nil {
			return allRepos, err
		}
		for _, repo := range repos {
			if !*repo.Fork {
				r := scm.Repository{
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

func GetOrganizationMembers(login *string, client *github.Client) ([]*scm.Owner, error) {
	var allMembers []*scm.Owner
	loginVal := *login
	ctx := context.Background()
	opt := &github.ListMembersOptions{}
	for {
		members, resp, err := client.Organizations.ListMembers(ctx, loginVal, opt)
		if err != nil {
			return allMembers, err
		}
		for _, member := range members {
			allMembers = append(allMembers, &scm.Owner{Login: member.Login, ID: member.ID, Type: member.Type})
		}
		if resp.NextPage == 0 {
			break
		}
		opt.Page = resp.NextPage
	}
	return allMembers, nil
}
