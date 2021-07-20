package common

type IClient interface {
	GetUserOrOrganization(login string) (*Owner, error)
	GetRepositoriesFromOwner(target Owner) ([]*Repository, error)
	GetRepositoriesFromOrganization(target Owner) ([]*Repository, error)
	GetOrganizationMembers(target Owner) ([]*Owner, error)
}
