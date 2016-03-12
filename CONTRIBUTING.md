# Contributing to Gitrob

Have a feature idea, bug fix, or refactoring suggestion? Contributions are welcome!

## Reporting Bugs

When you are creating a bug report, please [include as many details as possible](#how-do-i-submit-a-good-bug-report). If you'd like, you can use [this template](#template-for-submitting-bug-reports) to structure the information.

### How Do I Submit A (Good) Bug Report?

* **Use a clear and descriptive title** for the issue to identify the problem.
* **Describe the exact steps which reproduce the problem** in as many details as possible. For example, start by explaining how you started Gitrob, e.g. which command exactly you used in the terminal, or how you started Gitrob otherwise. When listing steps, **don't just say what you did, but explain how you did it**.
* **Describe the behavior you observed after following the steps** and point out what exactly is the problem with that behavior.
* **Explain which behavior you expected to see instead and why.**
* **Include screenshots and animated GIFs** which show you following the described steps and clearly demonstrate the problem. You can use [this tool](http://www.cockos.com/licecap/) to record GIFs on OSX and Windows, and [this tool](https://github.com/colinkeenan/silentcast) or [this tool](https://github.com/GNOME/byzanz) on Linux.
* **If you're reporting that Gitrob crashed**, include a stack trace/debugging information in a [code block](https://help.github.com/articles/markdown-basics/#multiple-lines), a [file attachment](https://help.github.com/articles/file-attachments-on-issues-and-pull-requests/), or put it in a [gist](https://gist.github.com/) and provide link to that gist.
* **If the problem wasn't triggered by a specific action**, describe what you were doing before the problem happened and share more information using the guidelines below.

Provide more context by answering these questions:

* **Did the problem start happening recently** (e.g. after updating to a new version of Gitrob) or was this always a problem?
* If the problem started happening recently, **can you reproduce the problem in an older version of Gitrob?** What's the most recent version in which the problem doesn't happen?
* **Can you reliably reproduce the issue?** If not, provide details about how often the problem happens and under which conditions it normally happens.
* If the problem is related to analyzing organizations, **does the problem happen for all organizations or only some?**

Include details about your configuration and environment:

* **Which version of Gitrob are you using?** You can get the exact version by running `gitrob` in your terminal, or by looking at the Footer area of the web application.
* **What's the name and version of the OS you're using**?
* **What version of Ruby are you running Gitrob with**? You can check the version with `ruby --version` in a terminal
* **What version of PostgreSQL do you have installed?** You can check the version with `postgres --version` in a terminal

### Template For Submitting Bug Reports

    [Short description of problem here]

    **Reproduction Steps:**

    1. [First Step]
    2. [Second Step]
    3. [Other Steps...]

    **Expected behavior:**

    [Describe expected behavior here]

    **Observed behavior:**

    [Describe observed behavior here]

    **Screenshots and GIFs**

    ![Screenshots and GIFs which follow reproduction steps to demonstrate the problem](url)

    **Gitrob version:** [Enter Gitrob version here]
    **OS and version:** [Enter OS name and version here]
    **Ruby version:** [Enter Ruby version here]
    **PostgreSQL version:** [Enter PostgreSQL version here]

    **Additional information:**

    * Problem started happening recently, didn't happen in an older version of Gitrob: [Yes/No]
    * Problem can be reliably reproduced, doesn't happen randomly: [Yes/No]
    * Problem happens with all assessments, not only some assessments: [Yes/No]

## Suggesting Enhancements

When you are creating an enhancement suggestion, please [include as many details as possible](#how-do-i-submit-a-good-enhancement-suggestion). If you'd like, you can use [this template](#template-for-submitting-enhancement-suggestions) to structure the information.

### Before Submitting An Enhancement Suggestion

* **Perform a [cursory search](https://github.com/michenriksen/gitrob/issues?utf8=%E2%9C%93&q=is%3Aissue)** to see if the enhancement has already been suggested. If it has, add a comment to the existing issue instead of opening a new one.

### How Do I Submit A (Good) Enhancement Suggestion?

Enhancement suggestions are tracked as [GitHub issues](https://guides.github.com/features/issues/). Create an issue and provide the following information:

* **Use a clear and descriptive title** for the issue to identify the suggestion.
* **Provide a step-by-step description of the suggested enhancement** in as many details as possible.
* **Provide specific examples to demonstrate the steps**. Include copy/pasteable snippets which you use in those examples, as [Markdown code blocks](https://help.github.com/articles/markdown-basics/#multiple-lines).
* **Describe the current behavior** and **explain which behavior you expected to see instead** and why.
* **Include screenshots and animated GIFs** which help you demonstrate the steps or point out the part of Gitrob which the suggestion is related to. You can use [this tool](http://www.cockos.com/licecap/) to record GIFs on OSX and Windows, and [this tool](https://github.com/colinkeenan/silentcast) or [this tool](https://github.com/GNOME/byzanz) on Linux.
* **Explain why this enhancement would be useful** to most Gitrob users.
* **Specify which version of Gitrob you're using.** You can get the exact version by running `gitrob` in your terminal, or by looking at the Footer area of the web application.
* **Specify the name and version of the OS you're using.**

### Template For Submitting Enhancement Suggestions

    [Short description of suggestion]

    **Steps which explain the enhancement**

    1. [First Step]
    2. [Second Step]
    3. [Other Steps...]

    **Current and suggested behavior**

    [Describe current and suggested behavior here]

    **Why would the enhancement be useful to most users**

    [Explain why the enhancement would be useful to most users]

    **Screenshots and GIFs**

    ![Screenshots and GIFs which demonstrate the steps or part of Gitrob the enhancement suggestion is related to](url)

    **Gitrob Version:** [Enter Gitrob version here]
    **OS and Version:** [Enter OS name and version here]


## Pull Requests

1. Check [Issues][] to see if your contribution has already been discussed and/or implemented.
2. If not, open an issue to discuss your contribution. I won't accept all changes and do not want to waste your time.
3. Once you have the :thumbsup:, fork the repo, make your changes, and open a PR.
4. Don't forget to add your contribution and credit yourself in `CHANGELOG.md`!

## Coding Guidelines

* This project has a coding style enforced by [RuboCop][]. Use hash rockets and double-quoted strings, and otherwise try to follow the [Ruby style guide][style].
* Writing tests is strongly encouraged! This project uses RSpec.

## Getting Started

After checking out the repo, run `bin/setup` to install dependencies.

Gitrob offers the following development and testing commands:

* `bin/console` loads your working copy of Gitrob into an irb session
* `bundle exec gitrob` runs your working copy of the Gitrob executable
* `rake` executes all of Gitrob's tests and RuboCop checks

A Guardfile is also present, so if you'd like to use Guard to do a TDD workflow, then:

1. Run `bundle install --with guard` to get the optional guard dependencies
2. Run `guard` to monitor the filesystem and automatically run tests as you work

[Issues]: https://github.com/michenriksen/gitrob/issues
[RuboCop]: https://github.com/bbatsov/rubocop
[style]: https://github.com/bbatsov/ruby-style-guide
