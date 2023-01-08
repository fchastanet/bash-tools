# bash-tools

<!-- remove -->

> **_NOTE:_** **Documentation is best viewed on
> [github-pages](https://fchastanet.github.io/bash-tools/)**

<!-- endRemove -->

> **_TIP:_** Checkout related projects of this suite
>
> - [Bash Tools Framework](https://fchastanet.github.io/bash-tools-framework/)
> - **[Bash Tools](https://fchastanet.github.io/bash-tools/)**
> - [Bash Dev Env](https://fchastanet.github.io/bash-dev-env/)

<!-- prettier-ignore-start -->
<!-- markdownlint-capture -->
<!-- markdownlint-disable -->
[![GitHubLicense](
  https://img.shields.io/github/license/Naereen/StrapDown.js.svg
)](
  https://github.com/fchastanet/bash-tools/blob/master/LICENSE
)
[![CI/CD](
  https://github.com/fchastanet/bash-tools/actions/workflows/lint-test.yml/badge.svg
)](
  https://github.com/fchastanet/bash-tools/actions?query=workflow%3A%22Lint+and+test%22+branch%3Amaster
)
[![ProjectStatus](
  http://opensource.box.com/badges/active.svg
)](
  http://opensource.box.com/badges
  'Project Status'
)
[![DeepSource](
  https://deepsource.io/gh/fchastanet/bash-tools.svg/?label=active+issues&show_trend=true
)](
  https://deepsource.io/gh/fchastanet/bash-tools/?ref=repository-badge
)
[![DeepSource](
  https://deepsource.io/gh/fchastanet/bash-tools.svg/?label=resolved+issues&show_trend=true
)](
  https://deepsource.io/gh/fchastanet/bash-tools/?ref=repository-badge
)
[![AverageTimeToResolveAnIssue](
  http://isitmaintained.com/badge/resolution/fchastanet/bash-tools.svg
)](
  http://isitmaintained.com/project/fchastanet/bash-tools
  'Average time to resolve an issue'
)
[![PercentageOfIssuesStillOpen](
  http://isitmaintained.com/badge/open/fchastanet/bash-tools.svg
)](
  http://isitmaintained.com/project/fchastanet/bash-tools
  'Percentage of issues still open'
)
<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

- [1. Excerpt](#1-excerpt)
- [2. Installation/Configuration](#2-installationconfiguration)
- [3. Development Environment](#3-development-environment)
  - [3.1. build dependencies](#31-build-dependencies)
  - [3.2. UT](#32-ut)
  - [3.3. auto generated bash doc](#33-auto-generated-bash-doc)
  - [3.4. github page](#34-github-page)
- [4. Acknowledgements](#4-acknowledgements)

## 1. Excerpt

This is a collection of several bash tools using
[bash tools framework](https://fchastanet.github.io/bash-tools-framework/)
allowing to easily import bash script, log, display log messages, database
manipulation, user interaction, version comparison, ...

List of tools:

- **gitRenameBranch** : easy rename git local branch, use options to push new
  branch and delete old branch
- **cli** : easy connection to docker container
- **dbImport** : Import db from aws dump or mysql into target db
- **dbImportTable** : Import remote db table from aws or mysql into target db
- **dbQueryAllDatabases** : Execute a query on multiple database in order to
  generate a report, query can be parallelized on multiple databases
- **dbScriptAllDatabases** : same as dbQueryAllDatabases but you can execute an
  arbitrary script on each database
- **gitIsAncestor** : show an error if commit is not an ancestor of branch
- **gitIsBranch** : show an error if branchName is not a known branch
- **gitRenameBranch** : rename git local branch, use options to push new branch
  and delete old branch
- **waitForIt** : useful in docker container to know if another container port
  is accessible
- **waitForMysql** : useful in docker container to know if mysql server is ready
  to receive queries
- ...

## 2. Installation/Configuration

clone this repository and create configuration files in your home directory
alternatively you can use the **install** script

```bash
git clone git@github.com:fchastanet/bash-tools.git
cd bash-tools
./install
```

The following structure will be created in your home directory

```text
~/.bash-tools/
├── cliProfiles
│   ├── default.sh
│   ├── mysql.remote.sh
│   ├── mysql.sh
├── dbImportDumps
├── dbImportProfiles
│   ├── all.sh
│   ├── default.sh
│   ├── none.sh
├── dbQueries
│   └── databaseSize.sql
├── dsn
│   └── default.local.env
│   └── default.remote.env
│   └── localhost-root.env
└── .env
```

Some tools need [GNU parallel software](https://www.gnu.org/software/parallel/),
it allows running multiple processes in parallel. You can install it running

```bash
sudo apt update
sudo apt install -y parallel
# remove parallel nagware
mkdir ~/.parallel
touch ~/.parallel/will-cite
```

## 3. Development Environment

### 3.1. build dependencies

Dependencies are automatically installed when used.

`bin/test` script will install the following libraries inside `vendor` folder:

- [bats-core/bats-core](https://github.com/bats-core/bats-core.git)
- [bats-core/bats-support](https://github.com/bats-core/bats-support.git)
- [bats-core/bats-assert](https://github.com/bats-core/bats-assert.git)
- [Flamefire/bats-mock](https://github.com/Flamefire/bats-mock.git)

`./bin/doc` script will install:

- [fchastanet/tomdoc.sh](https://github.com/fchastanet/tomdoc.sh.git)

To avoid checking for libraries update and have an impact on performance, a file
is created in vendor dir.

- `vendor/.tomdocInstalled`
- `vendor/.batsInstalled` You can remove these files to force the update of the
  libraries, or just wait 24 hours that the timeout expires.

### 3.2. UT

All the commands are unit tested, you can run the unit tests using the following
command

```bash
./bin/test -r tests
```

Launch UT on different environments:

```bash
VENDOR="alpine" BASH_TAR_VERSION=4.4 BASH_IMAGE=bash \
  SKIP_BUILD=1 SKIP_USER=1 ./bin/test -r src -j 16
VENDOR="alpine" BASH_TAR_VERSION=5.0 BASH_IMAGE=bash \
  SKIP_BUILD=1 SKIP_USER=1 ./bin/test -r src -j 16
VENDOR="alpine" BASH_TAR_VERSION=5.1 BASH_IMAGE=bash \
  SKIP_BUILD=1 SKIP_USER=1 ./bin/test -r src -j 16

VENDOR="ubuntu" BASH_TAR_VERSION=4.4 BASH_IMAGE=ubuntu:20.04 \
  SKIP_BUILD=1 SKIP_USER=1 ./bin/test -r src -j 2
VENDOR="ubuntu" BASH_TAR_VERSION=5.0 BASH_IMAGE=ubuntu:20.04 \
  SKIP_BUILD=1 SKIP_USER=1 ./bin/test -r src -j 2
VENDOR="ubuntu" BASH_TAR_VERSION=5.1 BASH_IMAGE=ubuntu:20.04 \
  SKIP_BUILD=1 SKIP_USER=1 ./bin/test -r src -j 2
```

### 3.3. auto generated bash doc

generated by running

```bash
./bin/doc
```

### 3.4. github page

The web page uses [Docsify](https://docsify.js.org/) to generate a static web
site.

It is recommended to install docsify-cli globally, which helps initializing and
previewing the website locally.

`npm i docsify-cli -g`

Run the local server with docsify serve.

`docsify serve pages`

Navigate to <http://localhost:3000/>

## 4. Acknowledgements

Like so many projects, this effort has roots in many places.

I would like to thank particularly Bazyli Brzóska for his work on the project
[Bash Infinity](https://github.com/niieani/bash-oo-framework). Framework part of
this project is largely inspired by his work(some parts copied). You can see his
[blog](https://invent.life/project/bash-infinity-framework) too that is really
interesting
