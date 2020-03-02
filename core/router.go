package core

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"

	assetfs "github.com/elazarl/go-bindata-assetfs"
	"github.com/gin-contrib/secure"
	"github.com/gin-contrib/static"
	"github.com/gin-gonic/gin"
)

const (
	GithubBaseUri   = "https://raw.githubusercontent.com"
	MaximumFileSize = 102400
	CspPolicy       = "default-src 'none'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'"
	ReferrerPolicy  = "no-referrer"
)

type binaryFileSystem struct {
	fs http.FileSystem
}

func (b *binaryFileSystem) Open(name string) (http.File, error) {
	return b.fs.Open(name)
}

func (b *binaryFileSystem) Exists(prefix string, filepath string) bool {
	if p := strings.TrimPrefix(filepath, prefix); len(p) < len(filepath) {
		if _, err := b.fs.Open(p); err != nil {
			return false
		}
		return true
	}
	return false
}

func BinaryFileSystem(root string) *binaryFileSystem {
	fs := &assetfs.AssetFS{Asset, AssetDir, AssetInfo, root}
	return &binaryFileSystem{
		fs,
	}
}

func NewRouter(s *Session) *gin.Engine {
	if *s.Options.Debug == true {
		gin.SetMode(gin.DebugMode)
	} else {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()
	router.Use(static.Serve("/", BinaryFileSystem("static")))
	router.Use(secure.New(secure.Config{
		SSLRedirect:           false,
		IsDevelopment:         false,
		FrameDeny:             true,
		ContentTypeNosniff:    true,
		BrowserXssFilter:      true,
		ContentSecurityPolicy: CspPolicy,
		ReferrerPolicy:        ReferrerPolicy,
	}))
	router.GET("/stats", func(c *gin.Context) {
		c.JSON(200, s.Stats)
	})
	router.GET("/findings", func(c *gin.Context) {
		c.JSON(200, s.Findings)
	})
	router.GET("/targets", func(c *gin.Context) {
		c.JSON(200, s.Targets)
	})
	router.GET("/repositories", func(c *gin.Context) {
		c.JSON(200, s.Repositories)
	})
	router.GET("/files/:owner/:repo/:commit/*path", fetchFile)

	return router
}

func fetchFile(c *gin.Context) {
	fileUrl := fmt.Sprintf("%s/%s/%s/%s%s", GithubBaseUri, c.Param("owner"), c.Param("repo"), c.Param("commit"), c.Param("path"))
	resp, err := http.Head(fileUrl)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"message": err,
		})
		return
	}

	if resp.StatusCode == http.StatusNotFound {
		c.JSON(http.StatusNotFound, gin.H{
			"message": "No content",
		})
		return
	}

	if resp.ContentLength > MaximumFileSize {
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"message": fmt.Sprintf("File size exceeds maximum of %d bytes", MaximumFileSize),
		})
		return
	}

	resp, err = http.Get(fileUrl)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"message": err,
		})
		return
	}

	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"message": err,
		})
		return
	}

	c.String(http.StatusOK, string(body[:]))
}
