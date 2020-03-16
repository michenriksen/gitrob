package matching

type FileSignature interface {
	Match(file MatchFile) bool
	GetDescription() string
	GetComment() string
}
