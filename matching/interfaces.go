package matching

type IFileSignature interface {
	Match(file MatchFile) bool
	GetDescription() string
	GetComment() string
}
