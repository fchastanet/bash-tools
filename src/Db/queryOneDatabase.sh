#!/usr/bin/env bash

# @require Linux::requireExecutedAsUser
Db::queryOneDatabase() {
  # query, dsnFile and optionSeparator are passed via export
  local db="$1"

  local -A dbInstance
  Database::newInstance dbInstance "${optionFromDsn}"
  Database::setQueryOptions dbInstance "${dbInstance[QUERY_OPTIONS]} --connect-timeout=5"

  # identify columns header
  echo -n "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  Database::skipColumnNames dbInstance 0

  # shellcheck disable=SC2154
  if ! Database::query dbInstance "${query}" "${db}" | sed "s/\t/${optionSeparator}/g"; then
    Log::fatal "database ${db} error" 1>&2
  fi
}
