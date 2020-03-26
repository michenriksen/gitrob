package gitlab

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/codeEmitter/gitrob/common"
	"github.com/xanzy/go-gitlab"
)

type Client struct {
	apiClient *gitlab.Client
	logger *common.Logger
}

func (c Client) NewClient(token string, logger *common.Logger) (apiClient Client) {
	c.apiClient = gitlab.NewClient(nil, token)
	c.apiClient.UserAgent = common.UserAgent
	c.logger = logger
	return c
}

func (c Client) GetUserOrOrganization(login string) (*common.Owner, error) {
	emptyString := gitlab.String("")
	org, orgErr := c.getOrganization(login)
	if orgErr != nil {
		user, userErr := c.getUser(login)
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

func (c Client) GetOrganizationMembers(target common.Owner) ([]*common.Owner, error) {
	var allMembers []*common.Owner
	opt := &gitlab.ListGroupMembersOptions{}
	sID := strconv.FormatInt(*target.ID, 10) //safely downcast an int64 to an int
	for {
		members, resp, err := c.apiClient.Groups.ListAllGroupMembers(sID, opt)
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

func (c Client) GetRepositoriesFromOwner(target common.Owner) ([]*common.Repository, error) {
	var allProjects []*common.Repository
	id := int(*target.ID)
	if *target.Type == common.TargetTypeUser {
		userProjects, err := c.getUserProjects(id)
		if err != nil {
			return nil, err
		}
		for _, project := range userProjects {
			allProjects = append(allProjects, project)
		}
	} else {
		groupProjects, err := c.getGroupProjects(target)
		if err != nil {
			return nil, err
		}
		for _, project := range groupProjects {
			allProjects = append(allProjects, project)
		}
	}
	return allProjects, nil
}

func (c Client) logRateLimitInfo(remaining int, wait time.Duration, isResetTime bool) {
	resetTimeMsg := ""
	if isResetTime {
		resetTimeMsg = "(rate limit reset time)"
	}
	c.logger.Warn(" Remaining requests before GitLab rate limit: %d.  Waiting %f seconds. %s\n", remaining, wait.Seconds(), resetTimeMsg)
}

func (c Client) getRateLimitResetDuration(rateLimitReset string) time.Duration {
	resetTime, _ := time.Parse(time.RFC1123, rateLimitReset)
	return time.Until(resetTime)
}

func (c Client) handleRateLimit(response *gitlab.Response) {

	remaining, _ := strconv.Atoi(response.Header.Get("RateLimit-Remaining"))

	switch {
	case remaining >=1 && remaining <= 10:
		reset := c.getRateLimitResetDuration(response.Header.Get("RateLimit-ResetTime"))
		c.logRateLimitInfo(remaining, reset, true)
		time.Sleep(reset)
	case remaining >=11 && remaining <= 25:
		wait, _ := time.ParseDuration("5s")
		c.logRateLimitInfo(remaining, wait, false)
		time.Sleep(wait)
	case remaining >= 26 && remaining <= 50:
		wait, _ := time.ParseDuration("2500ms")
		c.logRateLimitInfo(remaining, wait, false)
		time.Sleep(wait)
	case remaining >= 51 && remaining <= 100:
		wait, _ := time.ParseDuration("1250ms")
		c.logRateLimitInfo(remaining, wait, false)
		time.Sleep(wait)
	case remaining >= 101 && remaining <= 200:
		wait, _ := time.ParseDuration("750ms")
		c.logRateLimitInfo(remaining, wait, false)
		time.Sleep(wait)
	case remaining >= 201 && remaining <= 300:
		wait, _ := time.ParseDuration("500ms")
		c.logRateLimitInfo(remaining, wait, false)
		time.Sleep(wait)
	case remaining >= 301 && remaining <= 400:
		wait, _ := time.ParseDuration("250ms")
		c.logRateLimitInfo(remaining, wait, false)
		time.Sleep(wait)
	default:
		c.logger.Debug("Rate limited requests remaining:  %d\n", remaining)
	}

}

func (c Client) getUser(login string) (*gitlab.User, error) {
	users, response, err := c.apiClient.Users.ListUsers(&gitlab.ListUsersOptions{Username: gitlab.String(login)})
	c.handleRateLimit(response)
	if err != nil {
		return nil, err
	}
	if len(users) == 0 {
		return nil, fmt.Errorf("No GitLab %s or %s %s was found.",
			strings.ToLower(common.TargetTypeUser),
			strings.ToLower(common.TargetTypeOrganization),
			login)
	}
	return users[0], err
}

func (c Client) getOrganization(login string) (*gitlab.Group, error) {
	id, err := strconv.Atoi(login)
	if err != nil {
		return nil, err
	}
	org, response, err := c.apiClient.Groups.GetGroup(id)
	c.handleRateLimit(response)
	if err != nil {
		return nil, err
	}
	return org, err
}

func (c Client) getUserProjects(id int) ([]*common.Repository, error) {
	var allUserProjects []*common.Repository
	listUserProjectsOps := &gitlab.ListProjectsOptions{}
	for {
		projects, response, err := c.apiClient.Projects.ListUserProjects(id, listUserProjectsOps)
		c.handleRateLimit(response)
		if err != nil {
			return nil, err
		}
		for _, project := range projects {
			//don't capture forks
			if project.ForkedFromProject == nil {
				id := int64(project.ID)
				p := common.Repository{
					Owner:         gitlab.String(project.Owner.Username),
					ID:            &id,
					Name:          gitlab.String(project.Name),
					FullName:      gitlab.String(project.NameWithNamespace),
					CloneURL:      gitlab.String(project.HTTPURLToRepo),
					URL:           gitlab.String(project.WebURL),
					DefaultBranch: gitlab.String(project.DefaultBranch),
					Description:   gitlab.String(project.Description),
					Homepage:      gitlab.String(project.WebURL),
				}
				allUserProjects = append(allUserProjects, &p)
			}
		}
		if response.NextPage == 0 {
			break
		}
		listUserProjectsOps.Page = response.NextPage
	}
	return allUserProjects, nil
}

func (c Client) getGroupProjects(target common.Owner) ([]*common.Repository, error) {
	var allGroupProjects []*common.Repository
	listGroupProjectsOps := &gitlab.ListGroupProjectsOptions{}
	id := strconv.FormatInt(*target.ID, 10)
	for {
		projects, response, err := c.apiClient.Groups.ListGroupProjects(id, listGroupProjectsOps)
		c.handleRateLimit(response)
		if err != nil {
			return nil, err
		}
		for _, project := range projects {
			//don't capture forks
			if project.ForkedFromProject == nil {
				id := int64(project.ID)
				p := common.Repository{
					Owner:         gitlab.String(project.Namespace.FullPath),
					ID:            &id,
					Name:          gitlab.String(project.Name),
					FullName:      gitlab.String(project.NameWithNamespace),
					CloneURL:      gitlab.String(project.HTTPURLToRepo),
					URL:           gitlab.String(project.WebURL),
					DefaultBranch: gitlab.String(project.DefaultBranch),
					Description:   gitlab.String(project.Description),
					Homepage:      gitlab.String(project.WebURL),
				}
				allGroupProjects = append(allGroupProjects, &p)
			}
		}
		if response.NextPage == 0 {
			break
		}
		listGroupProjectsOps.Page = response.NextPage
	}
	return allGroupProjects, nil
}
