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

func GetOrganizationMembers(login *string, client *gitlab.Client) ([]*common.Owner, error) {
	return nil, nil
}
