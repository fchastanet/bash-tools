#!/usr/bin/env bash
# VAR_MAIN_FUNCTION_VAR_NAME=dbQueryAllDatabasesFacade

# @description used to execute given query when using
# dbScriptAllDatabases
# @arg $1 dsn:String
# @arg $2 db:String
# @env query String
# @env optionSeparator String
# @require Linux::requireExecutedAsUser
Db::queryOneDatabase() {
  # query and optionSeparator are passed via export
  local dsn="$1"
  local db="$2"

  local -A dbInstance
  Database::newInstance dbInstance "${dsn}"
  Database::setQueryOptions dbInstance "${dbInstance[QUERY_OPTIONS]} --connect-timeout=5"

  # identify columns header
  echo -n "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  Database::skipColumnNames dbInstance 0

  # shellcheck disable=SC2154
  if ! Database::query dbInstance "${query}" "${db}" | sed "s/\t/${optionSeparator}/g"; then
    Log::fatal "database ${db} error" 1>&2
  fi
}
