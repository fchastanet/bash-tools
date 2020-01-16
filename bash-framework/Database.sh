#!/usr/bin/env bash

import bash-framework/Log

#---
## @param $1 (passed by reference) database instance to create
#---
Database::newInstance() {
    local -n instance=$1
    local mysqlHostName="$2"
    local mysqlHostPort="$3"
    local mysqlUser="$4"
    local mysqlPasswd="$5"

    if [[ "${instance['INITIALIZED']:-0}" = "1" ]]; then
        return
    fi
    instance['OPTIONS']="--default-character-set=utf8"
    instance['DEFAULT_QUERY_OPTIONS']="-s --skip-column-names"
    instance['QUERY_OPTIONS']=instance['DEFAULT_QUERY_OPTIONS']
    instance['DUMP_OPTIONS']="--default-character-set=utf8 --compress --compact --hex-blob --routines --triggers --single-transaction"
    instance['AUTH_FILE']=""
    instance['COMMAND_PREFIX']=""
    instance['MYSQL_COMMAND']="/usr/bin/mysql"
    instance['MYSQLDUMP_COMMAND']="/usr/bin/mysqldump"
    instance['MYSQLSHOW_COMMAND']="/usr/bin/mysqlshow"

    instance['MYSQL_HOST']="${mysqlHostName}"
    instance['MYSQL_PORT']="${mysqlHostPort}"
    instance['MYSQL_USER']="${mysqlUser}"
    instance['MYSQL_PASSWORD']="${mysqlPasswd}"

    Database::createAuthFile instance

    instance['INITIALIZED']=1
}

#---
## @param $1 (passed by reference) database instance to use
#---
Database::setPrefix() {
    # shellcheck disable=SC2178
    local -n instance=$1
    instance['COMMAND_PREFIX']="$1"
}

#---
## @param $1 (passed by reference) database instance to use
#---
Database::setOptions() {
    # shellcheck disable=SC2178
    local -n instance=$1
    instance['OPTIONS']="$2"
}

#---
## @param $1 (passed by reference) database instance to use
#---
Database::setDumpOptions() {
    # shellcheck disable=SC2178
    local -n instance=$1
    instance['DUMP_OPTIONS']="$2"
}

#---
## @param $1 (passed by reference) database instance to use
#---
Database::setQueryOptions() {
    # shellcheck disable=SC2178
    local -n instance=$1
    instance['QUERY_OPTIONS']="$2"
}

#---
## @param $1 (passed by reference) database instance to use
## @param $2 mysql command
## @param $3 mysqldump command
## @param $4 mysqlshow command
#---
Database::setMysqlCommands() {
    # shellcheck disable=SC2178
    local -n instance=$1
    instance['MYSQL_COMMAND']="$2"
    instance['MYSQLDUMP_COMMAND']="$3"
    instance['MYSQLSHOW_COMMAND']="$4"
}

#---
## @internal generate temp file for easy authentication
## @param $1 (passed by reference) database instance to use
#---
Database::createAuthFile() {
    local -n instance2=$1

    instance2['AUTH_FILE']=$(mktemp "${TMPDIR:-/tmp}/mysql.XXXXXXXXXXXX.cnf")

    local conf=""
    conf+="[client]\n"
    conf+="user = ${instance2['MYSQL_USER']}\n"
    conf+="password = ${instance2['MYSQL_PASSWORD']}\n"
    conf+="host = ${instance2['MYSQL_HOST']}\n"
    conf+="port = ${instance2['MYSQL_PORT']}\n"

    printf "%b" "${conf}" > "${instance2['AUTH_FILE']}"

    # shellcheck disable=SC2064
    trap "rm -f '${instance2['AUTH_FILE']}' 2>/dev/null" EXIT
}

#---
## check if database exists
#---
Database::ifDbExists() {
    # shellcheck disable=SC2178
    local -n instance=$1
    local dbName="$2"

    local result
    local mysqlCommand=""

    mysqlCommand="${instance['MYSQLSHOW_COMMAND']} --defaults-extra-file='${instance['AUTH_FILE']}'"
    mysqlCommand+="'${dbName}' | grep -v Wildcard | grep -o '${dbName}'"
    Log::displayDebug "execute command: '${mysqlCommand}'"
    result=$(MSYS_NO_PATHCONV=1 eval "${mysqlCommand}")

    [[ "${result}" = "${dbName}" ]]
}

