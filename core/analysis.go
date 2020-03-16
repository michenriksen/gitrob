package core

import (
	"github.com/codeEmitter/gitrob/common"
	"github.com/codeEmitter/gitrob/github"
	"github.com/codeEmitter/gitrob/gitlab"
	"github.com/codeEmitter/gitrob/matching"
	"gopkg.in/src-d/go-git.v4"
	"os"
	"strings"
	"sync"
)

func PrintSessionStats(sess *Session) {
	sess.Out.Info("\nFindings....: %d\n", sess.Stats.Findings)
	sess.Out.Info("Files.......: %d\n", sess.Stats.Files)
	sess.Out.Info("Commits.....: %d\n", sess.Stats.Commits)
	sess.Out.Info("Repositories: %d\n", sess.Stats.Repositories)
	sess.Out.Info("Targets.....: %d\n\n", sess.Stats.Targets)
}

func GatherTargets(sess *Session) {
	sess.Stats.Status = StatusGathering
	sess.Out.Important("Gathering targets...\n")

	for _, loginOption := range sess.Options.Logins {
		target, err := sess.Client.GetUserOrOrganization(loginOption)
		if err != nil || target == nil {
			sess.Out.Error(" Error retrieving information on %s: %s\n", loginOption, err)
			continue
		}
		sess.Out.Debug("%s (ID: %d) type: %s\n", *target.Login, *target.ID, *target.Type)
		sess.AddTarget(target)
		if *sess.Options.NoExpandOrgs == false && *target.Type == common.TargetTypeOrganization {
			sess.Out.Debug("Gathering members of %s (ID: %d)...\n", *target.Login, *target.ID)
			members, err := sess.Client.GetOrganizationMembers(*target)
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

func GatherRepositories(sess *Session) {
	var ch = make(chan *common.Owner, len(sess.Targets))
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
				target, ok := <-ch
				if !ok {
					wg.Done()
					return
				}
				repos, err := sess.Client.GetRepositoriesFromOwner(*target)
				if err != nil {
					sess.Out.Error(" Failed to retrieve repositories from %s: %s\n", *target.Login, err)
				}
				if len(repos) == 0 {
					continue
				}
				for _, repo := range repos {
					sess.Out.Debug(" Retrieved repository: %s\n", *repo.CloneURL)
					sess.AddRepository(repo)
				}
				sess.Stats.IncrementTargets()
				sess.Out.Info(" Retrieved %d %s from %s\n", len(repos), Pluralize(len(repos), "repository", "repositories"), *target.Login)
			}
		}()
	}

	for _, target := range sess.Targets {
		ch <- target
	}
	close(ch)
	wg.Wait()
}

func AnalyzeRepositories(sess *Session) {
	sess.Stats.Status = StatusAnalyzing
	var ch = make(chan *common.Repository, len(sess.Repositories))
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

	sess.Out.Important("Analyzing %d %s...\n", len(sess.Repositories), Pluralize(len(sess.Repositories), "repository", "repositories"))

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

				sess.Out.Debug("[THREAD #%d][%s] Cloning repository...\n", tid, *repo.CloneURL)
				clone, path, err := func() (*git.Repository, string, error) {
					cloneConfig := common.CloneConfiguration{
						Url:    repo.CloneURL,
						Branch: repo.DefaultBranch,
						Depth:  sess.Options.CommitDepth,
						Token:  &sess.GitLab.AccessToken,
					}
					if sess.Github.AccessToken != "" {
						return github.CloneRepository(&cloneConfig)
					} else {
						userName := "oauth2"
						cloneConfig.Username = &userName
						return gitlab.CloneRepository(&cloneConfig)
					}
				}()
				if err != nil {
					if err.Error() != "remote repository is empty" {
						sess.Out.Error("Error cloning repository %s: %s\n", *repo.CloneURL, err)
					}
					sess.Stats.IncrementRepositories()
					sess.Stats.UpdateProgress(sess.Stats.Repositories, len(sess.Repositories))
					continue
				}
				sess.Out.Debug("[THREAD #%d][%s] Cloned repository to: %s\n", tid, *repo.CloneURL, path)

				history, err := common.GetRepositoryHistory(clone)
				if err != nil {
					sess.Out.Error("[THREAD #%d][%s] Error getting commit history: %s\n", tid, *repo.CloneURL, err)
					os.RemoveAll(path)
					sess.Stats.IncrementRepositories()
					sess.Stats.UpdateProgress(sess.Stats.Repositories, len(sess.Repositories))
					continue
				}
				sess.Out.Debug("[THREAD #%d][%s] Number of commits: %d\n", tid, *repo.CloneURL, len(history))

				for _, commit := range history {
					sess.Out.Debug("[THREAD #%d][%s] Analyzing commit: %s\n", tid, *repo.CloneURL, commit.Hash)
					changes, _ := common.GetChanges(commit, clone)
					sess.Out.Debug("[THREAD #%d][%s] Changes in %s: %d\n", tid, *repo.CloneURL, commit.Hash, len(changes))
					for _, change := range changes {
						changeAction := common.GetChangeAction(change)
						path := common.GetChangePath(change)
						matchFile := matching.NewMatchFile(path)
						if matchFile.IsSkippable() {
							sess.Out.Debug("[THREAD #%d][%s] Skipping %s\n", tid, *repo.CloneURL, matchFile.Path)
							continue
						}
						sess.Out.Debug("[THREAD #%d][%s] Matching: %s...\n", tid, *repo.CloneURL, matchFile.Path)
						for _, signature := range matching.FileSignatures {
							if signature.Match(matchFile) {

								finding := &matching.Finding{
									FilePath:        path,
									Action:          changeAction,
									Description:     signature.GetDescription(),
									Comment:         signature.GetComment(),
									RepositoryOwner: *repo.Owner,
									RepositoryName:  *repo.Name,
									CommitHash:      commit.Hash.String(),
									CommitMessage:   strings.TrimSpace(commit.Message),
									CommitAuthor:    commit.Author.String(),
								}
								finding.Initialize(sess.Github.AccessToken != "")
								sess.AddFinding(finding)

								sess.Out.Warn(" %s: %s\n", strings.ToUpper(changeAction), finding.Description)
								sess.Out.Info("  Path.......: %s\n", finding.FilePath)
								sess.Out.Info("  Repo.......: %s\n", *repo.CloneURL)
								sess.Out.Info("  Message....: %s\n", TruncateString(finding.CommitMessage, 100))
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
					sess.Out.Debug("[THREAD #%d][%s] Done analyzing changes in %s\n", tid, *repo.CloneURL, commit.Hash)
				}
				sess.Out.Debug("[THREAD #%d][%s] Done analyzing commits\n", tid, *repo.CloneURL)
				os.RemoveAll(path)
				sess.Out.Debug("[THREAD #%d][%s] Deleted %s\n", tid, *repo.CloneURL, path)
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
