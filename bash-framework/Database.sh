#!/usr/bin/env bash

import bash-framework/Log

# Public: create a new db instance
#
# **Arguments**:
# * $1 - (passed by reference) database instance to create
# * $2 - mysqlHostName
# * $3 - mysqlHostPort
# * $4 - mysqlHostUser
# * $5 - mysqlHostPassword
#
# **Example:**
# ```shell
# declare -Agx dbInstance
# Database::newInstance dbInstance "${HOSTNAME}" "${PORT}" "${USER}" "${PASSWORD}"
# ```
#
# Returns immediately if the instance is already initialized
Database::newInstance() {
  local -n instance=$1
  local mysqlHostName="$2"
  local mysqlHostPort="$3"
  local mysqlUser="$4"
  local mysqlPasswd="$5"

  if [[ "${instance['INITIALIZED']:-0}" == "1" ]]; then
    return
  fi
  instance['OPTIONS']="--default-character-set=utf8"
  instance['DEFAULT_QUERY_OPTIONS']="-s --skip-column-names"
  instance['QUERY_OPTIONS']=instance['DEFAULT_QUERY_OPTIONS']
  instance['DUMP_OPTIONS']="--default-character-set=utf8 --compress --compact --hex-blob --routines --triggers --single-transaction"
  instance['AUTH_FILE']=""
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

# Public: set the general options to use on mysql command to query the database
# These options should be set one time at instance creation and then never changes
# use `Database::setQueryOptions` to change options by query
#
# **Arguments**:
# * $1 - (passed by reference) database instance to use
# * $2 - options list
Database::setOptions() {
  # shellcheck disable=SC2178
  local -n instance=$1
  instance['OPTIONS']="$2"
}

# Public: set the options to use on mysqldump command
#
# **Arguments**:
# * $1 - (passed by reference) database instance to use
# * $2 - options list
Database::setDumpOptions() {
  # shellcheck disable=SC2178
  local -n instance=$1
  instance['DUMP_OPTIONS']="$2"
}

# Public: set the general options to use on mysql command to query the database
# Differs than setOptions in the way that these options could change each time
#
# **Arguments**:
# * $1 - (passed by reference) database instance to use
# * $2 - options list
Database::setQueryOptions() {
  # shellcheck disable=SC2178
  local -n instance=$1
  instance['QUERY_OPTIONS']="$2"
}

# Public: set the command fullpath for mysql, mysqldump and mysqlshow
#
# **Arguments**:
# * $1 (passed by reference) database instance to use
# * $2 mysql command
# * $3 mysqldump command
# * $4 mysqlshow command
#---
Database::setMysqlCommands() {
  # shellcheck disable=SC2178
  local -n instance=$1
  instance['MYSQL_COMMAND']="$2"
  instance['MYSQLDUMP_COMMAND']="$3"
  instance['MYSQLSHOW_COMMAND']="$4"
}

# Internal: generate temp file for easy authentication
#
# **Arguments**:
# * $1 (passed by reference) database instance to use
Database::createAuthFile() {
  local -n instance2=$1

  instance2['AUTH_FILE']=$(mktemp "${TMPDIR:-/tmp}/mysql.XXXXXXXXXXXX.cnf")

  local conf=""
  conf+="[client]\n"
  conf+="user = ${instance2['MYSQL_USER']}\n"
  conf+="password = ${instance2['MYSQL_PASSWORD']}\n"
  conf+="host = ${instance2['MYSQL_HOST']}\n"
  conf+="port = ${instance2['MYSQL_PORT']}\n"

  printf "%b" "${conf}" >"${instance2['AUTH_FILE']}"

  # shellcheck disable=SC2064
  trap "rm -f '${instance2['AUTH_FILE']}' 2>/dev/null" EXIT
}

# Public: check if given database exists
#
# **Arguments**:
# * $1 (passed by reference) database instance to use
# * $2 database name
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

  [[ "${result}" == "${dbName}" ]]
}

# Public: check if table exists on given db
#
# **Arguments**:
# * $1 (passed by reference) database instance to use
# * $2 database name
# * $3 the table that should exists on this db
#
# **Returns**:
# * 0 if table $3 exists
# * 1 else
Database::isTableExists() {
  # shellcheck disable=SC2178
  local -n instance=$1
  local dbName="$2"
  local tableThatShouldExists="$3"

  local sql=$"select count(*) from information_schema.tables where table_schema='${dbName}' and table_name='${tableThatShouldExists}'"
  local result
  result=$(Database::query instance "${sql}")
  if [[ "${result}" == "0" ]]; then
    Log::displayWarning "Db ${dbName} not initialized"
    return 1
  fi
  Log::displayInfo "Db ${dbName} already initialized"
  return 0
}

# Public: create database if not already existent
#
# **Arguments**:
# * $1 (passed by reference) database instance to use
# * $2 database name to create
#
# **Returns**:
# * 0 if success
# * 1 else
Database::createDb() {
  # shellcheck disable=SC2178
  local -n instance=$1
  local dbName="$2"

  local sql="CREATE DATABASE IF NOT EXISTS ${dbName} CHARACTER SET 'utf8' COLLATE 'utf8_general_ci'"
  Database::query instance "${sql}"
  local result=$?

  if [[ "${result}" == "0" ]]; then
    Log::displayInfo "Db ${dbName} has been created"
  else
    Log::displayError "Creating Db ${dbName} has failed"
  fi
  return ${result}
}

# Public: drop database if exists
#
# **Arguments**:
# * $1 (passed by reference) database instance to use
# * $2 database name to drop
#
# **Returns**:
# * 0 if success
# * 1 else
Database::dropDb() {
  # shellcheck disable=SC2178
  local -n instance=$1
  local dbName="$2"

  local sql="DROP DATABASE IF EXISTS ${dbName}"
  Database::query instance "${sql}"
  local result=$?

  if [[ "${result}" == "0" ]]; then
    Log::displayInfo "Db ${dbName} has been dropped"
  else
    Log::displayError "Dropping Db ${dbName} has failed"
  fi
  return ${result}
}

# Public: mysql query on a given db
#
# **Arguments**:
# * $1 (passed by reference) database instance to use
# * $2 sql query to execute.
#    if not provided or empty, the command can be piped (eg: cat file.sql | Database::queryDb ...)
# * _$3 (optional)_ the db name
#
# **Returns**: mysql command status code
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
    eval "${mysqlCommand}" <"$2"
  else
    eval "${mysqlCommand}"
  fi
  local result="$?"

  return ${result}
}

# Public: dump db limited to optional table list
#
# **Arguments**:
# * $1 (passed by reference) database instance to use
# * $2 the db to dump
# * _$3(optional)_ string containing table list
# * _$4(optional)_ ... additional dump options
#
# **Returns**: mysqldump command status code
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
