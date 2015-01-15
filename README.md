# Gitrob

Developers generally like to share their code, and many of them do so by open sourcing it on GitHub, a social code hosting and collaboration service. Many companies also use GitHub as a convenient place to host both private and public code repositories by creating GitHub organizations where employees can be joined.

Sometimes employees might publish things that should not be publicly available, things that contain sensitive information or things that could even lead to direct compromise of a system. This can happen by accident or because the employee does not know the sensitivity of the information.

Gitrob is a command line tool that can help organizations and security professionals find such sensitive information. The tool will iterate over all public organization and member repositories and match filenames against a range of patterns for files, that typically contain sensitive or dangerous information.

Read the [blog post](http://michenriksen.com/blog/gitrob-putting-the-open-source-in-osint/) for more information and screenshots.

## How it works

Looking for sensitive information in GitHub repositories is not a new thing, it has been [known for a while](http://blog.conviso.com.br/2013/06/github-hacking-for-fun-and-sensitive.html) that things such as private keys and credentials can be found with GitHub's search functionality, however Gitrob makes it easier to focus the effort on a specific organization.

The first thing the tool does is to collect all public repositories of the organization itself. It then goes on to collect all the organization members and their public repositories, in order to compile a list of repositories that might be related or have relevance to the organization.

When the list of repositories has been compiled, it proceeds to gather all the filenames in each repository and runs them through a series of observers that will flag the files, if they match any patterns of known sensitive files. This step might take a while if the organization is big or if the members have a lot of public repositories.

All of the members, repositories and files will be saved to a PostgreSQL database. When everything has been sifted through, it will start a Sinatra web server locally on the machine, which will serve a simple web application to present the collected data for analysis.

## Installation

Gitrob is written in Ruby and requires at least version 1.9.3 or above. If you are on an older version, it is very easy to install newer versions with [RVM](http://rvm.io/). If you are installing Gitrob on [Kali](http://www.kali.org/), you are almost good to go, you just need to update Bundler with `gem install bundler`. It might also be necessary to install a PostgreSQL dependency with `apt-get install postgresql-server-dev-9.1` in a terminal.

Gitrob is a Ruby gem, so installation is a simple `gem install gitrob` in a terminal. This will automatically install all the code dependencies as well.

A [PostgreSQL](http://www.postgresql.org/) database is also needed for Gitrob to store its data. Installing PostgreSQL is pretty straight forward; here is an installation guide for [Mac OS X](http://www.gotealeaf.com/blog/how-to-install-postgresql-on-a-mac) and one for [Ubuntu/Debian](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-14-04) based Linux. If you're installing Gitrob on Kali, you already have PostgreSQL installed, however you need to start the server with `service postgresql start` in a terminal.

The last thing we need is a GitHub access token in order to be able to talk to their API. The easiest way is to create a [personal access token](https://github.com/settings/applications). If you plan on using Gitrob extensively or on a very big organization, it might be necessary to have multiple access tokens to prevent running into rate limiting, but they need to be from different user accounts.

When everything is ready, simply run `gitrob --configure` and you will be presented with a configuration wizard that asks you for database connection details and GitHub access tokens. All of this configuration can be changed by running the same command again. The configuration will be saved in `~/.gitrobrc` - and yes, Gitrob is looking for this file too so watch out.

When everything is set up, you can start analyzing organizations by running `gitrob -o <orgname>` in a terminal. To see options, use `gitrob --help`.

## Contributing

Gitrob should be considered Beta and there is probably a good amount of bugs. Bug reports and suggestions for improvements are welcome!

Another way to help out is to contribute new patterns for sensitive files. If you know of any sensitive files that are not already identified, please submit them in a pull request. I am especially interested in sensitive web framework files and configuration files. Have a look at the [patterns.json](https://github.com/michenriksen/gitrob/blob/master/patterns.json) file to see what is already looked for.

### How to make a pull request:

1. Fork it ( https://github.com/michenriksen/gitrob/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
