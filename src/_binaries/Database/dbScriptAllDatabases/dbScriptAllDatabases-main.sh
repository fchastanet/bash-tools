#!/usr/bin/env bash

# create db instance
declare -Agx dbInstance
# shellcheck disable=SC2154
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
  # shellcheck disable=SC2154
  Log::displayInfo "processing ${#optionDatabases[@]} databases using ${optionJobs} jobs"
fi

export selectedQueryFile
export MYSQL_OPTIONS
PARALLEL_OPTIONS+=("-j" "${optionJobs}")

# shellcheck disable=SC2154
printf '%s\n' "${optionDatabases[@]}" |
  SHELL=$(type -p bash) \
    parallel --bar --eta --progress --tag "${PARALLEL_OPTIONS[@]}" \
    "${argScriptToExecute}" "${optionFromDsn}" "${optionLogFormat}" "${BASH_FRAMEWORK_ARGS_VERBOSE}" \
    "${optionOutputDir}" "${PWD}" "${scriptArguments[@]}"
