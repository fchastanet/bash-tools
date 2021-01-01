#!/usr/bin/env bash

import bash-framework/Log

# Public: create a new db instance
#
# **Arguments**:
# * $1 - (passed by reference) database instance to create
# * $2 - dsn profile - load the dsn.env profile 
#     absolute file is deduced using rules defined in Functions::getAbsoluteConfFile
#
# **Example:**
# ```shell
# declare -Agx dbInstance
# Database::newInstance dbInstance "defaul.local"
# ```
#
# Returns immediately if the instance is already initialized
Database::newInstance() {
  local -n instanceNewInstance=$1
  local dsn="$2"

  if [[ "${instanceNewInstance['INITIALIZED']:-0}" == "1" ]]; then
    return
  fi
  
  # final auth file generated from dns file
  instanceNewInstance['AUTH_FILE']=""
  instanceNewInstance['DSN_FILE']=""

  # check dsn file
  DSN_FILE="$(Functions::getAbsoluteConfFile "dsn" "${dsn}" "env")" || exit 1
  Database::checkDsnFile "${DSN_FILE}"
  instanceNewInstance['DSN_FILE']="${DSN_FILE}"

  # shellcheck source=/conf/dsn/default.local.env
  # shellcheck disable=SC1091
  source "${instanceNewInstance['DSN_FILE']}"
  
  # generate authfile for easy authentication
  # shellcheck disable=SC2064
  instanceNewInstance['AUTH_FILE']=$(mktemp -p "${TMPDIR:-/tmp}" -t "mysql.XXXXXXXXXXXX")
  (
      echo "[client]"
      echo "user = ${USER}"
      echo "password = ${PASSWORD}"
      echo "host = ${HOSTNAME}"
      echo "port = ${PORT}"
  ) > "${instanceNewInstance['AUTH_FILE']}"
  # shellcheck disable=SC2064
  Functions::trapAdd "rm -f \"${instanceNewInstance['AUTH_FILE']}\" 2>/dev/null || true" ERR EXIT

  # some of those values can be overridden using the dsn file
  instanceNewInstance['OPTIONS']="${MYSQL_OPTIONS:---default-character-set=utf8}"
  instanceNewInstance['SSL_OPTIONS']="${MYSQL_SSL_OPTIONS:---ssl-mode=DISABLED}"
  instanceNewInstance['QUERY_OPTIONS']="${MYSQL_QUERY_OPTIONS:--s --skip-column-names}"
  instanceNewInstance['DUMP_OPTIONS']="${MYSQL_DUMP_OPTIONS:---default-character-set=utf8 --compress --compact --hex-blob --routines --triggers --single-transaction --set-gtid-purged=OFF --column-statistics=0 ${instanceNewInstance['SSL_OPTIONS']}}"
  
  instanceNewInstance['INITIALIZED']=1
}

# Internal: check if dsn file has all the mandatory variables set
# Mandatory variables are: HOSTNAME, USER, PASSWORD, PORT
#
# **Arguments**:
# * $1 - dsn absolute filename 
#
# Returns 0 on valid file, 1 otherwise with log output
Database::checkDsnFile() {
  DSN_FILENAME="$1"
  if [[ ! -f "${DSN_FILENAME}" ]]; then
    Log::displayError "dsn file ${DSN_FILENAME} not found"
    return 1
  fi

  (
    unset HOSTNAME PORT PASSWORD USER
    # shellcheck source=/conf/dsn/default.local.env
    # shellcheck disable=SC1091
    source "${DSN_FILENAME}"  
    if [[ -z ${HOSTNAME+x} ]]; then
      Log::displayError "dsn file ${DSN_FILENAME} : HOSTNAME not provided"
      return 1
    fi
    if [[ -z "${HOSTNAME}" ]]; then
      Log::displayWarning "dsn file ${DSN_FILENAME} : HOSTNAME value not provided"
    fi
    if [[ "${HOSTNAME}" = "localhost" ]]; then
      Log::displayWarning "dsn file ${DSN_FILENAME} : check that HOSTNAME should not be 127.0.0.1 instead of localhost"
    fi
    if [[ -z "${PORT+x}" ]]; then
      Log::displayError "dsn file ${DSN_FILENAME} : PORT not provided"
      return 1
    fi
    if ! [[ ${PORT} =~ ^[0-9]+$ ]] ; then
      Log::displayError "dsn file ${DSN_FILENAME} : PORT invalid"
      return 1
    fi
    if [[ -z "${USER+x}" ]]; then
      Log::displayError "dsn file ${DSN_FILENAME} : USER not provided"
      return 1
    fi
    if [[ -z "${PASSWORD+x}" ]]; then
      Log::displayError "dsn file ${DSN_FILENAME} : PASSWORD not provided"
      return 1
    fi
  )
}

# Public: set the general options to use on mysql command to query the database
# These options should be set one time at instance creation and then never changes
# use `Database::setQueryOptions` to change options by query
#
# **Arguments**:
# * $1 - (passed by reference) database instance to use
# * $2 - options list
Database::setOptions() {
  local -n instanceSetOptions=$1
  # shellcheck disable=SC2034
  instanceSetOptions['OPTIONS']="$2"
}

# Public: set the options to use on mysqldump command
#
# **Arguments**:
# * $1 - (passed by reference) database instance to use
# * $2 - options list
Database::setDumpOptions() {
  local -n instanceSetDumpOptions=$1
  # shellcheck disable=SC2034
  instanceSetDumpOptions['DUMP_OPTIONS']="$2"
}

