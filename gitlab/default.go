package gitlab

import (
	"github.com/codeEmitter/gitrob/common"
	"github.com/xanzy/go-gitlab"
)

func getUser(login string, client *gitlab.Client) ([]*gitlab.User, error) {
	user, _, err := client.Users.ListUsers(&gitlab.ListUsersOptions{Username: gitlab.String(login)})
	if err != nil {
		return nil, err
	}
	return user, err
}

func GetUserOrOrganization(login string, client *gitlab.Client) (*common.Owner, error) {
	users, err := getUser(login, client)
	if err != nil {
		return nil, err
	}

	id := int64(users[0].ID)
	emptyString := gitlab.String("")

	return &common.Owner{
		Login:     gitlab.String(users[0].Username),
		ID:        &id,
		Type:      gitlab.String("User"),
		Name:      gitlab.String(users[0].Name),
		AvatarURL: gitlab.String(users[0].AvatarURL),
		URL:       gitlab.String(users[0].WebsiteURL),
		Company:   gitlab.String(users[0].Organization),
		Blog:      emptyString,
		Location:  emptyString,
		Email:     gitlab.String(users[0].PublicEmail),
		Bio:       gitlab.String(users[0].Bio),
	}, nil
}
