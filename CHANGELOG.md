
# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
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