# Public: set the general options to use on mysql command to query the database
# Differs than setOptions in the way that these options could change each time
#
# **Arguments**:
# * $1 - (passed by reference) database instance to use
# * $2 - options list
Database::setQueryOptions() {
  local -n instanceSetQueryOptions=$1
  # shellcheck disable=SC2034
  instanceSetQueryOptions['QUERY_OPTIONS']="$2"
}

# Public: check if given database exists
#
# **Arguments**:
# * $1 (passed by reference) database instance to use
# * $2 database name
Database::ifDbExists() {
  # shellcheck disable=SC2178
  local -n instanceIfDbExists=$1
  local dbName="$2"

  local result
  local -a mysqlCommand=()

  mysqlCommand+=(mysqlshow)
  mysqlCommand+=("--defaults-extra-file=${instanceIfDbExists['AUTH_FILE']}")
  # shellcheck disable=SC2206
  mysqlCommand+=(${instanceIfDbExists['SSL_OPTIONS']})
  mysqlCommand+=("${dbName}")
  Log::displayDebug "execute command: '${mysqlCommand[*]}'"
  result="$(MSYS_NO_PATHCONV=1 "${mysqlCommand[@]}" 2>/dev/null | grep '^Database: ' | grep -o "${dbName}" )"
  [[ "${result}" = "${dbName}" ]]
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
  # shellcheck disable=SC2178,SC2034
  local -n instanceIsTableExists=$1
  local dbName="$2"
  local tableThatShouldExists="$3"

  local sql="select count(*) from information_schema.tables where table_schema='${dbName}' and table_name='${tableThatShouldExists}'"
  local result
  result="$(Database::query instanceIsTableExists "${sql}")"
  if [ "${result}" != "1" ]; then
    return 1
  fi
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
  # shellcheck disable=SC2034
  local -n instanceCreateDb=$1
  local dbName="$2"

  local sql="CREATE DATABASE IF NOT EXISTS ${dbName} CHARACTER SET 'utf8' COLLATE 'utf8_general_ci'"
  Database::query instanceCreateDb "${sql}"
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
  # shellcheck disable=SC2034
  local -n instanceDropDb=$1
  local dbName="$2"

  local sql="DROP DATABASE IF EXISTS ${dbName}"
  Database::query instanceDropDb "${sql}"
  local result=$?

  if [[ "${result}" == "0" ]]; then
    Log::displayInfo "Db ${dbName} has been dropped"
  else
    Log::displayError "Dropping Db ${dbName} has failed"
  fi
  return ${result}
}

# Public: drop table if exists
#
# **Arguments**:
# * $1 (passed by reference) database instance to use
# * $2 database name
# * $3 table name to drop
#
# **Returns**:
# * 0 if success
# * 1 else
Database::dropTable() {
  # shellcheck disable=SC2034
  local -n instanceDropTable=$1
  local dbName="$2"
  local tableName="$3"

  local sql="DROP TABLE IF EXISTS ${tableName}"
  Database::query instanceDropTable "${sql}" "${dbName}"
  local result=$?

  if [[ "${result}" == "0" ]]; then
    Log::displayInfo "Table ${dbName}.${tableName} has been dropped"
  else
    Log::displayError "Dropping Table ${dbName}.${tableName} has failed"
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
  local -n instanceQuery=$1
  local -a mysqlCommand=()

  mysqlCommand+=(mysql)
  mysqlCommand+=("--defaults-extra-file=${instanceQuery['AUTH_FILE']}")
  IFS=' ' read -r -a queryOptions <<< "${instanceQuery['QUERY_OPTIONS']}"
  mysqlCommand+=("${queryOptions[@]}")
  IFS=' ' read -r -a options <<< "${instanceQuery['OPTIONS']}"
  mysqlCommand+=("${options[@]}")
  # add optional db name
  if [[ -n "${3+x}" ]]; then
    mysqlCommand+=("$3")
  fi
  # add optional sql query
  if [[ -n "${2+x}" && -n "$2" ]]; then
    if [[ ! -f "$2" ]]; then
      mysqlCommand+=("-e")
      mysqlCommand+=("$2")
    fi
  fi
  Log::displayDebug "$(printf "execute command: '%s'"  "${mysqlCommand[*]}")"

  if [[ -f "$2" ]]; then
    "${mysqlCommand[@]}" < "$2"
  else
    "${mysqlCommand[@]}"
  fi
}

# Public: dump db limited to optional table list
#
# **Arguments**:
# * $1 (passed by reference) database instance to use
# * $2 the db to dump
# * _$3(optional)_ string containing table list 
#       (can be empty string in order to specify additional options)
# * _$4(optional)_ ... additional dump options
#
# **Returns**: mysqldump command status code
Database::dump() {
  # shellcheck disable=SC2178
  local -n instanceDump=$1
  local db="$2"
  local optionalTableList=""
  local dumpAdditionalOptions=()
  local -a mysqlCommand=()

  # optional table list
  shift 2
  if [[ -n "${1+x}" ]]; then
    optionalTableList="$1"
    shift 1
  fi

  # additional options
  if [[ -n "${1+x}" ]]; then
    dumpAdditionalOptions=("$@")
  fi

  mysqlCommand+=(mysqldump)
  mysqlCommand+=("--defaults-extra-file=${instanceDump['AUTH_FILE']}")
  IFS=' ' read -r -a dumpOptions <<< "${instanceDump['DUMP_OPTIONS']}"
  mysqlCommand+=("${dumpOptions[@]}")
  mysqlCommand+=("${dumpAdditionalOptions[@]}")
  mysqlCommand+=("${db}")
  # shellcheck disable=SC2206
  mysqlCommand+=(${optionalTableList})

  Log::displayDebug "execute command: '${mysqlCommand[*]}'"
  "${mysqlCommand[@]}"
  return $?
}
