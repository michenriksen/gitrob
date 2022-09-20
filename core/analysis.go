package core

import (
	"fmt"
	"gitrob/common"
	"gitrob/github"
	"gitrob/gitlab"
	"gitrob/matching"
	"gopkg.in/src-d/go-git.v4"
	"gopkg.in/src-d/go-git.v4/plumbing/object"
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
				var repos []*common.Repository
				var err error
				target, ok := <-ch
				if !ok {
					wg.Done()
					return
				}
				if *target.Type == "Organization" {
					repos, err = sess.Client.GetRepositoriesFromOrganization(*target)
				} else {
					repos, err = sess.Client.GetRepositoriesFromOwner(*target)
				}
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
				sess.Out.Info(" Retrieved %d %s from %s\n", len(repos), common.Pluralize(len(repos), "repository", "repositories"), *target.Login)
			}
		}()
	}

	for _, target := range sess.Targets {
		ch <- target
	}
	close(ch)
	wg.Wait()
}

func deletePath(path string, cloneUrl string, threadId int, sess *Session) {
	if path != "" {
		err := os.RemoveAll(path)
		if err != nil {
			sess.Out.Error("[THREAD #%d][%s] Unable to delete path %s\n", threadId, cloneUrl, path)
		} else {
			sess.Out.Debug("[THREAD #%d][%s] Deleted clone path %s\n", threadId, cloneUrl, path)
		}
	}
}

func createFinding(repo common.Repository,
	commit object.Commit,
	change *object.Change,
	fileSignature matching.FileSignature,
	contentSignature matching.ContentSignature,
	isGitHubSession bool) *matching.Finding {

	finding := &matching.Finding{
		FilePath:                    common.GetChangePath(change),
		Action:                      common.GetChangeAction(change),
		FileSignatureDescription:    fileSignature.GetDescription(),
		FileSignatureComment:        fileSignature.GetComment(),
		ContentSignatureDescription: contentSignature.GetDescription(),
		ContentSignatureComment:     contentSignature.GetComment(),
		RepositoryOwner:             *repo.Owner,
		RepositoryName:              *repo.Name,
		CommitHash:                  commit.Hash.String(),
		CommitMessage:               strings.TrimSpace(commit.Message),
		CommitAuthor:                commit.Author.String(),
		CloneUrl:                    *repo.CloneURL,
	}
	finding.Initialize(isGitHubSession)
	return finding

}

func matchContent(sess *Session,
	matchTarget matching.MatchTarget,
	repo common.Repository,
	change *object.Change,
	commit object.Commit,
	fileSignature matching.FileSignature,
	threadId int) {

	content, err := common.GetChangeContent(change)
	if err != nil {
		sess.Out.Error("Error retrieving content in commit %s, change %s:  %s", commit.String(), change.String(), err)
	}
	matchTarget.Content = content
	sess.Out.Debug("[THREAD #%d][%s] Matching content in %s...\n", threadId, *repo.CloneURL, commit.Hash)
	for _, contentSignature := range sess.Signatures.ContentSignatures {
		matched, err := contentSignature.Match(matchTarget)
		if err != nil {
			sess.Out.Error("Error while performing content match with '%s': %s\n", contentSignature.Description, err)
		}
		if !matched {
			continue
		}
		finding := createFinding(repo, commit, change, fileSignature, contentSignature, sess.IsGithubSession)
		sess.AddFinding(finding)
	}
}

/*func saveChangeToJson(c *object.Change) error {
	sessionJson, err := json.Marshal(c)
	if err != nil {
		return err
	}
	path := fmt.Sprintf("change-%s.json", strconv.FormatInt(int64(rand.Intn(10000)), 16))
	file, err := os.Create(path)
	defer file.Close()
	file.Write(sessionJson)
	if err != nil {
		return err
	}
	return nil
}*/

