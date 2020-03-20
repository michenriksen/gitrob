package matching

import (
	"path/filepath"
	"strings"
)

type MatchTarget struct {
	Path      string
	Filename  string
	Extension string
}

var skippableExtensions = []string{".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".tif", ".psd", ".xcf"}
var skippablePathIndicators = []string{"node_modules/", "vendor/bundle", "vendor/cache"}

func (f *MatchTarget) IsSkippable() bool {
	ext := strings.ToLower(f.Extension)
	path := strings.ToLower(f.Path)
	for _, skippableExt := range skippableExtensions {
		if ext == skippableExt {
			return true
		}
	}
	for _, skippablePathIndicator := range skippablePathIndicators {
		if strings.Contains(path, skippablePathIndicator) {
			return true
		}
	}
	return false
}

func NewMatchTarget(path string) MatchTarget {
	_, filename := filepath.Split(path)
	extension := filepath.Ext(path)
	return MatchTarget{
		Path:      path,
		Filename:  filename,
		Extension: extension,
	}
}
