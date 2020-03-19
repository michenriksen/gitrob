package matching

import (
	"errors"
	"fmt"
	"github.com/codeEmitter/gitrob/common"
)

type Signatures struct {
	FileSignatures []FileSignature
	//ContentSignatures []ContentSignatures
}

func (s *Signatures) Load(mode int) error {
	fileSignaturePath := "./file-signatures.json"
	if !common.FileExists("./file-signatures.json") {
		return errors.New(fmt.Sprintf("Missing signature file: %s.", fileSignaturePath))
	}
	return nil
}
