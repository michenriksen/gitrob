package gitlab

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/codeEmitter/gitrob/common"
	"github.com/xanzy/go-gitlab"
)

type errorString struct {
	s string
}

func (e *errorString) Error() string {
	return e.s
}
func new(text string) error {
	return &errorString{text}
}

func getUser(login string, client *gitlab.Client) (*gitlab.User, error) {
	users, _, err := client.Users.ListUsers(&gitlab.ListUsersOptions{Username: gitlab.String(login)})
	if err != nil {
		return nil, err
	}
	if len(users) == 0 {
		return nil, new(fmt.Sprintf("No GitLab %s or %s %s was found.",
			strings.ToLower(common.TargetTypeUser),
			strings.ToLower(common.TargetTypeOrganization),
			login))
	}
	return users[0], err
}

func getOrganization(login string, client *gitlab.Client) (*gitlab.Group, error) {
	id, err := strconv.Atoi(login)
	if err != nil {
		return nil, err
	}
	org, _, err := client.Groups.GetGroup(id)
	if err != nil {
		return nil, err
	}
	return org, err
}

func GetUserOrOrganization(login string, client *gitlab.Client) (*common.Owner, error) {
	emptyString := gitlab.String("")
	org, orgErr := getOrganization(login, client)
	if orgErr != nil {
		user, userErr := getUser(login, client)
		if userErr != nil {
			return nil, userErr
		}
		id := int64(user.ID)
		return &common.Owner{
			Login:     gitlab.String(user.Username),
			ID:        &id,
			Type:      gitlab.String(common.TargetTypeUser),
			Name:      gitlab.String(user.Name),
			AvatarURL: gitlab.String(user.AvatarURL),
			URL:       gitlab.String(user.WebsiteURL),
			Company:   gitlab.String(user.Organization),
			Blog:      emptyString,
			Location:  emptyString,
			Email:     gitlab.String(user.PublicEmail),
			Bio:       gitlab.String(user.Bio),
		}, nil
	} else {
		id := int64(org.ID)
		return &common.Owner{
			Login:     gitlab.String(org.Name),
			ID:        &id,
			Type:      gitlab.String(common.TargetTypeOrganization),
			Name:      gitlab.String(org.Name),
			AvatarURL: gitlab.String(org.AvatarURL),
			URL:       gitlab.String(org.WebURL),
			Company:   gitlab.String(org.FullName),
			Blog:      emptyString,
			Location:  emptyString,
			Email:     emptyString,
			Bio:       gitlab.String(org.Description),
		}, nil
	}
}

func GetOrganizationMembers(id int64, client *gitlab.Client) ([]*common.Owner, error) {
	var allMembers []*common.Owner
	opt := &gitlab.ListGroupMembersOptions{}
	for {
		members, resp, err := client.Groups.ListAllGroupMembers(int(id), opt)
		if err != nil {
			return nil, err
		}
		for _, member := range members {
			id := int64(member.ID)
			allMembers = append(allMembers,
				&common.Owner{
					Login: gitlab.String(member.Username),
					ID:    &id,
					Type:  gitlab.String(common.TargetTypeUser)})
		}
		if resp.NextPage == 0 {
			break
		}
		opt.Page = resp.NextPage
	}
	return allMembers, nil
}

func GetRepositoriesFromOwner(target common.Owner, client *gitlab.Client) ([]*common.Repository, error) {
	var allProjects []*common.Repository
	listUserProjectsOps := &gitlab.ListProjectsOptions{}
	listGroupProjectsOps := &gitlab.ListGroupProjectsOptions{}
	id := int(*target.ID)
	for {
		projects, resp, err := func() ([]*gitlab.Project, *gitlab.Response, error) {
			if *target.Type == common.TargetTypeUser {
				return client.Projects.ListUserProjects(id, listUserProjectsOps)
			} else {
				return client.Groups.ListGroupProjects(id, listGroupProjectsOps)
			}
		}()
		if err != nil {
			return nil, err
		}
		for _, project := range projects {
			//don't capture forks
			if (gitlab.ForkParent{}) == *project.ForkedFromProject {
				id := int64(project.ID)
				p := common.Repository{
					Owner:         gitlab.String(project.Owner.Name),
					ID:            &id,
					Name:          gitlab.String(project.Name),
					FullName:      gitlab.String(project.NameWithNamespace),
					CloneURL:      gitlab.String(project.HTTPURLToRepo),
					URL:           gitlab.String(project.WebURL),
					DefaultBranch: gitlab.String(project.DefaultBranch),
					Description:   gitlab.String(project.Description),
					Homepage:      gitlab.String(project.WebURL),
				}
				allProjects = append(allProjects, &p)
			}
		}
		if resp.NextPage == 0 {
			break
		}
		if *target.Type == common.TargetTypeUser {
			listUserProjectsOps.Page = resp.NextPage
		} else {
			listGroupProjectsOps.Page = resp.NextPage
		}
	}
	return allProjects, nil
}
