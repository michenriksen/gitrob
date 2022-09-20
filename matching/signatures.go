package matching

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"gitrob/common"
)

type Signatures struct {
	FileSignatures    []FileSignature
	ContentSignatures []ContentSignature
}

func (s *Signatures) loadSignatures(path string) error {
	if !common.FileExists(path) {
		return errors.New(fmt.Sprintf("Missing signature file: %s.\n", path))
	}
	data, readError := ioutil.ReadFile(path)
	if readError != nil {
		return readError
	}
	if unmarshalError := json.Unmarshal(data, &s); unmarshalError != nil {
		return unmarshalError
	}
	return nil
}

func (s *Signatures) Load(mode int) error {
	var e error
	if mode != 3 {
		e = s.loadSignatures("./filesignatures.json")
		if e != nil {
			return e
		}
	}
	if mode != 1 {
		//source:  https://github.com/dxa4481/truffleHogRegexes/blob/master/truffleHogRegexes/regexes.json
		e = s.loadSignatures("./contentsignatures.json")
		if e != nil {
			return e
		}
	}
	return nil
}
