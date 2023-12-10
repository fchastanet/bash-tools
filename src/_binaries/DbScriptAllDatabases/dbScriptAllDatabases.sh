#!/usr/bin/env bash
# BIN_FILE=${BASH_TOOLS_ROOT_DIR}/bin/dbScriptAllDatabases
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE
# EMBED Db::queryOneDatabase as dbQueryOneDatabase
# shellcheck disable=SC2034

# default values
declare outputDirectory="${HOME}/.bash-tools/output"
declare optionFromDsn=""
declare optionOutputDir=""
declare optionLogFormat=""
declare optionJobs=""
declare argScriptToExecute=""
declare -a scriptArguments=()

# other configuration
declare copyrightBeginYear="2020"
declare QUERIES_DIR="${BASH_TOOLS_ROOT_DIR}/conf/dbQueries"
declare HOME_QUERIES_DIR="${HOME}/.bash-tools/dbQueries"

.INCLUDE "$(dynamicTemplateDir _binaries/DbScriptAllDatabases/dbScriptAllDatabases.options.tpl)"

# @require Linux::requireExecutedAsUser
run() {

  # check dependencies
  Assert::commandExists mysql "sudo apt-get install -y mysql-client"
  Assert::commandExists mysqlshow "sudo apt-get install -y mysql-client"
  Assert::commandExists parallel "sudo apt-get install -y parallel"

  # create db instance
  declare -Agx dbInstance
  Database::newInstance dbInstance "${optionFromDsn}"
  Database::setQueryOptions dbInstance "${dbInstance['QUERY_OPTIONS']} --connect-timeout=5"
  if ((BASH_FRAMEWORK_ARGS_VERBOSE >= __VERBOSE_LEVEL_DEBUG)); then
    Log::displayInfo "Using dsn ${dbInstance['DSN_FILE']}"
  fi

  # list of all databases
  if ((BASH_FRAMEWORK_ARGS_VERBOSE >= __VERBOSE_LEVEL_DEBUG)); then
    Log::displayInfo "get the list of all databases"
  fi

  if ((${#optionDatabases[@]} == 0)); then
    mapfile -t optionDatabases < <(Database::getUserDbList dbInstance)
  fi

  if ((BASH_FRAMEWORK_ARGS_VERBOSE >= __VERBOSE_LEVEL_DEBUG)); then
    Log::displayInfo "processing ${#optionDatabases[@]} databases using ${optionJobs} jobs"
  fi

  export selectedQueryFile
  export MYSQL_OPTIONS

  printf '%s\n' "${optionDatabases[@]}" | parallel --eta --progress --tag --jobs="${optionJobs}" \
    "${argScriptToExecute}" "${optionFromDsn}" "${optionLogFormat}" "${BASH_FRAMEWORK_ARGS_VERBOSE}" \
    "${optionOutputDir}" "${PWD}" "${scriptArguments[@]}"
}

if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "1" ]]; then
  run &>/dev/null
else
  run
fi
