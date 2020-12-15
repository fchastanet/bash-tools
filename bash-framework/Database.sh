#!/usr/bin/env bash

import bash-framework/Log

# Public: create a new db instance
#
# **Arguments**:
# * $1 - (passed by reference) database instance to create
# * $2 - dsn profile
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
  local dsn="$2"

  if [[ "${instance['INITIALIZED']:-0}" == "1" ]]; then
    return
  fi
  instance['OPTIONS']="--default-character-set=utf8"
  instance['SSL_OPTIONS']='--ssl-mode=DISABLED'
  instance['DEFAULT_QUERY_OPTIONS']="-s --skip-column-names ${instance['SSL_OPTIONS']} "
  instance['QUERY_OPTIONS']="${instance['DEFAULT_QUERY_OPTIONS']:-}"
  instance['DUMP_OPTIONS']="--default-character-set=utf8 --compress --compact --hex-blob --routines --triggers --single-transaction --set-gtid-purged=OFF --column-statistics=0 ${instance['SSL_OPTIONS']}"
  instance['AUTH_FILE']=""
  instance['MYSQL_COMMAND']="/usr/bin/mysql"
  instance['MYSQLDUMP_COMMAND']="/usr/bin/mysqldump"
  instance['MYSQLSHOW_COMMAND']="/usr/bin/mysqlshow"
  instance['DSN_FILE']=""

  # check dsn file
  # load dsn from home folder, then bash framework folder, then absolute file
  # shellcheck source=/conf/dsn/default.local.env
  DSN_FILE="$(Database::getHomeConfDsnFolder)/${dsn}.env"
  if [ ! -f "${DSN_FILE}" ]; then
    DSN_FILE="$(Database::getDefaultConfDsnFolder)/${dsn}.env"
    if [ ! -f "${DSN_FILE}" ]; then
      DSN_FILE="${dsn}"
      if [ ! -f "${DSN_FILE}" ]; then
        Log::displayError "dsn file ${dsn} not found"
        return 1    
      fi
    fi
  fi
  Database::checkDsnFile "${DSN_FILE}"

  instance['DSN_FILE']="${DSN_FILE}"

  instance['INITIALIZED']=1
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

# Public
# Returns the default conf dsn folder
Database::getDefaultConfDsnFolder() {
  echo "${__bash_framework_rootVendorPath}/conf/dsn"
}

# Public
# Returns the overriden conf dsn folder in user home folder 
Database::getHomeConfDsnFolder() {
  echo "${HOME}/.bash-tools/dsn"
}

# Public: list the dsn available in bash-tools/conf/dsn folder
# and those overriden in $HOME/.bash-tools/dsn folder
Database::getDsnList() {
  DEFAULT_CONF_DIR="$(Database::getDefaultConfDsnFolder)"
  HOME_CONF_DIR="$(Database::getHomeConfDsnFolder)"
  (
    (cd "${DEFAULT_CONF_DIR}" && find . -type f -name \*.env | sed 's/\.env$//g' | sed 's#^./##g' )

    if [[ -d "${HOME_CONF_DIR}" ]]; then
        (cd "${HOME_CONF_DIR}" && find . -type f -name \*.env | sed 's/\.env$//g' | sed 's#^./##g')
    fi
  ) | sort | uniq
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
  local -n instance2=$1
  instance2['OPTIONS']="$2"
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
Database::authFile() {
  local -n instance3=$1

  (
      # shellcheck source=/conf/dsn/default.local.env
      source "${instance3['DSN_FILE']}"
      echo "[client]"
      echo "user = ${USER}"
      echo "password = ${PASSWORD}"
      echo "host = ${HOSTNAME}"
      echo "port = ${PORT}"
  )
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


  mysqlCommand="${instance['MYSQLSHOW_COMMAND']} --defaults-extra-file=<(Database::authFile instance) ${instance['SSL_OPTIONS']} "
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
  # shellcheck disable=SC2178,SC2034
  local -n instanceIsTableExists=$1
  local dbName="$2"
  local tableThatShouldExists="$3"

  local sql=$"select count(*) from information_schema.tables where table_schema='${dbName}' and table_name='${tableThatShouldExists}'"
  local result
  result=$(Database::query instanceIsTableExists "${sql}")
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
  local -n instance2=$1
  local dbName="$2"

  local sql="CREATE DATABASE IF NOT EXISTS ${dbName} CHARACTER SET 'utf8' COLLATE 'utf8_general_ci'"
  Database::query instance2 "${sql}"
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
  local -n instance2=$1
  local dbName="$2"

  local sql="DROP DATABASE IF EXISTS ${dbName}"
  Database::query instance2 "${sql}"
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
  # shellcheck disable=SC2178
  local -n instance2=$1
  local dbName="$2"
  local tableName="$3"

  local sql="DROP TABLE IF EXISTS ${tableName}"
  Database::query instance2 "${sql}" "${dbName}"
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
  local mysqlCommand=""

  mysqlCommand+="${instanceQuery['MYSQL_COMMAND']} --defaults-extra-file=<(Database::authFile instance) ${instanceQuery['QUERY_OPTIONS']} ${instanceQuery['OPTIONS']}"
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

  mysqlCommand+="${instance['MYSQLDUMP_COMMAND']} --defaults-extra-file=<(Database::authFile instance) "
  mysqlCommand+="${instance['DUMP_OPTIONS']} ${dumpAdditionalOptions} ${db} ${optionalTableList}"

  Log::displayDebug "execute command: '${mysqlCommand}'"
  eval "${mysqlCommand}"
  return $?
}
