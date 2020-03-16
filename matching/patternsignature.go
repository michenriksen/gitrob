package matching

import "regexp"

type PatternFileSignature struct {
	Part        string
	MatchOn     *regexp.Regexp
	Description string
	Comment     string
}

func (s PatternFileSignature) Match(file MatchFile) bool {
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

func (s PatternFileSignature) GetDescription() string {
	return s.Description
}

func (s PatternFileSignature) GetComment() string {
	return s.Comment
}
