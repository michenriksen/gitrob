package matching

import "regexp"

type PatternSignature struct {
	Part        string
	MatchOn     *regexp.Regexp
	Description string
	Comment     string
}

func (s PatternSignature) Match(file MatchFile) bool {
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

	return s.MatchOn.MatchString(*haystack)
}

func (s PatternSignature) GetDescription() string {
	return s.Description
}

func (s PatternSignature) GetComment() string {
	return s.Comment
}
