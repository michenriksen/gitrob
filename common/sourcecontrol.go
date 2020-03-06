package common

const (
	TargetTypeUser         = "User"
	TargetTypeOrganization = "Organization"
)

type CloneConfiguration struct {
	Url      *string
	Username *string
	Token    *string
	Branch   *string
	Depth    *int
}

type Owner struct {
	Login     *string
	ID        *int64
	Type      *string
	Name      *string
	AvatarURL *string
	URL       *string
	Company   *string
	Blog      *string
	Location  *string
	Email     *string
	Bio       *string
}

type Repository struct {
	Owner         *string
	ID            *int64
	Name          *string
	FullName      *string
	CloneURL      *string
	URL           *string
	DefaultBranch *string
	Description   *string
	Homepage      *string
}
