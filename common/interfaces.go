package common

type IClient interface {
	GetUserOrOrganization(login string) (*Owner, error)
	GetRepositoriesFromOwner(target Owner) ([]*Repository, error)
	GetOrganizationMembers(login string) ([]*Owner, error)
}
