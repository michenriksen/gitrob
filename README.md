# Gitrob: Putting the Open Source in OSINT

Gitrob is a command line tool which can help organizations and security professionals find sensitive information lingering in publicly available files on GitHub. The tool will iterate over all public organization and member repositories and match filenames against a range of patterns for files that typically contain sensitive or dangerous information.

Looking for sensitive information in GitHub repositories is not a new thing, it has been [known for a while](http://blog.conviso.com.br/2013/06/github-hacking-for-fun-and-sensitive.html) that things such as private keys and credentials can be found with GitHub's search functionality, however Gitrob makes it easier to focus the effort on a specific organization.

## Installation

### 1. Ruby

Gitrob is written in [Ruby](https://www.ruby-lang.org/) and requires at least version 1.9.3 or above. To check which version of Ruby you have installed, simply run `ruby --version` in a terminal.

Should you have an older version installed, it is very easy to upgrade and manage different versions with the Ruby Version Manager ([RVM](https://rvm.io/)). Please see the [RVM website](https://rvm.io/) for installation instructions.

### 2. RubyGems

Gitrob is packaged as a Ruby gem to make it easy to install and update. To install Ruby gems you'll need the RubyGems tool installed. To check if you have it already, type `gem` in a Terminal. If you got it already, it is recommended to do a quick `gem update --system` to make sure you have the latest and greatest version. In case you don't have it installed, download it from [here](https://rubygems.org/pages/download) and follow the simple installation instructions.

### 3. PostgreSQL

Gitrob uses a PostgreSQL database to store all the collected data. If you are setting up Gitrob in the [Kali](https://www.kali.org/) linux distribution you already have it installed, you just need to make sure it's running by executing `service postgresql start` and install a dependency with `apt-get install libpq-dev` in a terminal. Here's an excellent [guide](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-9-4-on-debian-8) on how to install PostgreSQL on a Debian based Linux system. If you are setting up Gitrob on a Mac, the easiest way to install PostgreSQL is with [Homebrew](http://brew.sh/). Here's a [guide](http://exponential.io/blog/2015/02/21/install-postgresql-on-mac-os-x-via-brew/) on how to install PostgreSQL with Homebrew.

#### 3.1 PostgreSQL user and database

You need to set up a user and a database in PostgreSQL for Gitrob. Execute the following commands in a terminal:

    sudo su postgres # Not necessary on Mac OS X
    createuser -s gitrob --pwprompt
    createdb -O gitrob gitrob

You now have a new PostgreSQL user with the name `gitrob` and with the password you typed into the prompt. You also created a database with the name `gitrob` which is owned by the `gitrob` user.

### 4. GitHub access tokens

Gitrob works by querying the [GitHub API](https://developer.github.com/v3/) for interesting information, so you need at least one access token to get up and running. The easiest way is to create a [Personal Access Token](https://github.com/settings/tokens). Press the `Generate new token` button and give the token a description. If you intend on using Gitrob against organizations you're not a member of you don't need to give the token any scopes, as we will only be accessing public data. If you intend to run Gitrob against your own organization, you'll need to check the `read:org` scope to get full coverage.

If you plan on using Gitrob extensively or against a very large organization, it might be necessary to have multiple access tokens to avoid running into rate limiting. These access tokens will have to be from different user accounts.

### 5. Gitrob

With all the previous steps completed, you can now finally install Gitrob itself with the following command in a terminal:

    gem install gitrob

This will install the Gitrob Ruby gem along with all its dependencies. Congratulations!

### 6. Configuring Gitrob

Gitrob needs to know how to talk to the PostgreSQL database as well as what access token to use to access the GitHub API. Gitrob comes with a convenient configuration wizard which can be invoked with the following command in a terminal:

    gitrob configure

The configuration wizard will ask you for the information needed to set up Gitrob. All the information is saved to `~/.gitrobrc` and yes, Gitrob will be looking for this file too, so watch out!

## Usage

### Analyzing organizations and users

Analyzing organizations and users is the main feature of Gitrob. The `analyze` command accepts an arbitrary amount of organization and user logins, which will be bundled into an assessment:

    gitrob analyze acme,johndoe,janedoe

Mixing organizations and users is convenient if you know that a certain user is part of an organization but they do not have their membership public.

When the assessment is finished, the `analyze` command will automatically start up the web server to present the results. This can be avoided by adding the `--no-server` option to the command.

See `gitrob help analyze` for more options.

### Running Gitrob against custom GitHub Enterprise installations

Gitrob can analyze organizations and users on custom GitHub Enterprise installations instead of the official GitHub site. The `analyze` command takes several options to control this:

    gitrob analyze johndoe --site=https://github.acme.com --endpoint=https://github.acme.com/api --access-tokens=token1,token2

See `gitrob help analyze` for more options.

### Starting the Gitrob web server

The Gitrob web server can be started with the `server` command:

    gitrob server

By default, the server will listen on [localhost:9393](http://localhost:9393). This can of course all be controlled:

    gitrob server --bind-address=0.0.0.0 --port=8000

See `gitrob help server` for more options.

### Starting the web server

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec gitrob` to use the gem in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Contributions are welcome! Read [CONTRIBUTING.md](CONTRIBUTING.md) to get started.

## License

Gitrob is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
