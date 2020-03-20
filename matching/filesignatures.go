package matching

import (
	"errors"
	"fmt"
	"regexp"
)


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
}

func (s FileSignature) Match(file MatchFile) (bool, error) {
	var haystack *string
	switch s.Part {
	case fileSignatureTypes.Path:
		haystack = &file.Path
	case fileSignatureTypes.Filename:
		haystack = &file.Filename
	case fileSignatureTypes.Extension:
		haystack = &file.Extension
	default:
		return false, errors.New(fmt.Sprintf("Unrecognized 'Part' parameter: %s\n", s.Part))
	}
	return regexp.MatchString(s.MatchOn, *haystack)
}

func (s FileSignature) GetDescription() string {
	return s.Description
}

func (s FileSignature) GetComment() string {
	return s.Comment
}