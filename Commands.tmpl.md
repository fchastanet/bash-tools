# The commands

- [1. Build tools](#1-build-tools)
  - [1.1. bin/test](#11-bintest)
  - [1.2. bin/waitForIt](#12-binwaitforit)
  - [1.3. bin/installRequirements](#13-bininstallrequirements)
  - [1.4. bin/installDevRequirements](#14-bininstalldevrequirements)
  - [1.5. bin/runBuildContainer](#15-binrunbuildcontainer)
  - [1.6. bin/buildPushDockerImages](#16-binbuildpushdockerimages)
  - [1.7. bin/waitForIt](#17-binwaitforit)
  - [1.8. bin/waitForMysql](#18-binwaitformysql)
  - [1.9. bin/doc](#19-bindoc)
- [2. Linters](#2-linters)
  - [2.1. bin/dockerLint](#21-bindockerlint)
  - [2.2. bin/shellcheckLint](#22-binshellchecklint)
  - [2.3. bin/awkLint](#23-binawklint)
  - [2.4. bin/generateShellDoc](#24-bingenerateshelldoc)
- [3. Converter and Generator tools](#3-converter-and-generator-tools)
  - [3.1. bin/generateShellDoc](#31-bingenerateshelldoc)
  - [3.2. bin/mysql2puml](#32-binmysql2puml)
    - [3.2.1. Help](#321-help)
    - [3.2.2. Example](#322-example)
- [4. Installers](#4-installers)
  - [4.1. bin/Installers/installDockerInWsl](#41-bininstallersinstalldockerinwsl)
- [5. Git tools](#5-git-tools)
  - [5.1. bin/gitIsAncestorOf](#51-bingitisancestorof)
  - [5.2. bin/gitIsBranch](#52-bingitisbranch)
  - [5.3. bin/gitRenameBranch](#53-bingitrenamebranch)
- [6. Dev tools](#6-dev-tools)
  - [6.1. bin/cli](#61-bincli)
    - [6.1.1. Help](#611-help)
    - [6.1.2. Example 1: open bash on a container named web](#612-example-1-open-bash-on-a-container-named-web)
    - [6.1.3. Example 2: connect to mysql container with root user](#613-example-2-connect-to-mysql-container-with-root-user)
    - [6.1.4. Example 3: connect to mysql server in order to execute a query](#614-example-3-connect-to-mysql-server-in-order-to-execute-a-query)
    - [6.1.5. Example 4: pipe sql command to mysql container](#615-example-4-pipe-sql-command-to-mysql-container)
- [7. Database tools](#7-database-tools)
  - [7.1. bin/dbQueryAllDatabases](#71-bindbqueryalldatabases)
    - [7.1.1. Help](#711-help)
  - [7.2. bin/dbScriptAllDatabases](#72-bindbscriptalldatabases)
    - [7.2.1. Help](#721-help)
  - [7.3. bin/dbImport](#73-bindbimport)
    - [7.3.1. Help](#731-help)
  - [7.4. bin/dbImportProfile](#74-bindbimportprofile)
    - [7.4.1. Help](#741-help)
  - [7.5. bin/dbImportStream](#75-bindbimportstream)
  - [7.6. bin/dbQueryOneDatabase](#76-bindbqueryonedatabase)

## 1. Build tools

### 1.1. bin/test

```text
@@@test_help@@@
```

### 1.2. bin/waitForIt

```text
@@@waitForIt_help@@@
```

### 1.3. bin/installRequirements

```text
@@@installRequirements_help@@@
```

### 1.4. bin/installDevRequirements

```text
@@@installDevRequirements_help@@@
```

### 1.5. bin/runBuildContainer

```text
@@@runBuildContainer_help@@@
```

### 1.6. bin/buildPushDockerImages

```text
@@@buildPushDockerImages_help@@@
```

### 1.7. bin/waitForIt

```text
@@@waitForIt_help@@@
```

### 1.8. bin/waitForMysql

```text
@@@waitForMysql_help@@@
```

### 1.9. bin/doc

```text
@@@doc_help@@@
```

## 2. Linters

### 2.1. bin/dockerLint

```text
@@@dockerLint_help@@@
```

### 2.2. bin/shellcheckLint

```text
@@@shellcheckLint_help@@@
```

### 2.3. bin/awkLint

```text
@@@awkLint_help@@@
```

### 2.4. bin/generateShellDoc

```text
@@@generateShellDoc_help@@@
```

## 3. Converter and Generator tools

### 3.1. bin/generateShellDoc

```text
@@@generateShellDoc_help@@@
```

### 3.2. bin/mysql2puml

#### 3.2.1. Help

```text
@@@mysql2puml_help@@@
```

#### 3.2.2. Example

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

```text
@@@Installers_installDockerInWsl_help@@@
```

## 5. Git tools

### 5.1. bin/gitIsAncestorOf

```text
@@@gitIsAncestorOf_help@@@
```

### 5.2. bin/gitIsBranch

```text
@@@gitIsBranch_help@@@
```

### 5.3. bin/gitRenameBranch

```text
@@@gitRenameBranch_help@@@
```

## 6. Dev tools

### 6.1. bin/cli

#### 6.1.1. Help

```text
@@@cli_help@@@
```

#### 6.1.2. Example 1: open bash on a container named web

```bash
cli web
```

will actually execute this command :

```bash
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='\*'
docker exec -it -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" --user=
apache2 //bin/bash
```

#### 6.1.3. Example 2: connect to mysql container with root user

```bash
cli mysql root bash
```

will actually execute this command :

```bash
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='\*'
docker exec -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" -it --user=root
project-mysql bash
```

#### 6.1.4. Example 3: connect to mysql server in order to execute a query

will actually execute this command :

```bash
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='\*'
docker exec -it -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" --user=mysql
project-mysql //bin/bash -c 'mysql -h127.0.0.1 -uroot -proot -P3306'
```

#### 6.1.5. Example 4: pipe sql command to mysql container

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

#### 7.1.1. Help

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

#### 7.2.1. Help

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
dbImport --from-dsn default.remote --target-dsn default.local -p all \
  fromDb targetDB --tables tableA,tableB
```

#### 7.3.1. Help

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

#### 7.4.1. Help

```text
@@@dbImportProfile_help@@@
```

### 7.5. bin/dbImportStream

```text
@@@dbImportStream_help@@@
```

### 7.6. bin/dbQueryOneDatabase

```text
@@@dbQueryOneDatabase_help@@@
```
