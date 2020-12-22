# bash-framework/Database.sh
# Functions
# function `Database::newInstance`
> ***Public***

create a new db instance

**Arguments**:
* $1 - (passed by reference) database instance to create
* $2 - dsn profile

**Example:**
```shell
 declare -Agx dbInstance
 Database::newInstance dbInstance "${HOSTNAME}" "${PORT}" "${USER}" "${PASSWORD}"
```

Returns immediately if the instance is already initialized
# function `Database::checkDsnFile`
> ***Internal***

check if dsn file has all the mandatory variables set
 Mandatory variables are: HOSTNAME, USER, PASSWORD, PORT

**Arguments**:
* $1 - dsn absolute filename

Returns 0 on valid file, 1 otherwise with log output
# function `Database::getDefaultConfDsnFolder`
Public
 Returns the default conf dsn folder
# function `Database::getHomeConfDsnFolder`
Public
 Returns the overriden conf dsn folder in user home folder
# function `Database::getDsnList`
> ***Public***

list the dsn available in bash-tools/conf/dsn folder
 and those overriden in $HOME/.bash-tools/dsn folder
# function `Database::setOptions`
> ***Public***

set the general options to use on mysql command to query the database
 These options should be set one time at instance creation and then never changes
 use `Database::setQueryOptions` to change options by query

**Arguments**:
* $1 - (passed by reference) database instance to use
* $2 - options list
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
# function `Database::authFile`
> ***Internal***

generate temp file for easy authentication

**Arguments**:
* $1 (passed by reference) database instance to use
# function `Database::ifDbExists`
> ***Public***

check if given database exists

**Arguments**:
* $1 (passed by reference) database instance to use
* $2 database name
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
* _$4(optional)_ ... additional dump options

**Returns**: mysqldump command status code
