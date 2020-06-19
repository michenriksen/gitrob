package main

import (
	"fmt"
	"os"
	"time"

	"gitrob/common"
	"gitrob/core"
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
	sess.Out.Important("Loaded %d file signatures and %d content signatures.\n", len(sess.Signatures.FileSignatures), len(sess.Signatures.ContentSignatures))
	sess.Out.Important("Web interface available at http://%s:%d\n", *sess.Options.BindAddress, *sess.Options.Port)

	if sess.Stats.Status == "finished" {
		sess.Out.Important("Loaded session file: %s\n", *sess.Options.Load)
	} else {
		if len(sess.Options.Logins) == 0 {
			host := func() string {
				if sess.IsGithubSession {
					return "Github organization"
				} else {
					return "GitLab group"
				}
			}()
			sess.Out.Fatal("Please provide at least one %s or user\n", host)
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
	if !sess.IsGithubSession {
		sess.Out.Error("%s", common.GitLabTanuki)
	}
	sess.Out.Important("Press Ctrl+C to stop web server and exit.\n\n")
	select {}
}
