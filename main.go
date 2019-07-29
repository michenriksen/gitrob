package main

import (
  "fmt"
  "os"
  "strings"
  "sync"
  "time"

  "github.com/michenriksen/gitrob/core"
)

var (
  sess *core.Session
  err  error
)

func GatherTargets(sess *core.Session) {
  sess.Stats.Status = core.StatusGathering
  sess.Out.Important("Gathering targets...\n")
  for _, login := range sess.Options.Logins {
    target, err := core.GetUserOrOrganization(login, sess.GithubClient)
    if err != nil {
      sess.Out.Error(" Error retrieving information on %s: %s\n", login, err)
      continue
    }
    sess.Out.Debug("%s (ID: %d) type: %s\n", *target.Login, *target.ID, *target.Type)
    sess.AddTarget(target)
    if *sess.Options.NoExpandOrgs == false && *target.Type == "Organization" {
      sess.Out.Debug("Gathering members of %s (ID: %d)...\n", *target.Login, *target.ID)
      members, err := core.GetOrganizationMembers(target.Login, sess.GithubClient)
      if err != nil {
        sess.Out.Error(" Error retrieving members of %s: %s\n", *target.Login, err)
        continue
      }
      for _, member := range members {
        sess.Out.Debug("Adding organization member %s (ID: %d) to targets\n", *member.Login, *member.ID)
        sess.AddTarget(member)
      }
    }
  }
}

func GatherRepositories(sess *core.Session) {
  var ch = make(chan *core.GithubOwner, len(sess.Targets))
  var wg sync.WaitGroup
  var threadNum int
  if len(sess.Targets) == 1 {
    threadNum = 1
  } else if len(sess.Targets) <= *sess.Options.Threads {
    threadNum = len(sess.Targets) - 1
  } else {
    threadNum = *sess.Options.Threads
  }
  wg.Add(threadNum)
  sess.Out.Debug("Threads for repository gathering: %d\n", threadNum)
  for i := 0; i < threadNum; i++ {
    go func() {
      for {
        var repos []*core.GithubRepository
	var err error
        target, ok := <-ch
        if !ok {
          wg.Done()
          return
        }
	if *target.Type == "Organization" {
		repos, err = core.GetRepositoriesFromOrganization(target.Login, sess.GithubClient)
	} else {
		repos, err = core.GetRepositoriesFromOwner(target.Login, sess.GithubClient)
	}
        if err != nil {
          sess.Out.Error(" Failed to retrieve repositories from %s: %s\n", *target.Login, err)
        }
        if len(repos) == 0 {
          continue
        }
        for _, repo := range repos {
          sess.Out.Debug(" Retrieved repository: %s\n", *repo.FullName)
          sess.AddRepository(repo)
        }
        sess.Stats.IncrementTargets()
        sess.Out.Info(" Retrieved %d %s from %s\n", len(repos), core.Pluralize(len(repos), "repository", "repositories"), *target.Login)
      }
    }()
  }

  for _, target := range sess.Targets {
    ch <- target
  }
  close(ch)
  wg.Wait()
}

