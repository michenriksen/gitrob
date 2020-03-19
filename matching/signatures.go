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