#---
## check if table $3 on db $2 exists
## @param $1 (passed by reference) database instance to use
## @param $2 the database name to check
## @param $3 the table that should exists on this db
## @return 0 if table $3 exists, 1 else
#---
Database::isTableExists() {
    # shellcheck disable=SC2178
    local -n instance=$1
    local dbName="$2"
    local tableThatShouldExists="$3"

    local sql=$"select count(*) from information_schema.tables where table_schema='${dbName}' and table_name='${tableThatShouldExists}'"
    local result
    result=$(Database::query instance "${sql}")
    if [[ "${result}" = "0" ]]; then
        Log::displayWarning "Db ${dbName} not initialized"
        return 1
    fi
    Log::displayInfo "Db ${dbName} already initialized"
    return 0
}

#---
## create database $2 if not already existent
## @param $1 (passed by reference) database instance to use
## @param $2 the database name to create
## @return 0 if success, 1 else
#---
Database::createDb() {
    # shellcheck disable=SC2178
    local -n instance=$1
    local dbName="$2"

    local sql="CREATE DATABASE IF NOT EXISTS ${dbName} CHARACTER SET 'utf8' COLLATE 'utf8_general_ci'"
    Database::query instance "${sql}"
    local result=$?

    if [[ "${result}" = "0" ]]; then
        Log::displayInfo "Db ${dbName} has been created"
    else
        Log::displayError "Creating Db ${dbName} has failed"
    fi
    return ${result}
}

#---
## drop database $2 if exists
## @param $1 (passed by reference) database instance to use
## @param $2 the database name to drop
## @return 0 if success, 1 else
#---
Database::dropDb() {
    # shellcheck disable=SC2178
    local -n instance=$1
    local dbName="$2"

    local sql="DROP DATABASE IF EXISTS ${dbName}"
    Database::query instance "${sql}"
    local result=$?

    if [[ "${result}" = "0" ]]; then
        Log::displayInfo "Db ${dbName} has been dropped"
    else
        Log::displayError "Dropping Db ${dbName} has failed"
    fi
    return ${result}
}

#---
## query mysql on a given db
## @param $1 (passed by reference) database instance to use
## @param $2 sql query to execute
##    if not provided or empty, the command can be piped (eg: cat file.sql | Database::queryDb ...)
## @param $3 (optional) the db name
Database::query() {
    # shellcheck disable=SC2178
    local -n instance=$1
    local mysqlCommand=""

    mysqlCommand+="${instance['MYSQL_COMMAND']} --defaults-extra-file='${instance['AUTH_FILE']}' ${instance['QUERY_OPTIONS']} ${instance['OPTIONS']}"
    # add optional db name
    if [[ -n "${3+x}" ]]; then
        mysqlCommand+=" '$3'"
    fi
    # add optional sql query
    if [[ -n "${2+x}" && -n "$2" ]]; then
        if [[ ! -f "$2" ]]; then
            mysqlCommand+=" -e "
            mysqlCommand+=$(Functions::quote "$2")
        fi
    fi
    Log::displayDebug "execute command: '${mysqlCommand}'"

    if [[ -f "$2" ]]; then
        eval "${mysqlCommand}" < "$2"
    else
        eval "${mysqlCommand}"
    fi
    local result="$?"

    return ${result}
}

#---
## dump db
## @param $1 (passed by reference) database instance to use
## @param $2 the db to dump
## @param $3 string containing table list
## @param $4... additional dump options
#---
Database::dump() {
    # shellcheck disable=SC2178
    local -n instance=$1
    local db="$2"
    local optionalTableList=""
    local dumpAdditionalOptions=""
    local mysqlCommand=""

    # optional table list
    shift 2
    if [[ -n "${1+x}" ]]; then
        optionalTableList="$1"
        shift 1
    fi

    # additional options
    if [[ -n "${1+x}" ]]; then
        dumpAdditionalOptions="$*"
    fi

    mysqlCommand+="${instance['MYSQLDUMP_COMMAND']} --defaults-extra-file='${instance['AUTH_FILE']}' "
    mysqlCommand+="${instance['DUMP_OPTIONS']} ${dumpAdditionalOptions} ${db} ${optionalTableList}"

    Log::displayDebug "execute command: '${mysqlCommand}'"
    eval "${mysqlCommand}"
    return $?
}
