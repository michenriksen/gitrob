![Gitrob](https://github.com/codeEmitter/gitrob/workflows/Gitrob/badge.svg)

<p align="center">
  <img src="./static/images/gopher_full.png" alt="Gitrob" width="200" />
</p>

# Gitrob: Putting the Open Source in OSINT

Gitrob is a tool to help find potentially sensitive information pushed to repositories on GitLab or Github. Gitrob will clone repositories belonging to a user or group/organization down to a configurable depth and iterate through the commit history and flag files and/or commit content that match signatures for potentially sensitive information. The findings will be presented through a web interface for easy browsing and analysis.

## Usage

    gitrob [options] target [target2] ... [targetN]

**IMPORTANT** If you are targeting a GitLab group, please give the **group ID** as the target argument.  You can find the group ID just below the group name in the GitLab UI.  Otherwise, names with suffice for the target arguments.

### Options

```
-bind-address string
    Address to bind web server to (default "127.0.0.1")
-commit-depth int
    Number of repository commits to process (default 500)
-debug
    Print debugging information
-github-access-token string
    Github access token to use for API requests (set one)
-gitlab-access-token string
    GitLab access token to use for API requests (set one)
-in-mem-clone
    Clone repositories into memory for faster analysis depending on your hardware
-load string
    Load session file from specified path
-mode int {1, 2, or 3}
    Designate a mode for execution.  Mode 1 (default) searches for file signature matches.  Mode 2 (-mode 2) searches for file signature matches.  Given a file signature match, mode 2 then attempts to match on content in order to produce a result.  Mode 3 (-mode 3) searches by content matches only.  In mode 3, no file signature matches are performed.
-no-expand-orgs
    Don't add members to targets when processing organizations
-port int
    Port to run web server on (default 9393)
-save string
    Save session to a file at the given path
-silent
    Suppress all output except for errors
-threads int
    Number of concurrent threads (default number of logical CPUs)
```

## Examples

Scan a GitLab group assuming your access token has been added to the environment variable with name GITROB_GITLAB_ACCESS_TOKEN.  Look for file signature matches only:

    gitrob <gitlab_group_id>

Scan a multiple GitLab groups assuming your access token has been added to the environment variable with name GITROB_GITLAB_ACCESS_TOKEN.  Clone repositories into memory for faster analysis.  Set the scan mode to 2 to scan each file match for a content match before creating a result.  Save the results to `./output.json`:

    gitrob -in-mem-clone -mode 2 -save "./output.json"  <gitlab_group_id_1> <gitlab_group_id_2>

Scan a GitLab groups assuming your access token has been added to the environment variable with name GITROB_GITLAB_ACCESS_TOKEN.  Clone repositories into memory for faster analysis.  Set the scan mode to 3 to scan each commit for content matches only.  Save the results to `./output.json`:

    gitrob -in-mem-clone -mode 3 -save "./output.json"  <gitlab_group_id>

Scan a Github user setting your Github access token as a parameter.  Clone repositories into memory for faster analysis.

    gitrob -github-access-token <token> -in-mem-clone <github_user_name>

### Editing File and Content Regular Expressions

Regular expressions are included in the [filesignatures.json](./filesignatures.json) and [contentsignatures.json](./contentsignatures.json) files respectively.  Edit these files to adjust your scope and fine-tune your results.

### Loading session from a file

A session stored in a file can be loaded with the `-load` option:

    gitrob -load ./output.json

Gitrob will start its web interface and serve the results for analysis.

## Installation

A [precompiled version is available](https://github.com/codeEmitter/gitrob/releases) for each release, alternatively you can use the latest version of the source code from this repository in order to build your own binary.

To install from source, make sure you have a correctly configured **Go >= 1.8** environment and that `$GOPATH/bin` is in your `$PATH`.  Also, make sure you have installed [dep](https://github.com/golang/dep) locally.

    $ go get github.com/codeEmitter/gitrob
    $ cd ~/go/src/github.com/codeEmitter/gitrob
    $ dep ensure
    $ go build

*Note that installing with `go install` will not work due to the static json file dependencies.  However, it was deemed more useful to have the files be adjustable without recompiling the binary than to have everything bundled into the binary itself.*

## Using docker

The [included Dockerfile](./Dockerfile) can be used to build images needed to run gitrob.  You can build a basic image with:

    docker build . -t gitrob:latest

You can then run the container, optionally specifying how many logical CPUs to allocate for concurrency with:

    docker run -p 9393:9393 --cpus <NUM_CPUS> gitrob:latest -bind-address 0.0.0.0 -github-access-token <token> -in-mem-clone -mode 2 <target1> <target2> ...

With this container running, use your browser to hit the UI with:  http://localhost:9393.

## Access Tokens

Gitrob will need either a GitLab or Github access token in order to interact with the appropriate API.  You can create a [GitLab personal access token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html), or [a Github personal access token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/) and save it in an environment variable in your `.bashrc` or similar shell configuration file:

    export GITROB_GITLAB_ACCESS_TOKEN=deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
    export GITROB_GITHUB_ACCESS_TOKEN=deadbeefdeadbeefdeadbeefdeadbeefdeadbeef

Alternatively you can specify the access token with the `-gitlab-access-token` or `-github-access-token` option on the command line, but watch out for your command history!
