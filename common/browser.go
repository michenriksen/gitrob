package common

import (
	"fmt"
	"strings"
)

var UserAgent = fmt.Sprintf("%s v%s", Name, Version)

func CleanUrlSpaces(dirtyStrings ...string) []string {
	var result []string
	for _, s := range dirtyStrings {
		result = append(result, strings.ReplaceAll(s, " ", "-"))
	}
	return result
}
