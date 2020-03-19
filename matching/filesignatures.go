package matching

import "regexp"


type FileSignatureType struct {
	Extension string
	Filename  string
	Path      string
}

var fileSignatureTypes = FileSignatureType{
	Extension: "extension",
	Filename:  "filename",
	Path:      "path",
}

type FileSignature struct {
	Part string
	MatchOn string
	Description string
	Comment string
	CompiledRegex *regexp.Regexp
}

func (s FileSignature) Match(file MatchFile) bool {
	var haystack string
	switch s.Part {
	case fileSignatureTypes.Path:
		haystack = file.Path
	case fileSignatureTypes.Filename:
		haystack = file.Filename
	case fileSignatureTypes.Extension:
		haystack = file.Extension
	default:
		return false
	}
	return s.CompiledRegex.MatchString(haystack)
}

func (s FileSignature) GetDescription() string {
	return s.Description
}

func (s FileSignature) GetComment() string {
	return s.Comment
}