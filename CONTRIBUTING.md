# How to contribute

Third-party patches are essential for extending solaris_providers. We simply
can't match the complexity of all the possible configurations and uses of
Solaris. We want to keep it as easy as possible to contribute changes that
get things working in your environment. There are a few guidelines that we
need contributors to follow so that we can have a chance of keeping on
top of things.

## Solaris 10 vs Solaris 11

This module is targeted at Solaris 11.4. Changes may be accepted
for earlier Solaris releases as long as proper constraints are present.

## Getting Started

* Fork the repository on GitHub

## Making Changes

* Create a topic branch from where you want to base your work.
  * This is usually the master branch.
  * Use the default branch. Currently 1.2.x
  * Only target release branches if you are certain your fix must be on that
    branch.
  * To quickly create a topic branch based on master; `git checkout -b
    fix/master/my_contribution master`. Please avoid working directly on the
    `master` branch.
* Make commits of logical units.
* Check for unnecessary whitespace with `git diff --check` before committing.
* Make sure your commit messages are in the proper format.

````
    (ISSUE) brief summary
    OR
    <Oracle Bug Number> brief summary

    Without this patch applied the example commit message in the CONTRIBUTING
    document is not a concrete example.  This is a problem because the
    contributor is left to imagine what the commit message should look like
    based on a description rather than an example.  This patch fixes the
    problem by making the example concrete and imperative.

    The first line is a real life imperative statement with a ticket number
    from our issue tracker or an Oracle bug number.  The body describes the
    behavior without the patch, why this is a problem, and how the patch fixes
    the problem when applied.
````

* Make sure you have added the necessary tests for your changes.
  * See: [Testing](TESTING.md)
* Run _all_ the tests to assure nothing else was accidentally broken.
* Pull requests will not be accepted if they fail test evaluation in
  [Travis-CI](https://travis-ci.org/)
  * Travis configuration is included in the repository.
  * Enable travis to get automatic testing on your own commits.

## Making Trivial Changes

### Documentation

For changes of a trivial nature to comments and documentation, it is not
always necessary to create a new ticket in Jira. In this case, it is
appropriate to start the first line of a commit with '(doc)' instead of
a ticket number.

````
    (doc) Add documentation commit example to CONTRIBUTING

    There is no example for contributing a documentation commit
    to the puppet-solaris_providers repository. This is a problem because
    the contributor is left to assume how a commit of this nature may appear.

    The first line is a real life imperative statement with '(doc)' in
    place of what would have been the ticket number in a
    non-documentation related commit. The body describes the nature of
    the new documentation or comments added.
````

## Submitting Changes

* Sign the [The Oracle Contributor Agreement](https://oca.opensource.oracle.com)
  (OCA).

  * For pull requests to be accepted into the repo, the bottom of
  your commit message must have the following line using your name and
  e-mail address as it appears in the OCA Signatories list.

  ```
  Signed-off-by: Your Name <you@example.org>
  ```

  This can be automatically added to pull requests by committing with:

  ```
  git commit --signoff
  ````
  * Only pull requests from committers that can be verified as having
signed the OCA can be accepted.

* Push your changes to a topic branch in your fork of the repository.
* Submit a pull request to the repository in the oracle organization.
* The Configuration Management Team will review the pull request.
* After feedback has been given we expect responses within two weeks. After two
  weeks we may close the pull request if it isn't showing any activity.

# Additional Resources

* [General GitHub documentation](https://help.github.com/)
* [GitHub pull request documentation](https://help.github.com/send-pull-requests/)
* [solaris_providers Testing](docs/TESTING.md)

This page mostly taken from the Puppet contributing page.
