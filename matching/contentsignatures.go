package matching

import "regexp"

type ContentSignature struct {
	MatchOn string
	Description string
	Comment string
}

func (c ContentSignature) Match(target MatchTarget) (bool, error) {
	return regexp.MatchString(c.MatchOn, target.Content)
}

func (c ContentSignature) GetDescription() string {
	return c.Description
}

func (c ContentSignature) GetComment() string {
	return c.Comment
}