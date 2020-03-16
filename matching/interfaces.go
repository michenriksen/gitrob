package matching

type Signature interface {
	Match(file MatchFile) bool
	GetDescription() string
	GetComment() string
}
