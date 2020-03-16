package matching

type SimpleSignature struct {
	Part        string
	MatchOn     string
	Description string
	Comment     string
}

func (s SimpleSignature) Match(file MatchFile) bool {
	var haystack *string
	switch s.Part {
	case fileSignatureTypes.Path:
		haystack = &file.Path
	case fileSignatureTypes.Filename:
		haystack = &file.Filename
	case fileSignatureTypes.Extension:
		haystack = &file.Extension
	default:
		return false
	}

	return s.MatchOn == *haystack
}

func (s SimpleSignature) GetDescription() string {
	return s.Description
}

func (s SimpleSignature) GetComment() string {
	return s.Comment
}
