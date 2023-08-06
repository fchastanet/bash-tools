# The commands

- [1. Build tools](#1-build-tools)
  - [1.1. bin/installRequirements](#11-bininstallrequirements)
  - [1.2. bin/waitForIt](#12-binwaitforit)
  - [1.3. bin/waitForMysql](#13-binwaitformysql)
  - [1.4. bin/doc](#14-bindoc)
  - [1.5. bin/findShebangFiles](#15-binfindshebangfiles)
  - [1.6. bin/dockerLint](#16-bindockerlint)
  - [1.7. bin/shellcheckLint](#17-binshellchecklint)
  - [1.8. bin/awkLint](#18-binawklint)
  - [1.9. bin/frameworkLint](#19-binframeworklint)
  - [1.10. bin/megalinter](#110-binmegalinter)
  - [1.11. .github/workflows/buildBinFiles](#111-githubworkflowsbuildbinfiles)
  - [1.12. bin/test](#112-bintest)
  - [1.13. bin/runBuildContainer](#113-binrunbuildcontainer)
  - [1.14. bin/buildPushDockerImages](#114-binbuildpushdockerimages)
- [2. Converter and Generator tools](#2-converter-and-generator-tools)
  - [2.1. bin/generateShellDoc](#21-bingenerateshelldoc)
  - [2.2. bin/mysql2puml](#22-binmysql2puml)
    - [2.2.1. Help](#221-help)
    - [2.2.2. Example](#222-example)
- [3. Installers](#3-installers)
  - [3.1. bin/Installers/installDockerInWsl](#31-bininstallersinstalldockerinwsl)
- [4. Git tools](#4-git-tools)
  - [4.1. bin/gitIsAncestorOf](#41-bingitisancestorof)
  - [4.2. bin/gitIsBranch](#42-bingitisbranch)
  - [4.3. bin/gitRenameBranch](#43-bingitrenamebranch)
- [5. Dev tools](#5-dev-tools)
  - [5.1. bin/cli](#51-bincli)
    - [5.1.1. Help](#511-help)
    - [5.1.2. Example 1: open bash on a container named web](#512-example-1-open-bash-on-a-container-named-web)
    - [5.1.3. Example 2: connect to mysql container with root user](#513-example-2-connect-to-mysql-container-with-root-user)
    - [5.1.4. Example 3: connect to mysql server in order to execute a query](#514-example-3-connect-to-mysql-server-in-order-to-execute-a-query)
    - [5.1.5. Example 4: pipe sql command to mysql container](#515-example-4-pipe-sql-command-to-mysql-container)
- [6. Database tools](#6-database-tools)
  - [6.1. bin/dbQueryAllDatabases](#61-bindbqueryalldatabases)
    - [6.1.1. Help](#611-help)
  - [6.2. bin/dbScriptAllDatabases](#62-bindbscriptalldatabases)
    - [6.2.1. Help](#621-help)
  - [6.3. bin/dbImport](#63-bindbimport)
    - [6.3.1. Help](#631-help)
  - [6.4. bin/dbImportProfile](#64-bindbimportprofile)
    - [6.4.1. Help](#641-help)
  - [6.5. bin/dbImportStream](#65-bindbimportstream)
  - [6.6. bin/dbQueryOneDatabase](#66-bindbqueryonedatabase)

## 1. Build tools

### 1.1. bin/installRequirements

```text
@@@installRequirements_help@@@
```

### 1.2. bin/waitForIt

```text
@@@waitForIt_help@@@
```

### 1.3. bin/waitForMysql

```text
@@@waitForMysql_help@@@
```

### 1.4. bin/doc

```text
@@@doc_help@@@
```

### 1.5. bin/findShebangFiles

imported from bash-tools-framework

```text
@@@findShebangFiles_help@@@
```

### 1.6. bin/dockerLint

imported from bash-tools-framework

```text
@@@dockerLint_help@@@
```

### 1.7. bin/shellcheckLint

imported from bash-tools-framework

```text
@@@shellcheckLint_help@@@
```

### 1.8. bin/awkLint

imported from bash-tools-framework

```text
@@@awkLint_help@@@
```

### 1.9. bin/frameworkLint

imported from bash-tools-framework

```text
@@@frameworkLint_help@@@
```

### 1.10. bin/megalinter

imported from bash-tools-framework

```text
@@@megalinter_help@@@
```

### 1.11. .github/workflows/buildBinFiles

imported from bash-tools-framework

```text
@@@buildBinFiles_help@@@
```

### 1.12. bin/test

imported from bash-tools-framework

```text
@@@test_help@@@
```

### 1.13. bin/runBuildContainer

imported from bash-tools-framework

```text
@@@runBuildContainer_help@@@
```

### 1.14. bin/buildPushDockerImages

imported from bash-tools-framework

```text
@@@buildPushDockerImages_help@@@
```

## 2. Converter and Generator tools

### 2.1. bin/generateShellDoc

imported from bash-tools-framework

```text
@@@generateShellDoc_help@@@
```

### 2.2. bin/mysql2puml

#### 2.2.1. Help

```text
@@@mysql2puml_help@@@
```

#### 2.2.2. Example

Mysql dump of some tables

```bash
mysqldump --skip-add-drop-table --skip-add-locks \
  --skip-disable-keys --skip-set-charset \
  --host=127.0.0.1 --port=3345 --user=root --password=root \
  --no-data skills \
  $(mysql --host=127.0.0.1 --port=3345 --user=root --password=root skills \
    -Bse "show tables like 'core\_%'") \
  | grep -v '^\/\*![0-9]\{5\}.*\/;$' > doc/schema.sql
```

Transform mysql dump to plant uml format

```bash
mysql2puml \
  src/_binaries/Converters/testsData/mysql2puml.dump.sql \
  -s default > src/_binaries/Converters/testsData/mysql2puml.dump.puml
```

Plantuml diagram generated

```plantuml
@@@mysql2puml_plantuml_diagram@@@
```

using plantuml software, here an example of resulting diagram

![resulting database diagram](src/_binaries/Converters/testsData/mysql2puml-model.png)

## 3. Installers

### 3.1. bin/Installers/installDockerInWsl

```text
@@@Installers_installDockerInWsl_help@@@
```

## 4. Git tools

### 4.1. bin/gitIsAncestorOf

```text
@@@gitIsAncestorOf_help@@@
```

### 4.2. bin/gitIsBranch

```text
@@@gitIsBranch_help@@@
```

### 4.3. bin/gitRenameBranch

```text
@@@gitRenameBranch_help@@@
```

## 5. Dev tools

### 5.1. bin/cli

#### 5.1.1. Help

```text
@@@cli_help@@@
```

#### 5.1.2. Example 1: open bash on a container named web

```bash
cli web
```

will actually execute this command :

```bash
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='\*'
docker exec -it -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" --user=
apache2 //bin/bash
```

#### 5.1.3. Example 2: connect to mysql container with root user

```bash
cli mysql root bash
```

will actually execute this command :

```bash
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='\*'
docker exec -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" -it --user=root
project-mysql bash
```

#### 5.1.4. Example 3: connect to mysql server in order to execute a query

will actually execute this command :

```bash
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='\*'
docker exec -it -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" --user=mysql
project-mysql //bin/bash -c 'mysql -h127.0.0.1 -uroot -proot -P3306'
```

#### 5.1.5. Example 4: pipe sql command to mysql container

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

## 6. Database tools

### 6.1. bin/dbQueryAllDatabases

Execute a query on multiple database in order to generate a report, query can be
parallelized on multiple databases

```bash
bin/dbQueryAllDatabases -e localhost-root conf/dbQueries/databaseSize.sql
```

#### 6.1.1. Help

```text
@@@dbQueryAllDatabases_help@@@
```

### 6.2. bin/dbScriptAllDatabases

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

#### 6.2.1. Help

```text
@@@dbScriptAllDatabases_help@@@
```

### 6.3. bin/dbImport

Import default source dsn/db ExampleDbName into default target dsn/db
ExampleDbName

```bash
dbImport ExampleDbName
```

Ability to import db from dump stored on aws the dump file should have this name
`<fromDbName>.tar.gz` and stored on AWS location defined by S3_BASE_URL env
variable (see src/\_binaries/DbImport/testsData/.env file)

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
dbImport --from-dsn default.remote --target-dsn default.local -p all \
  fromDb targetDB --tables tableA,tableB
```

#### 6.3.1. Help

```text
@@@dbImport_help@@@
```

### 6.4. bin/dbImportProfile

Import remote db into local db

```bash
dbImportProfile --from-dsn default.local MY_DB --ratio 45
```

Ability to generate profile that can be used in dbImport to filter out tables
bigger than given ratio (based on biggest table size). Profile is automatically
saved in ${HOME}/.bash-tools/dbImportProfiles with this format `auto*<dsn>*<db>`
**eg:** auto_default.local_MY_DB

#### 6.4.1. Help

```text
@@@dbImportProfile_help@@@
```

### 6.5. bin/dbImportStream

```text
@@@dbImportStream_help@@@
```

### 6.6. bin/dbQueryOneDatabase

```text
@@@dbQueryOneDatabase_help@@@
```
