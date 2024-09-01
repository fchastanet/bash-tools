#!/usr/bin/env bash
# @embed "${BASH_TOOLS_ROOT_DIR}/src/_binaries/Database/dbQueryAllDatabases/dbQueryAllDatabases.awk" AS dbQueryAllDatabasesScript

# later on, parallel calls this script(inception)
if [[ "${DB_QUERY_ALL_DATABASES_COMMAND}" = "DbQueryOneDatabase" ]]; then
  shift || true
  Linux::requireExecutedAsUser
  Db::queryOneDatabase "${ORIGINAL_BASH_FRAMEWORK_ARGV[@]}"
  exit 0
fi

# query contains the sql from argQuery or from query string if -q option is provided
# shellcheck disable=SC2154
declare query="${argQuery}"
# shellcheck disable=SC2154
if [[ "${queryIsFile}" = "1" ]]; then
  query="$(cat "${argQuery}")"
fi

declare -Agx dbInstance
Database::newInstance dbInstance "${optionFromDsn}"
Database::setQueryOptions dbInstance "${dbInstance['QUERY_OPTIONS']} --connect-timeout=5"
Log::displayInfo "Using dsn ${dbInstance['DSN_FILE']}"

# list of all databases
allDbs="$(Database::getUserDbList dbInstance)"
PARALLEL_OPTIONS+=("-j" "${optionJobs}")

# query all databases
export query
export optionSeparator
export optionFromDsn
export DB_QUERY_ALL_DATABASES_COMMAND="DbQueryOneDatabase"
# shellcheck disable=SC2154
echo "${allDbs}" |
  SHELL=$(type -p bash) \
    parallel --bar --eta --progress "${PARALLEL_OPTIONS[@]}" \
    "$0" "${optionFromDsn}" |
  awk -f "${embed_file_dbQueryAllDatabasesScript}" -
