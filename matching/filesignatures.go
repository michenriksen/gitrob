package matching

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