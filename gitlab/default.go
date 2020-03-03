package gitlab

import (
	"github.com/codeEmitter/gitrob/common"
	"github.com/xanzy/go-gitlab"
)

func getUser(login string, client *gitlab.Client) (*gitlab.User, error) {
	user, _, err := client.Users.ListUsers(&gitlab.ListUsersOptions{Username: gitlab.String(login)})
	if err != nil {
		return nil, err
	}
	return user[0], err
}

func GetUserOrOrganization(login string, client *gitlab.Client) (*common.Owner, error) {
	user, err := getUser(login, client)
	if err != nil {
		return nil, err
	}

	id := int64(user.ID)
	emptyString := gitlab.String("")

	return &common.Owner{
		Login:     gitlab.String(user.Username),
		ID:        &id,
		Type:      gitlab.String("User"),
		Name:      gitlab.String(user.Name),
		AvatarURL: gitlab.String(user.AvatarURL),
		URL:       gitlab.String(user.WebsiteURL),
		Company:   gitlab.String(user.Organization),
		Blog:      emptyString,
		Location:  emptyString,
		Email:     gitlab.String(user.PublicEmail),
		Bio:       gitlab.String(user.Bio),
	}, nil
}
