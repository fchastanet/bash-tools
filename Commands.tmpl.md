---
title: 'The commands'
permalink: /commands
---

# The commands

- [1. Build tools](#1-build-tools)
  - [1.1. bin/test](#11-bintest)
  - [1.2. bin/waitForIt](#12-binwaitforit)
  - [1.3. bin/publishDeepsourceArtifact](#13-binpublishdeepsourceartifact)
  - [1.4. bin/installRequirements](#14-bininstallrequirements)
  - [1.5. bin/installDevRequirements](#15-bininstalldevrequirements)
  - [1.6. bin/runBuildContainer](#16-binrunbuildcontainer)
  - [1.7. bin/buildPushDockerImages](#17-binbuildpushdockerimages)
  - [1.8. bin/waitForIt](#18-binwaitforit)
  - [1.9. bin/waitForMysql](#19-binwaitformysql)
- [2. Linters](#2-linters)
  - [2.1. bin/dockerLint](#21-bindockerlint)
  - [2.2. bin/shellcheckLint](#22-binshellchecklint)
  - [2.3. bin/awkLint](#23-binawklint)
  - [2.4. bin/generateShellDoc](#24-bingenerateshelldoc)
- [3. Converter and Generator tools](#3-converter-and-generator-tools)
  - [3.1. bin/generateShellDoc](#31-bingenerateshelldoc)
  - [3.2. bin/mysql2puml](#32-binmysql2puml)
- [4. Installers](#4-installers)
  - [4.1. bin/Installers/installDockerInWsl](#41-bininstallersinstalldockerinwsl)
- [5. Git tools](#5-git-tools)
  - [5.1. bin/gitIsAncestorOf](#51-bingitisancestorof)
  - [5.2. bin/gitIsBranch](#52-bingitisbranch)
  - [5.3. bin/gitRenameBranch](#53-bingitrenamebranch)
- [6. Dev tools](#6-dev-tools)
  - [6.1. bin/cli](#61-bincli)
- [7. Database tools](#7-database-tools)
  - [7.1. bin/dbQueryAllDatabases](#71-bindbqueryalldatabases)
  - [7.2. bin/dbScriptAllDatabases](#72-bindbscriptalldatabases)
  - [7.3. bin/dbImport](#73-bindbimport)
  - [7.4. bin/dbImportProfile](#74-bindbimportprofile)
  - [7.5. bin/dbImportStream](#75-bindbimportstream)

## 1. Build tools

### 1.1. bin/test

**Help**

```text
@@@test_help@@@
```

### 1.2. bin/waitForIt

**Help**

```text
@@@waitForIt_help@@@
```

### 1.3. bin/publishDeepsourceArtifact

**Help**

```text
@@@publishDeepsourceArtifact_help@@@
```

### 1.4. bin/installRequirements

**Help**

```text
@@@installRequirements_help@@@
```

### 1.5. bin/installDevRequirements

**Help**

```text
@@@installDevRequirements_help@@@
```

### 1.6. bin/runBuildContainer

**Help**

```text
@@@runBuildContainer_help@@@
```

### 1.7. bin/buildPushDockerImages

**Help**

```text
@@@buildPushDockerImages_help@@@
```

### 1.8. bin/waitForIt

**Help**

```text
@@@waitForIt_help@@@
```

### 1.9. bin/waitForMysql

**Help**

```text
@@@waitForMysql_help@@@
```

## 2. Linters

### 2.1. bin/dockerLint

**Help**

```text
@@@dockerLint_help@@@
```

### 2.2. bin/shellcheckLint

**Help**

```text
@@@shellcheckLint_help@@@
```

### 2.3. bin/awkLint

**Help**

```text
@@@awkLint_help@@@
```

### 2.4. bin/generateShellDoc

**Help**

```text
@@@generateShellDoc_help@@@
```

## 3. Converter and Generator tools

### 3.1. bin/generateShellDoc

**Help**

```text
@@@generateShellDoc_help@@@
```

### 3.2. bin/mysql2puml

**Help**

```text
@@@mysql2puml_help@@@
```

Mysql dump of some tables

```bash
mysqldump --skip-add-drop-table --skip-add-locks --skip-disable-keys --skip-set-charset \
  --host=127.0.0.1 --port=3345 --user=root --password=root --no-data skills \
  $(mysql --host=127.0.0.1 --port=3345 --user=root --password=root skills \
    -Bse "show tables like 'core\_%'") \
  | grep -v '^\/\*![0-9]\{5\}.*\/;$' > doc/schema.sql
```

Transform mysql dump to plant uml format

```bash
mysql2puml tests/tools/data/mysql2puml.dump.sql -s default > tests/tools/data/mysql2puml.puml
```

Plantuml diagram generated

```plantuml
@@@mysql2puml_plantuml_diagram@@@
```

using plantuml software, here an example of resulting diagram

![resulting database diagram](tests/data/mysql2puml-model.png)

## 4. Installers

### 4.1. bin/Installers/installDockerInWsl

**Help**

```text
@@@Installers_installDockerInWsl_help@@@
```

## 5. Git tools

### 5.1. bin/gitIsAncestorOf

**Help**

```text
@@@gitIsAncestorOf_help@@@
```

### 5.2. bin/gitIsBranch

**Help**

```text
@@@gitIsBranch_help@@@
```

### 5.3. bin/gitRenameBranch

**Help**

```text
@@@gitRenameBranch_help@@@
```

## 6. Dev tools

### 6.1. bin/cli

**Help**

```text
@@@cli_help@@@
```

easy connection to docker container

**Example 1: open bash on a container named web**

```bash
cli web
```

will actually execute this command :

```bash
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='\*'
docker exec -it -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" --user=
apache2 //bin/bash
```

**Example 2: connect to mysql container with root user**

```bash
cli mysql root bash
```

will actually execute this command :

```bash
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='\*'
docker exec -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" -it --user=root
project-mysql bash
```

**Example 3: connect to mysql server in order to execute a query**

will actually execute this command :

```bash
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='\*'
docker exec -it -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" --user=mysql
project-mysql //bin/bash -c 'mysql -h127.0.0.1 -uroot -proot -P3306'
```

**Example 4: pipe sql command to mysql container**

```bash
echo 'SELECT
  table_schema AS "Database",
  ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS "Size (MB)"
FROM information_schema.TABLES' | bin/cli mysql
```

will actually execute this command :

```bash
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='\*'
docker exec -i -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" --user=mysql
project-mysql //bin/bash -c 'mysql -h127.0.0.1 -uroot -proot -P3306'
```

notice that as input is given to the command, tty option is not provided to
docker exec

## 7. Database tools

### 7.1. bin/dbQueryAllDatabases

Execute a query on multiple database in order to generate a report, query can be
parallelized on multiple databases

```bash
bin/dbQueryAllDatabases -e localhost-root conf/dbQueries/databaseSize.sql
```

**Help**

```text
@@@dbQueryAllDatabases_help@@@
```

### 7.2. bin/dbScriptAllDatabases

Allow to execute a script on each database of specified mysql server

```bash
bin/dbScriptAllDatabases -d localhost-root dbCheckStructOneDatabase
```

or specified db only

```bash
bin/dbScriptAllDatabases -d localhost-root dbCheckStructOneDatabase db
```

launch script in parallel on multiple db at once

```bash
bin/dbScriptAllDatabases --jobs 10 -d localhost-root dbCheckStructOneDatabase
```

**Help:**

```text
@@@dbScriptAllDatabases_help@@@
```

### 7.3. bin/dbImport

Import default source dsn/db ExampleDbName into default target dsn/db
ExampleDbName

```bash
dbImport ExampleDbName
```

Ability to import db from dump stored on aws the dump file should have this name
`<fromDbName>.tar.gz` and stored on AWS location defined by S3_BASE_URL env
variable (see tests/data/.env file)

```bash
dbImport --from-aws ExampleDbName.tar.gz
```

It allows also to dump from source database and import it into target database.
Providing --profile option **dumps** only the tables selected. Providing
--tables option **imports** only the tables selected.

The following command will dump full structure and data of fromDb but will
insert only the data from tableA and tableB, full structure will be inserted
too. Second call to this command skip the dump as dump has been saved the first
time. Note that table A and table B are truncated on target database before
being imported.

```bash
dbImport --from-dsn default.remote --target-dsn default.local -p all fromDb targetDB --tables tableA,tableB
```

**Help**

```text
@@@dbImport_help@@@
```

### 7.4. bin/dbImportProfile

Import remote db into local db

```bash
dbImportProfile --from-dsn default.local MY_DB --ratio 45
```

Ability to generate profile that can be used in dbImport to filter out tables
bigger than given ratio (based on biggest table size). Profile is automatically
saved in ${HOME}/.bash-tools/dbImportProfiles with this format `auto*<dsn>*<db>`
**eg:** auto_default.local_MY_DB

**Help**

```text
@@@dbImportProfile_help@@@
```

### 7.5. bin/dbImportStream

**Help**

```text
@@@dbImportStream_help@@@
```
