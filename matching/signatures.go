package matching

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/codeEmitter/gitrob/common"
	"io/ioutil"
)

type Signatures struct {
	FileSignatures []FileSignature
	ContentSignatures []ContentSignature
}

type ContentSignature struct {
	MatchOn string
	Description string
	Comment string
}

type FileSignature struct {
	Kind string
	Part string
	MatchOn string
	Description string
	Comment string
}

func (s *Signatures) Load(mode int) error {
	fileSignaturePath := "./filesignatures.json"
	if !common.FileExists(fileSignaturePath) {
		return errors.New(fmt.Sprintf("Missing signature file: %s.\n", fileSignaturePath))
	}
	data, err := ioutil.ReadFile(fileSignaturePath); if err != nil {
		return err
	}
	if err2 := json.Unmarshal(data, &s); err2 != nil {
		return err2
	}
	return nil
}

func (s FileSignature) Match(file MatchFile) bool {
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

func (s FileSignature) GetDescription() string {
	return s.Description
}

func (s FileSignature) GetComment() string {
	return s.Comment
}
