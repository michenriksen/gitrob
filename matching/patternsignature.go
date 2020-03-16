package matching

import "regexp"

type PatternSignature struct {
	Part        string
	MatchOn       *regexp.Regexp
	Description string
	Comment     string
}

func (s PatternSignature) Match(file MatchFile) bool {
	var haystack *string
	switch s.Part {
	case PartPath:
		haystack = &file.Path
	case PartFilename:
		haystack = &file.Filename
	case PartExtension:
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