func findSecrets(sess *Session, repo *common.Repository, commit *object.Commit, changes object.Changes, threadId int) {
	for _, change := range changes {
		/*err1 := saveChangeToJson(change)
		if err1 != nil {
			panic(err1)
		}*/
		path := common.GetChangePath(change)
		matchTarget := matching.NewMatchTarget(path)
		if matchTarget.IsSkippable() {
			sess.Out.Debug("[THREAD #%d][%s] Skipping %s\n", threadId, *repo.CloneURL, matchTarget.Path)
			continue
		}
		sess.Out.Debug("[THREAD #%d][%s] Inspecting file: %s...\n", threadId, *repo.CloneURL, matchTarget.Path)

		if *sess.Options.Mode != 3 {
			for _, fileSignature := range sess.Signatures.FileSignatures {
				matched, err := fileSignature.Match(matchTarget)
				if err != nil {
					sess.Out.Error(fmt.Sprintf("Error while performing file match: %s\n", err))
				}
				if !matched {
					continue
				}
				if *sess.Options.Mode == 1 {
					finding := createFinding(*repo, *commit, change, fileSignature,
						matching.ContentSignature{Description: "NA"}, sess.IsGithubSession)
					sess.AddFinding(finding)
				}
				if *sess.Options.Mode == 2 {
					matchContent(sess, matchTarget, *repo, change, *commit, fileSignature, threadId)
				}
				break
			}
			sess.Stats.IncrementFiles()
		} else {
			matchContent(sess, matchTarget, *repo, change, *commit, matching.FileSignature{Description: "NA"}, threadId)
			sess.Stats.IncrementFiles()
		}
	}
}

func cloneRepository(sess *Session, repo *common.Repository, threadId int) (*git.Repository, string, error) {
	sess.Out.Debug("[THREAD #%d][%s] Cloning repository...\n", threadId, *repo.CloneURL)

	userName := "oauth2"

	cloneConfig := common.CloneConfiguration{
		Url:        repo.CloneURL,
		Branch:     repo.DefaultBranch,
		Depth:      sess.Options.CommitDepth,
		InMemClone: sess.Options.InMemClone,
		Username: &userName,
	}

	var clone *git.Repository
	var path string
	var err error

	if sess.IsGithubSession {
		cloneConfig.Token = &sess.Github.AccessToken
		clone, path, err = github.CloneRepository(&cloneConfig)
	} else {
		cloneConfig.Token = &sess.GitLab.AccessToken
		clone, path, err = gitlab.CloneRepository(&cloneConfig)
	}
	if err != nil {
		if err.Error() != "remote repository is empty" {
			sess.Out.Error("Error cloning repository %s: %s\n", *repo.CloneURL, err)
		}
		sess.Stats.IncrementRepositories()
		sess.Stats.UpdateProgress(sess.Stats.Repositories, len(sess.Repositories))
		return nil, "", err
	}
	sess.Out.Debug("[THREAD #%d][%s] Cloned repository to: %s\n", threadId, *repo.CloneURL, path)
	return clone, path, err
}

func getRepositoryHistory(sess *Session, clone *git.Repository, repo *common.Repository, path string, threadId int) ([]*object.Commit, error) {
	history, err := common.GetRepositoryHistory(clone)
	if err != nil {
		sess.Out.Error("[THREAD #%d][%s] Error getting commit history: %s\n", threadId, *repo.CloneURL, err)
		deletePath(path, *repo.CloneURL, threadId, sess)
		sess.Stats.IncrementRepositories()
		sess.Stats.UpdateProgress(sess.Stats.Repositories, len(sess.Repositories))
		return nil, err
	}
	sess.Out.Debug("[THREAD #%d][%s] Number of commits: %d\n", threadId, *repo.CloneURL, len(history))
	return history, err
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

	sess.Out.Important("Analyzing %d %s...\n", len(sess.Repositories), common.Pluralize(len(sess.Repositories), "repository", "repositories"))

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

				clone, path, err := cloneRepository(sess, repo, tid)
				if err != nil {
					continue
				}

				history, err := getRepositoryHistory(sess, clone, repo, path, tid)
				if err != nil {
					continue
				}

				for _, commit := range history {
					sess.Out.Debug("[THREAD #%d][%s] Analyzing commit: %s\n", tid, *repo.CloneURL, commit.Hash)
					changes, _ := common.GetChanges(commit, clone)
					sess.Out.Debug("[THREAD #%d][%s] %s changes in %d\n", tid, *repo.CloneURL, commit.Hash, len(changes))

					findSecrets(sess, repo, commit, changes, tid)

					sess.Stats.IncrementCommits()
					sess.Out.Debug("[THREAD #%d][%s] Done analyzing changes in %s\n", tid, *repo.CloneURL, commit.Hash)
				}

				sess.Out.Debug("[THREAD #%d][%s] Done analyzing commits\n", tid, *repo.CloneURL)
				deletePath(path, *repo.CloneURL, tid, sess)
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
