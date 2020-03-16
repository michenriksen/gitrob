package matching

type SimpleFileSignature struct {
	Part        string
	MatchOn     string
	Description string
	Comment     string
}

func (s SimpleFileSignature) Match(file MatchFile) bool {
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

func (s SimpleFileSignature) GetDescription() string {
	return s.Description
}

func (s SimpleFileSignature) GetComment() string {
	return s.Comment
}
