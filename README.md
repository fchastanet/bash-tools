# 1. bash-tools

Build status: [![Build Status](https://travis-ci.com/fchastanet/bash-tools.svg?branch=master)](https://travis-ci.com/fchastanet/bash-tools)
[![Project Status](http://opensource.box.com/badges/active.svg)](http://opensource.box.com/badges)
[![DeepSource](https://deepsource.io/gh/fchastanet/bash-tools.svg/?label=active+issues&show_trend=true)](https://deepsource.io/gh/fchastanet/bash-tools/?ref=repository-badge)
[![DeepSource](https://deepsource.io/gh/fchastanet/bash-tools.svg/?label=resolved+issues&show_trend=true)](https://deepsource.io/gh/fchastanet/bash-tools/?ref=repository-badge)
[![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/fchastanet/bash-tools.svg)](http://isitmaintained.com/project/fchastanet/bash-tools "Average time to resolve an issue")
[![Percentage of issues still open](http://isitmaintained.com/badge/open/fchastanet/bash-tools.svg)](http://isitmaintained.com/project/fchastanet/bash-tools "Percentage of issues still open")

- [1. bash-tools](#1-bash-tools)
  - [1.1. Exerpt](#11-exerpt)
  - [1.2. Installation/Configuration](#12-installationconfiguration)
  - [1.3. The tools](#13-the-tools)
    - [1.3.1. bin/gitRenameBranch](#131-bingitrenamebranch)
    - [1.3.2. bin/dbQueryAllDatabases](#132-bindbqueryalldatabases)
    - [bin/dbScriptAllDatabases](#bindbscriptalldatabases)
    - [1.3.3. bin/dbImport](#133-bindbimport)
    - [1.3.4. bin/dbImportTable](#134-bindbimporttable)
    - [1.3.5. bin/cli](#135-bincli)
  - [1.4. Bash Framework](#14-bash-framework)
  - [1.5. Acknowledgements](#15-acknowledgements)

## 1.1. Exerpt

This is a collection of several bash tools using a bash framework allowing to easily import bash script, log, display log messages, database manipulation, user interation, version comparison, ...

List of tools:
* **gitRenameBranch** : easy rename git local branch, use options to push new branch and delete old branch
* **cli** : easy connection to docker container
* **dbImport** : Import db from aws dump or remote db into local db
* **dbImportTable** : Import remote db table into local db
* **dbQueryAllDatabases** : Execute a query on multiple database in order to generate a report, query can be parallelized on multiple databases
* **dbScriptAllDatabases** : same as dbQueryAllDatabases but you can execute an arbitrary script on each database
* **gitIsAncestor** : show an error if commit is not an ancestor of branch
* **gitIsBranch** : show an error if branchName is not a known branch
* **waitforIt** : useful in docker container to know if another container port is accessible
* **waitForMysql** : useful in docker container to know if mysql server is ready to receive queries

## 1.2. Installation/Configuration

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

## 1.3. The tools

### 1.3.1. bin/gitRenameBranch

```
Description: rename git local branch, use options to push new branch and delete old branch

Usage: gitRenameBranch [-h|--help] prints this help and exits
Usage: gitRenameBranch <newBranchName> [<oldBranchName>] [--push|-p] [--delete|-d] [--assume-yes|-yes|-y]
    --help,-h prints this help and exits
     -y, --yes, --assume-yes do not ask for confirmation (use with caution)
        Automatic yes to prompts; assume "y" as answer to all prompts
        and run non-interactively. 
    --push,-p push new branch
    --delete,-d delete old remote branch
    <newBranchName> the new branch name to give to current branch
    <oldBranchName> (optional) the name of the old branch if not current one
```

### 1.3.2. bin/dbQueryAllDatabases

Execute a query on multiple database in order to generate a report, query can be parallelized on multiple databases
```bash
bin/dbQueryAllDatabases -e localhost-root conf/dbQueries/databaseSize.sql
```

**Help**
```
Description: Execute a query on multiple databases in order to generate a report, query can be parallelized on multiple databases

Usage: dbQueryAllDatabases [-h|--help] prints this help and exits
Usage: dbQueryAllDatabases <query|queryFile> [-d|--dsn <dsn>] [-t|--as-tsv] [-q|--query] [--jobs|-j <jobsCount>] [--bar|-b]

    -t|--as-tsv           show results as tsv file (separated by tabulations)
    -q|--query            implies <query> parameter is a mysql query string
    -d|--dsn <dsn>        to use for target mysql server (Default: default.local) 
    -j|--jobs <jobsCount> specify the number of db to query in parallel (this needs the use of gnu parallel)
    -b|--bar              Show progress as a progress bar. In the bar is shown: % of jobs completed, estimated seconds left, and number of jobs started.
    <query|queryFile>
        if -q option is provided this parameter is a mysql query string
        else a file must be specified

List of available dsn:
       - default.local
       - default.remote
       - localhost-root
List of available queries (default dir /home/vagrant/projects/bash-tools/conf/dbQueries overridable in home dir /home/vagrant/.bash-tools/dbQueries):
       - databaseSize
```

### bin/dbScriptAllDatabases
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
```
Description: Allow to execute a script on each database of specified mysql server

Usage: dbScriptAllDatabases [-h|--help] prints this help and exits
Usage: dbScriptAllDatabases [-j|--jobs <numberOfJobs>] [-o|--output <outputDirectory>] [-d|--dsn <dsn>] [-v|--verbose] [-l|--log-format <logFormat>] [--database <dbName>] <scriptToExecute> [optional parameters to pass to the script]
    <scriptToExecute>             the script that will be executed on each databases
    -d|--dsn <dsn>                target mysql server (Default: default.local) 
    --database <dbName>           if provided will check only this db, otherwise script will be executed on all dbs of mysql server
    -j|--jobs <numberOfJobs>      the number of db to query in parallel (default: 1)
    -o|--output <outputDirectory> output directory, see log-format option (default : "/home/vagrant/.bash-tools/output")
    -l|--log-format <logFormat>   if log provided, will log each db result to log file, can be one of these values (none, log) (default: none)
    -v|--verbose                  display more information

Note: the use of output, log-format, verbose options highly depends on the script used

Example: script conf/dbScripts/extractData.sh 
    executes query databaseSize (see conf/dbQueries/databaseSize.sql) on each db and log the result in log file in default output dir, call it using
    /home/vagrant/projects/bash-tools/bin/dbScriptAllDatabases -j 10 extractData databaseSize

    executes query databaseSize on each db and display the result on stdout (2>/dev/null hides information messages)
    /home/vagrant/projects/bash-tools/bin/dbScriptAllDatabases -j 10 --log-format none extractData databaseSize 

    use --verbose to get some debug information
    /home/vagrant/projects/bash-tools/bin/dbScriptAllDatabases -j 10 --log-format none --verbose extractData databaseSize 

Use cases:
    you can use this script in order to check that each db model conforms with your ORM schema
    simply create a new script in conf/dbQueries that will call your orm schema checker

    update multiple db at once (simple to complex update script)

List of available dsn:
       - default.local
       - default.remote
       - localhost-root
list of available scripts (/home/vagrant/.bash-tools/conf/dbScripts):
       - dbCheckStructOneDatabase
       - dbPropelMigrationScriptOneDatabase
       - extractData
```

### 1.3.3. bin/dbImport
Import remote db into local db
```bash
dbImport ExampleDbName
```

Ability to import db from dump stored on aws
the dump file should have this name `<fromDbName>.tar.gz`
and stored on AWS location defined by S3_BASE_URL env variable (see conf/.env file)
```bash
dbImport --from-aws ExampleDbName
```

**Help**
```
Description: Import source db into target db

Usage: dbImport --help prints this help and exits
Usage: dbImport <fromDbName> [<targetDbName>] 
                        [--force] 
                        [-d|--download-dump] [-a|--from-aws]
                        [-s|--skip-schema] [-p|--profile profileName] 
                        [-o|--collation-name utf8_general_ci] [-c|--character-set utf8]
                        [-t|--target-dsn dsn] [-f|--from-dsn dsn]

    <localDbName> : use remote db name if not provided
    -f|--force                  If local db exists, it will overwrite it
    -d|--download-dump          force remote db dump (default: use already downloaded dump 
        in /home/vagrant/.bash-tools/dbImportDumps if available)
    -s|--skip-schema            avoid to import the schema
    -o|--collation-name         change the collation name used during database creation 
        (default value: collation name used by remote db)
    -c|--character-set          change the character set used during database creation 
        (default value: character set used by remote db or dump file if aws)
    -p|--profile profileName    the name of the profile to use in order to include or exclude tables
        (if not specified /home/vagrant/.bash-tools/dbImportProfiles/default.sh  is used if exists otherwise /home/vagrant/projects/bash-tools/conf/dbImportProfiles/default.sh)
    -t|--target-dsn dsn         dsn to use for target database (Default: default.local) 
    -f|--from-dsn dsn           dsn to use for source database (Default: default.remote)
        this option is incompatible with -a|--from-aws option
    -a|--from-aws               db dump will be downloaded from s3 instead of using remote db, 
        remoteDBName will represent the name of the file
        profile will be calculated against the dump itself
        this option is incompatible with -f|--from-dsn option

    Aws s3 location       : s3://example.com/exports/

List of available profiles (default profiles dir /home/vagrant/projects/bash-tools/conf/dbImportProfiles overridable in home profiles /home/vagrant/.bash-tools/dbImportProfiles):
       - all
       - default
       - none
       - sample
List of available dsn:
       - default.local
       - default.remote
       - localhost-root
```

### 1.3.4. bin/dbImportTable
Import remote db table into local db
```bash
dbImportTable ExampleDbName ExampleTableName
```

**Help**
```
Description: Import remote db table into local db

Usage: dbImportTable [-h|--help] prints this help and exits
Usage: dbImportTable <remoteDbName> <tableName> [<localDbName>] 
    [-d|--download-dump] [--force] [-a|--from-aws]
    [-t|--target-dsn dsn] [-f|--from-dsn dsn]
    [-c|--character-set utf8]

    download the remote table data and install data in local database (the schema should exists)

    <tableName>   :      table name to import
    <localDbName> :      use remote db name if not provided
    --force              If local table exists, it will overwrite it
    -t|--target-dsn dsn  dsn to use for target database (Default: default.local) 
    -f|--from-dsn dsn    dsn to use for source database (Default: default.remote)
        this option is incompatible with -a|--from-aws option
    -a|--from-aws        db dump will be downloaded from s3 instead of using remote db, 
        remoteDBName will represent the name of the file
        profile will be calculated against the dump itself
    -d|--download-dump   force remote db dump (default: use already downloaded dump in /home/vagrant/.bash-tools/dbImportDumps if available)
    -c|--character-set   change the character set used during database creation (default value: character set used by remote db)

    Aws s3 location       : s3://example.com/exports/

List of available dsn:
       - default.local
       - default.remote
       - localhost-root

```

### 1.3.5. bin/cli

**Help**
```
Description: easy connection to docker container

Usage: cli [-h|--help] prints this help and exits
Usage: cli [<container>] [user] [command]

    <container> : container should be one of these values (provided by 'docker ps'): 
        mysql8,ace-dashboard,apache2,redis,mailhog,express_1
        if not provided, it will load the container specified in default configuration (project-apache2)

examples:
    to connect to mysql container in bash mode with user mysql
        cli mysql mysql "//bin/bash"
    to connect to web container with user root
        cli web root

you can override these mappings by providing your own profile in 
    
This script will be executed with the variables userArg containerArg commandArg set as specified in command line
and should provide value for the following variables finalUserArg finalContainerArg finalCommandArg

List of available profiles (from /home/vagrant/projects/bash-tools/conf/cliProfiles and overridable in /home/vagrant/.bash-tools/cliProfiles):
       - default
       - mysql
       - mysql.remote
       - node
       - redis
       - web
```

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
will actually execute this command : MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' docker exec -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" -it --user=root project-mysql bash

**Example 3: connect to mysql server in order to execute a query**

will actually execute this command : MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' docker exec -it -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" --user=mysql project-mysql //bin/bash -c 'mysql -h127.0.0.1 -uroot -proot -P3306'

**Example 4: pipe sql command to mysql container** 
```bash
echo 'SELECT table_schema AS "Database",ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS "Size (MB)" FROM information_schema.TABLES' | bin/cli mysql
```
will actually execute this command : MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' docker exec -i -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" --user=mysql project-mysql //bin/bash -c 'mysql -h127.0.0.1 -uroot -proot -P3306'
notice that as input is given to the command, tty option is not provided to docker exec

## 1.4. Bash Framework

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
    * **Functions::addTrap** add a trap to existing trap or simply set the trap if no existing trap
  * UI
    * **UI::askToContinue** ask the user if he wishes to continue a process
    * **UI::askYesNo** ask the user a confirmation
    * **UI::askToIgnoreOverwriteAbort** ask the user to ignore(i), overwrite(o) or abort(a)
  * Version
    * **Version::checkMinimal** ensure that command exists with expected version
    * **Version::compare** compares two versions
  * Log::display* output colored message on error output and log the message 
    * **Log::fatal** error message in red bold and exits with code 1
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

## 1.5. Acknowledgements
Like so many projects, this effort has roots in many places. 

I would like to thank particularly  Bazyli Brzóska for his work on the project [Bash Infinity](https://github.com/niieani/bash-oo-framework).
Framework part of this project is largely inspired by his work(some parts copied). You can see his [blog](https://invent.life/project/bash-infinity-framework) too that is really interesting 