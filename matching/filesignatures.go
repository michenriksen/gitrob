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

func (f FileSignature) Match(target MatchTarget) (bool, error) {
	var haystack *string
	switch f.Part {
	case fileSignatureTypes.Path:
		haystack = &target.Path
	case fileSignatureTypes.Filename:
		haystack = &target.Filename
	case fileSignatureTypes.Extension:
		haystack = &target.Extension
	default:
		return false, errors.New(fmt.Sprintf("Unrecognized 'Part' parameter: %f\n", f.Part))
	}
	return regexp.MatchString(f.MatchOn, *haystack)
}

func (f FileSignature) GetDescription() string {
	return f.Description
}

func (f FileSignature) GetComment() string {
	return f.Comment
}