func AnalyzeRepositories(sess *core.Session) {
  sess.Stats.Status = core.StatusAnalyzing
  var ch = make(chan *core.GithubRepository, len(sess.Repositories))
  var wg sync.WaitGroup
  var threadNum int
  if len(sess.Repositories) <= 1 {
    threadNum = 1
  } else if len(sess.Repositories) <= *sess.Options.Threads {
    threadNum = len(sess.Repositories) - 1
  } else {
    threadNum = *sess.Options.Threads
  }
  wg.Add(threadNum)
  sess.Out.Debug("Threads for repository analysis: %d\n", threadNum)

  sess.Out.Important("Analyzing %d %s...\n", len(sess.Repositories), core.Pluralize(len(sess.Repositories), "repository", "repositories"))

  githubURL := sess.GithubURL()

  for i := 0; i < threadNum; i++ {
    go func(tid int) {
      for {
        sess.Out.Debug("[THREAD #%d] Requesting new repository to analyze...\n", tid)
        repo, ok := <-ch
        if !ok {
          sess.Out.Debug("[THREAD #%d] No more tasks, marking WaitGroup as done\n", tid)
          wg.Done()
          return
        }

        sess.Out.Debug("[THREAD #%d][%s] Cloning repository...\n", tid, *repo.FullName)
        clone, path, err := core.CloneRepository(repo.CloneURL, repo.DefaultBranch, sess)
        if err != nil {
          if err.Error() != "remote repository is empty" {
            sess.Out.Error("Error cloning repository %s: %s\n", *repo.FullName, err)
          }
          sess.Stats.IncrementRepositories()
          sess.Stats.UpdateProgress(sess.Stats.Repositories, len(sess.Repositories))
          continue
        }
        sess.Out.Debug("[THREAD #%d][%s] Cloned repository to: %s\n", tid, *repo.FullName, path)

        history, err := core.GetRepositoryHistory(clone)
        if err != nil {
          sess.Out.Error("[THREAD #%d][%s] Error getting commit history: %s\n", tid, *repo.FullName, err)
          os.RemoveAll(path)
          sess.Stats.IncrementRepositories()
          sess.Stats.UpdateProgress(sess.Stats.Repositories, len(sess.Repositories))
          continue
        }
        sess.Out.Debug("[THREAD #%d][%s] Number of commits: %d\n", tid, *repo.FullName, len(history))

        for _, commit := range history {
          sess.Out.Debug("[THREAD #%d][%s] Analyzing commit: %s\n", tid, *repo.FullName, commit.Hash)
          changes, _ := core.GetChanges(commit, clone)
          sess.Out.Debug("[THREAD #%d][%s] Changes in %s: %d\n", tid, *repo.FullName, commit.Hash, len(changes))
          for _, change := range changes {
            changeAction := core.GetChangeAction(change)
            path := core.GetChangePath(change)
            matchFile := core.NewMatchFile(path)
            if matchFile.IsSkippable() {
              sess.Out.Debug("[THREAD #%d][%s] Skipping %s\n", tid, *repo.FullName, matchFile.Path)
              continue
            }
            sess.Out.Debug("[THREAD #%d][%s] Matching: %s...\n", tid, *repo.FullName, matchFile.Path)
            for _, signature := range core.Signatures {
              if signature.Match(matchFile) {

                finding := &core.Finding{
                  FilePath:        path,
                  Action:          changeAction,
                  Description:     signature.Description(),
                  Comment:         signature.Comment(),
                  RepositoryOwner: *repo.Owner,
                  RepositoryName:  *repo.Name,
                  CommitHash:      commit.Hash.String(),
                  CommitMessage:   strings.TrimSpace(commit.Message),
                  CommitAuthor:    commit.Author.String(),
                }
                finding.Initialize(githubURL)
                sess.AddFinding(finding)

                sess.Out.Warn(" %s: %s\n", strings.ToUpper(changeAction), finding.Description)
                sess.Out.Info("  Path.......: %s\n", finding.FilePath)
                sess.Out.Info("  Repo.......: %s\n", *repo.FullName)
                sess.Out.Info("  Message....: %s\n", core.TruncateString(finding.CommitMessage, 100))
                sess.Out.Info("  Author.....: %s\n", finding.CommitAuthor)
                if finding.Comment != "" {
                  sess.Out.Info("  Comment....: %s\n", finding.Comment)
                }
                sess.Out.Info("  File URL...: %s\n", finding.FileUrl)
                sess.Out.Info("  Commit URL.: %s\n", finding.CommitUrl)
                sess.Out.Info(" ------------------------------------------------\n\n")
                sess.Stats.IncrementFindings()
                break
              }
            }
            sess.Stats.IncrementFiles()
          }
          sess.Stats.IncrementCommits()
          sess.Out.Debug("[THREAD #%d][%s] Done analyzing changes in %s\n", tid, *repo.FullName, commit.Hash)
        }
        sess.Out.Debug("[THREAD #%d][%s] Done analyzing commits\n", tid, *repo.FullName)
        os.RemoveAll(path)
        sess.Out.Debug("[THREAD #%d][%s] Deleted %s\n", tid, *repo.FullName, path)
        sess.Stats.IncrementRepositories()
        sess.Stats.UpdateProgress(sess.Stats.Repositories, len(sess.Repositories))
      }
    }(i)
  }
  for _, repo := range sess.Repositories {
    ch <- repo
  }
  close(ch)
  wg.Wait()
}

func PrintSessionStats(sess *core.Session) {
  sess.Out.Info("\nFindings....: %d\n", sess.Stats.Findings)
  sess.Out.Info("Files.......: %d\n", sess.Stats.Files)
  sess.Out.Info("Commits.....: %d\n", sess.Stats.Commits)
  sess.Out.Info("Repositories: %d\n", sess.Stats.Repositories)
  sess.Out.Info("Targets.....: %d\n\n", sess.Stats.Targets)
}

func main() {
  if sess, err = core.NewSession(); err != nil {
    fmt.Println(err)
    os.Exit(1)
  }

  sess.Out.Info("%s\n\n", core.ASCIIBanner)
  sess.Out.Important("%s v%s started at %s\n", core.Name, core.Version, sess.Stats.StartedAt.Format(time.RFC3339))
  sess.Out.Important("Loaded %d signatures\n", len(core.Signatures))
  if !*sess.Options.NoServer {
    sess.Out.Important("Web interface available at http://%s:%d\n", *sess.Options.BindAddress, *sess.Options.Port)
  }

  if sess.Stats.Status == "finished" {
    sess.Out.Important("Loaded session file: %s\n", *sess.Options.Load)
  } else {
    if len(sess.Options.Logins) == 0 {
      sess.Out.Fatal("Please provide at least one GitHub organization or user\n")
    }

    GatherTargets(sess)
    GatherRepositories(sess)
    AnalyzeRepositories(sess)
    sess.Finish()

    if *sess.Options.Save != "" {
      err := sess.SaveToFile(*sess.Options.Save)
      if err != nil {
        sess.Out.Error("Error saving session to %s: %s\n", *sess.Options.Save, err)
      }
      sess.Out.Important("Saved session to: %s\n\n", *sess.Options.Save)
    }
  }

  PrintSessionStats(sess)
  if !*sess.Options.NoServer {
    sess.Out.Important("Press Ctrl+C to stop web server and exit.\n\n")
    select {}
  }
}
