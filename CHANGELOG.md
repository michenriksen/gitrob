
# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## 3.1.3-alpha 2020-05-04
### Added
- Bug fixes for content scans that hit really large commits.  This bug is due to an issue the go-diff depenency used by go-git:  https://github.com/sergi/go-diff/issues/89

## 3.1.2-alpha 2020-05-03
### Added
- Bug fixes for UI:  results should now load in the modal properly
- Added GitHub action for branch and master builds

## 3.1.1-alpha 2020-04-08
### Changed
- Resolved a dependency problem where the locked version of github.com/xanzy/go-gitlab was incorrect.
- Removed rate limit handling for GitLab API requests from gitrob directly in leu of go-gitlab's new implementation with the newly locked version.

## 3.1.0-alpha 2020-03-30
### Added
- Docker support
- Bug fix:  include go-gitlab in dep dependency .toml and .lock files.

### Changed
- Windows releases have been removed temporarily due to a platform build issue introduced with github.com/xanzy/go-gitlab

## 3.0.0-alpha - 2020-03-27
### Added
- Support for GitLab users and groups
- Support for multiple modes of execution including content search
    - Mode 1 - Default mode to match on [file signatures](./filesignatures.json)
    - Mode 2 - Match on [file signatures](./filesignatures.json) then [content signatures](./contentsignatures.json) to constitute a result.
    - Mode 3 - Match on [content signatures](./contentsignatures.json) only without file signature matches.
- Support for in-memory repository clones, which can result in significantly faster analysis times depending on your hardware.
- File signatures for Google Cloud Platform credentials
- Content signatures similar to [trufflehog](https://github.com/dxa4481/truffleHogRegexes/blob/master/truffleHogRegexes/regexes.json).
- Dependency management with dep

### Changed
- Skip expensive signature checking for image extensions and files in `node_modules` and other package directories

## 2.0.0-beta - 2018-06-08
### Added
- Total rewrite of Gitrob in [Golang](https://golang.org/)
- Find interesting files in history down to a default (and configurable) depth of 500 commits
- Hexdump view for binary files
- Saving and loading of session files for easy sharing

### Removed
- All the stupid Rubygems with native extensions
- PostgreSQL dependency
- Messy assessment comparison feature
- User overview
- Repository overview

[Unreleased]: https://github.com/michenriksen/gitrob/compare/v2.0.0-beta...HEAD
