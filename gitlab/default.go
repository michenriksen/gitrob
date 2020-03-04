package gitlab

import (
	"strconv"

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

func getOrganization(login string, client *gitlab.Client) (*gitlab.Group, error) {
	id, err := strconv.Atoi(login)
	if err != nil {
		return nil, err
	}
	org, _, err := client.Groups.GetGroup(id)
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

}
