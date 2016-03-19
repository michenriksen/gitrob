# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Fixed
 - The `--verify-ssl` command option did not properly set SSL configuration
   on GitHub API clients.
 - Setting GitHub access tokens with `--access-tokens` command option resulted
   in an error.
 - Analyze command did not collect private repositories from organizations.

## [1.0.0]
### Added
 - Complete rewrite of Gitrob
 - Analyze arbitrary amount of organizations and users
 - Create and delete assessments directly from web interface
 - Run Gitrob against GitHub Enterprise installations
 - Compare two assessments to find new/modified files as well as new users and repositories
 - Highlight interesting things such as hostnames, IPs, email addresses and tokens in files
 - Detect likely testing/mock related files
 - General web UI/UX improvements
 - More tests

### Changed
 - Use [sequel](https://rubygems.org/gems/sequel) Gem for database operations
 - Use [github_api](https://rubygems.org/gems/github_api) Gem for GitHub API operations
 - Use [thor](https://rubygems.org/gems/thor) Gem for CLI
 - Rename `patterns.json` to `signatures.json`

### New signatures
 - SSH configuration files (`path =~ /\.?ssh/config\z/`)
 - Postgresql password files (`filename =~ /\A\.?pgpass\z/`)
 - AWS CLI credential files (`path =~ /\.?aws/credentials\z/`)
 - Day One journal files (`extension == "dayone"`)
 - jrnl journal files (`filename == "journal.txt"`)
 - Tugboat DigitalOcean management tool configuration files (`filename =~ /\A\.?tugboat\z/`)
 - git-credential-store helper credential files (`filename =~ /\A\.?git-credentials\z/`)
 - Git configuration files (`filename =~ /\A\.?gitconfig\z/`)
 - Chef Knife configuration file (`filename == "knife.rb"`)
 - Chef private keys (`path =~ /\.?chef/(.*)\.pem\z/`)
 - cPanel backup ProFTPd credential files (`filename == "proftpdpasswd"`)
 - Robomongo MongoDB manager configuration files (`filename == "robomongo.json"`)
 - FileZilla FTP configuration files (`filename == "filezilla.xml"`)
 - FileZilla FTP recent servers files (`filename == "recentservers.xml"`)
 - Ventrilo server configuration files (`filename == "ventrilo_srv.ini"`)
 - Docker configuration files (`filename =~ /\A\.?dockercfg\z/`)
 - NPM configuration file (`filename =~ /\A\.?npmrc\z/`)
 - Files containing word: credential (`filename =~ /credential/`)
 - Files containing word: secret (`filename =~ /secret/`)
