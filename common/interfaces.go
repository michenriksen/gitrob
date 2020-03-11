package common

type IClient interface {
	GetUserOrOrganization(login string) (*Owner, error)
	GetRepositoriesFromOwner(login *string) ([]*Repository, error)
	GetOrganizationMembers(login *string) ([]*Owner, error)
}
