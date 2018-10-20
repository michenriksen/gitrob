package core

import (
  "context"
  "fmt"
  "net/http"
  "strings"

  assetfs "github.com/elazarl/go-bindata-assetfs"
  "github.com/gin-contrib/secure"
  "github.com/gin-contrib/static"
  "github.com/gin-gonic/gin"
  "github.com/google/go-github/github"
)

const (
  contextKeyGithubClient = "kGithubClient"
  
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

  router.GET("/files/:owner/:repo/:commit/*path", func (c *gin.Context) {
    c.Set(contextKeyGithubClient, s.GithubClient)
    fetchFile(c)
  })

  return router
}

func fetchFile(c *gin.Context) {
  client, _ := c.Get(contextKeyGithubClient)
  githubClient := client.(*github.Client)
  
  ctx := context.Background()
  options := &github.RepositoryContentGetOptions{
    Ref: c.Param("commit"),
  }

  fileResponse, _, _, err := githubClient.Repositories.GetContents(ctx, c.Param("owner"), c.Param("repo"), c.Param("path"), options)

  if err != nil {
    c.JSON(http.StatusInternalServerError, gin.H{
      "message": err,
    })
    return
  }

  if fileResponse.GetSize() > MaximumFileSize {
    c.JSON(http.StatusUnprocessableEntity, gin.H{
      "message": fmt.Sprintf("File size exceeds maximum of %d bytes", MaximumFileSize),
    })
    return
  }
  
  content, _ := fileResponse.GetContent()

  c.String(http.StatusOK, content)
}
