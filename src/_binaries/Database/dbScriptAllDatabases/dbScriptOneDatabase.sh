#!/usr/bin/env bash

############################################################
# INTERNAL USE ONLY
# USED BY bin/dbScriptAllDatabases sub scripts
# eg: src/DbScriptAllDatabases/extractData.sh
############################################################
Assert::expectNonRootUser

declare DSN="$1"
# shellcheck disable=SC2034
declare LOG_FORMAT="$2"
# shellcheck disable=SC2034
declare VERBOSE="${3:-0}"
# shellcheck disable=SC2034
declare outputDir="$4"
# shellcheck disable=SC2034
declare callingDir="$5"

declare -i length=$(($# - 6))
# shellcheck disable=SC2034
declare -a scriptParameters=("${@:6:${length}}")
# shellcheck disable=SC2034,SC2124
declare db="${@:$(($#)):1}"
# shellcheck disable=SC2034
declare -A dbInstance

init() {
  if ((VERBOSE >= 1)); then
    Log::displayInfo "process db '${db}'"
  fi

  # shellcheck disable=SC2154
  if [[ -z "${scriptParameters[0]}" ]]; then
    Log::fatal "query string or file not provided"
  fi

  Database::newInstance dbInstance "${DSN}"
  Database::setQueryOptions dbInstance "${dbInstance[QUERY_OPTIONS]} --connect-timeout=5"
}

unknownArg() {
  :
}

beforeParseCallback() {
  Env::requireLoad
  UI::requireTheme
  Log::requireLoad
  Linux::requireExecutedAsUser
  Linux::requireRealpathCommand
  init
}
