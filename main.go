package main

import (
	"fmt"
	"github.com/codeEmitter/gitrob/matching"
	"os"
	"time"

	"github.com/codeEmitter/gitrob/common"
	"github.com/codeEmitter/gitrob/core"
)

var (
	sess *core.Session
	err  error
)

func main() {
	if sess, err = core.NewSession(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	sess.Out.Info("%s\n\n", common.ASCIIBanner)
	sess.Out.Important("%s v%s started at %s\n", common.Name, common.Version, sess.Stats.StartedAt.Format(time.RFC3339))
	sess.Out.Important("Loaded %d signatures\n", len(matching.Signatures))
	sess.Out.Important("Web interface available at http://%s:%d\n", *sess.Options.BindAddress, *sess.Options.Port)

	if sess.Stats.Status == "finished" {
		sess.Out.Important("Loaded session file: %s\n", *sess.Options.Load)
	} else {
		if len(sess.Options.Logins) == 0 {
			host := func() string {
				if sess.Github.AccessToken != "" {
					return "Github organization"
				} else {
					return "GitLab group"
				}
			}()
			sess.Out.Fatal(fmt.Sprintf("Please provide at least one %s or user\n", host))
		}

		core.GatherTargets(sess)
		core.GatherRepositories(sess)
		core.AnalyzeRepositories(sess)
		sess.Finish()

		if *sess.Options.Save != "" {
			err := sess.SaveToFile(*sess.Options.Save)
			if err != nil {
				sess.Out.Error("Error saving session to %s: %s\n", *sess.Options.Save, err)
			}
			sess.Out.Important("Saved session to: %s\n\n", *sess.Options.Save)
		}
	}

	core.PrintSessionStats(sess)
	sess.Out.Important("Press Ctrl+C to stop web server and exit.\n\n")
	select {}
}
