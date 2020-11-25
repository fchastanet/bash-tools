# bash-tools

Build status: [![Build Status](https://travis-ci.com/fchastanet/bash-tools.svg?branch=master)](https://travis-ci.com/fchastanet/bash-tools)

- [1. Exerpt](#1-exerpt)
- [2. Installation/Configuration](#2-installationconfiguration)
- [3. The tools](#3-the-tools)
  - [3.1. bin/dbQueryAllDatabases](#31-bindbqueryalldatabases)
  - [3.2. bin/dbImport](#32-bindbimport)
  - [3.3. bin/dbImportTable](#33-bindbimporttable)
  - [3.4. bin/cli](#34-bincli)
- [4. Bash Framework](#4-bash-framework)
- [5. Acknowledgements](#5-acknowledgements)

## 1. Exerpt

This is a collection of several bash tools using a bash framework allowing to easily import bash script, log, display log messages, database manipulation, user interation, version comparison, ...

List of tools:
* **cli** : easy connection to docker container
* **dbImport** : Import db from aws dump or remote db into local db
* **dbImportTable** : Import remote db table into local db
* **dbQueryAllDatabases** : Execute a query on multiple database in order to generate a report, query can be parallelized on multiple databases
* **dbScriptAllDatabases** : same as dbQueryAllDatabases but you can execute an arbitrary script on each database
* **gitIsAncestor** : show an error if commit is not an ancestor of branch
* **gitIsBranch** : show an error if branchName is not a known branch
* **waitforIt** : useful in docker container to know if another container port is accessible
* **waitForMysql** : useful in docker container to know if mysql server is ready to receive queries

## 2. Installation/Configuration

clone this repository and create configuration files in your home directory
alternatively you can use the **install.sh** script
```bash
git clone git@github.com:fchastanet/bash-tools.git
cd bash-tools
mkdir -p ~/.bash-tools && cp -R conf/. ~/.bash-tools
sed -i -e "s@^BASH_TOOLS_FOLDER=.*@BASH_TOOLS_FOLDER=$(pwd)@g" ~/.bash-tools/.env
```

The following structure will be created in your home directory
<pre>
~/.bash-tools/
├── cliProfile
│   ├── default.sh
├── dbCheckStructs
├── dbImportDumps
├── dbImportProfiles
│   ├── sample.sh
├── dbQueries
│   └── sample.sql
└── .env
</pre>

Some tools need [GNU parallel software](https://www.gnu.org/software/parallel/), it allows running multiple processes in parallel. You can install it running
```bash
sudo apt update
sudo apt install -y parallel
# remove parallel nagware
mkdir ~/.parallel
touch ~/.parallel/will-cite
```

## 3. The tools

### 3.1. bin/dbQueryAllDatabases

Execute a query on multiple database in order to generate a report, query can be parallelized on multiple databases
```bash
bin/dbQueryAllDatabases -e conf/dsn/localhost-root.env conf/dbQueries/databaseSize.sql
```

**Help**
```
Description: Execute a query on multiple database in order to generate a report, query can be parallelized on multiple databases

Usage: dbQueryAllDatabases [-h|--help]
Usage: dbQueryAllDatabases <query|queryFile> [--env-file|-e <envfile>] [-t|--as-tsv] [-q|--query] [--jobs|-j <numberOfJobs>] [--bar|-b]
    --help,-h prints this help and exits
    --as-tsv,-t show results as tsv file (separated by tabulations)
    --query,-q implies <query> parameter is a mysql query string
    -r|--remote checks remote db, local db otherwise
    --jobs,-j <numberOfJobs> specify the number of db to query in parallel (this needs the use of gnu parallel)
    --bar,-b Show progress as a progress bar. In the bar is shown: % of jobs completed, estimated seconds left, and number of jobs started.
    <query|queryFile>
        if -q option is provided this parameter is a mysql query string
        else a file must be specified
    --env-file,-e <envfile> load <envfile>, this file must contains these variables in order to connect to the mysql server
MYSQL_HOSTNAME=""
MYSQL_USER=""
MYSQL_PASSWORD=""
MYSQL_PORT=""
REMOTE_MYSQL_HOSTNAME=""
REMOTE_MYSQL_PORT=""
REMOTE_MYSQL_USER=""
REMOTE_MYSQL_PASSWORD=""

    local DB connection  : root:hidden@127.0.0.1:3306
    remote DB connection : root:hidden@127.0.0.1:3306
```

### 3.2. bin/dbImport
Import remote db into local db
```bash
dbImport ExampleDbName
```

**Help**
```
Description: Import remote db into local db

Command: dbImport --help prints this help and exits
Command: dbImport <remoteDbName> [<localDbName>] [-f|--force] 
                        [-d|--download-dump] [-a|--from-aws]
                        [-s|--skip-schema] [-p|--profile profileName] 
                        [-o|--collation-name utf8_general_ci] [-c|--character-set utf8]

    <localDbName> : use remote db name if not provided
    -f|--force If local db exists, it will overwrite it
    -d|--download-dump force remote db dump (default: use already downloaded dump in /home/vagrant/.bash-tools/dbImportDumps if available)
    -a|--from-aws db dump will be downloaded from s3 instead of using remote db, 
        remoteDBName will represent the name of the file
        profile will be calculated against the dump itself
    -s|--skip-schema avoid to import the schema
    -o|--collation-name change the collation name used during database creation (default value: collation name used by remote db)
    -c|--character-set change the character set used during database creation (default value: character set used by remote db)
    -p|--profile profileName the name of the profile to use in order to include or exclude tables
        (if not specified /home/vagrant/.bash-tools/dbImportProfiles/default.sh  is used if exists otherwise /home/vagrant/projects/bash-tools/conf/dbImportProfiles/default.sh)
        list of available home profiles (/home/vagrant/.bash-tools/dbImportProfiles): ing, precomputeLearnerTimezone, all, none, sample, default
        list of available profiles : all, none, default

    local DB connection   : root:Hidden@127.0.0.1:3306
    remote DB connection  : root:Hidden@127.0.0.1:3306
    Aws s3 location       : s3://example/exports/
```

### 3.3. bin/dbImportTable
Import remote db table into local db
```bash
dbImportTable ExampleDbName ExampleTableName
```

**Help**
```
Description: Import remote db table into local db

Command: dbImportTable [--help] prints this help and exits
Command: dbImportTable <remoteDbName> <tableName> [<localDbName>] 
    [-d|--download-dump] [-f|--force] [-a|--from-aws]
    [-o|--collation-name utf8_general_ci] [-c|--character-set utf8]

    download the remote table data and install data in local database (the schema should exists)

    <tableName>   : table name to import
    <localDbName> : use remote db name if not provided
    -f|--force If local table exists, it will overwrite it
    -a|--from-aws db dump will be downloaded from s3 instead of using remote db, 
        remoteDBName will represent the name of the file
        profile will be calculated against the dump itself
    -d|--download-dump force remote db dump (default: use already downloaded dump in /home/vagrant/.bash-tools/dbImportDumps if available)
    -o|--collation-name change the collation name used during database creation (default value: collation name used by remote db)
    -c|--character-set change the character set used during database creation (default value: character set used by remote db)

    local DB connection  : root:Hidden@127.0.0.1:3306
    remote DB connection : root:Hidden@127.0.0.1:3306
    Aws s3 location       : s3://example/exports/
```

### 3.4. bin/cli

easy connection to docker container

**Example 1: open bash on a container named web**
```bash
cli web
```
will actually execute this command : MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' docker exec -it -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" --user= apache2 //bin/bash

**Example 2: connect to mysql container with root user**
```bash
cli mysql root bash
```
will actually execute this command : MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' docker exec -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" -it --user=root ckls-mysql bash

**Example 3: connect to mysql server in order to execute a query**

will actually execute this command : MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' docker exec -it -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" --user=mysql ckls-mysql //bin/bash -c 'mysql -h127.0.0.1 -uroot -proot -P3306'

**Example 4: pipe sql command to mysql container** 
```bash
echo 'SELECT table_schema AS "Database",ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS "Size (MB)" FROM information_schema.TABLES' | bin/cli mysql
```
will actually execute this command : MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' docker exec -i -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" --user=mysql ckls-mysql //bin/bash -c 'mysql -h127.0.0.1 -uroot -proot -P3306'
notice that as input is given to the command, tty option is not provided to docker exec

**Help**
```
    Description: easy connection to docker container

    Command: cli [-h|--help] prints this help and exits
    Command: cli <container> [user] [command]

    <container> : container should be one of these values : apache2,mysql8,mailhog,redis,proxysql

    examples:
    to connect to mysql container in bash mode with user mysql
        cli mysql mysql "//bin/bash"
    to connect to web container with user root
        cli web root

    these mappings are provided by default using /home/vagrant/projects/bash-tools/cliProfile/default.sh
    you can override these mappings by providing your own profile in /home/vagrant/.bash-tools/cliProfile/default.sh

    This script will be executed with the variables userArg containerArg commandArg set as specified in command line
    and should provide value for the following variables finalUserArg finalContainerArg finalCommandArg
```

## 4. Bash Framework

All these tools are based on *Bash framework* with the following features:
 * A boostrap that allows to import automatically .env file in home folder or ~/.bash-tools folder in order to load some environment variables
 * **import alias** allows to import (only once) a bash file found in following folders (in order)
    * vendor/bash-framework
    * vendor
    * calling script path
    * absolute path 
  * **source alias**, same as import but multiple times import allowed
  * Framework
    * **Framework::expectUser** exits with message if current user is not the expected one
    * **Framework::expectNonRootUser** exits with message if current user is root
  * Database
    * **Database::dump** dump db limited to optional table list
    * **Database::query** mysql query on a given db
    * **Database::dropTable** drop table if exists
    * **Database::dropDb** drop database if exists
    * **Database::createDb** create database if not already existing
    * **Database::isTableExists** check if table exists on given db
    * **Database::ifDbExists** check if given database exists
    * all these methods need to call **Database::newInstance** in order to reference target db connection
  * Array
    * **Array::contains** check if an element is contained in an array
  * Functions
    * **Functions::checkCommandExists** check if command specified exists or exits with error message if not
    * **Functions::isWindows** determine if the script is executed under windows (git bash, wsl)
    * **Functions::quote** quote a string replace ' with \'
  * UI
    * **UI::askToContinue** ask the user if he wishes to continue a process
    * **UI::askYesNo** ask the user a confirmation
    * **UI::askToIgnoreOverwriteAbort** ask the user to ignore(i), overwrite(o) or abort(a)
  * Version
    * **Version::checkMinimal** ensure that command exists with expected version
    * **Version::compare** compares two versions
  * Log::display* output colored message on error output and log the message 
    * **Log::displayError** error message in red
    * **Log::displayWarning** warning message  in yellow
    * **Log::displayInfo** info message in white on lightBlue
    * **Log::displaySuccess** success message in green
    * **Log::displayDebug** debug message in grey
  * Log::log* output message in a log file
    * **Log::logError**
    * **Log::logWarning**
    * **Log::logInfo**
    * **Log::logSuccess**
    * **Log::logDebug**


**Usage:** simply add these lines to your script
```bash
#!/usr/bin/env bash

# load bash-framework
# shellcheck source=bash-framework/_bootstrap.sh
CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$( cd "${CURRENT_DIR}/.." && pwd )/bash-framework/_bootstrap.sh"

# bash framework is loaded, .env has been loaded (default .env file present in bash-framework is loaded if none exists yet) 

# exits with message if this script is executed using root user
Framework::expectNonRootUser

# import some useful apis
import bash-framework/Database
import bash-framework/Array
```

[see the auto generated bash doc](doc/Index.md) generated by running
```bash
./doc.sh
```

All the methods of this framework are unit tested, you can run the unit tests using the following command
```bash
./test.sh
```

## 5. Acknowledgements
Like so many projects, this effort has roots in many places. 

I would like to thank particularly  Bazyli Brzóska for his work on the project [Bash Infinity](https://github.com/niieani/bash-oo-framework).
Framework part of this project is largely inspired by his work(some parts copied). You can see his [blog](https://invent.life/project/bash-infinity-framework) too that is really interesting 
