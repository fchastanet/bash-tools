# bash-framework/Database.sh
# Functions
# function `Database::newInstance`
> ***Public***

create a new db instance

**Arguments**:
* $1 - (passed by reference) database instance to create
* $2 - dsn profile - load the dsn.env profile
      absolute file is deduced using rules defined in Functions::getAbsoluteConfFile

**Example:**
```shell
 declare -Agx dbInstance
 Database::newInstance dbInstance "defaul.local"
```

Returns immediately if the instance is already initialized
# function `Database::checkDsnFile`
> ***Internal***

check if dsn file has all the mandatory variables set
 Mandatory variables are: HOSTNAME, USER, PASSWORD, PORT

**Arguments**:
* $1 - dsn absolute filename

Returns 0 on valid file, 1 otherwise with log output
# function `Database::skipColumnNames`
> ***Public***

by default we skip the column names
 but sometimes we need column names to display some results
 disable this option temporarely and then restore it to true

**Arguments**:
* $1 - (passed by reference) database instance to use
* $2 - 0 to disable, 1 to enable (hide column names)
# function `Database::setDumpOptions`
> ***Public***

set the options to use on mysqldump command

**Arguments**:
* $1 - (passed by reference) database instance to use
* $2 - options list
# function `Database::setQueryOptions`
> ***Public***

set the general options to use on mysql command to query the database
 Differs than setOptions in the way that these options could change each time

**Arguments**:
* $1 - (passed by reference) database instance to use
* $2 - options list
# function `Database::ifDbExists`
> ***Public***

check if given database exists

**Arguments**:
* $1 (passed by reference) database instance to use
* $2 database name
# function `Database::getUserDbList`
 Public: lis dbs of given mysql server
 **Output**:
 the list of db exept mysql admin ones :
 - information_schema
 - mysql
 - performance_schema
 - sys

**Arguments**:
* $1 (passed by reference) database instance to use
# function `Database::isTableExists`
> ***Public***

check if table exists on given db

**Arguments**:
* $1 (passed by reference) database instance to use
* $2 database name
* $3 the table that should exists on this db

**Returns**:
* 0 if table $3 exists
* 1 else
# function `Database::createDb`
> ***Public***

create database if not already existent

**Arguments**:
* $1 (passed by reference) database instance to use
* $2 database name to create

**Returns**:
* 0 if success
* 1 else
# function `Database::dropDb`
> ***Public***

drop database if exists

**Arguments**:
* $1 (passed by reference) database instance to use
* $2 database name to drop

**Returns**:
* 0 if success
* 1 else
# function `Database::dropTable`
> ***Public***

drop table if exists

**Arguments**:
* $1 (passed by reference) database instance to use
* $2 database name
* $3 table name to drop

**Returns**:
* 0 if success
* 1 else
# function `Database::query`
> ***Public***

mysql query on a given db

**Arguments**:
* $1 (passed by reference) database instance to use
* $2 sql query to execute.
     if not provided or empty, the command can be piped (eg: cat file.sql | Database::queryDb ...)
* _$3 (optional)_ the db name

**Returns**: mysql command status code
# function `Database::dump`
> ***Public***

dump db limited to optional table list

**Arguments**:
* $1 (passed by reference) database instance to use
* $2 the db to dump
* _$3(optional)_ string containing table list
        (can be empty string in order to specify additional options)
* _$4(optional)_ ... additional dump options

**Returns**: mysqldump command status code
