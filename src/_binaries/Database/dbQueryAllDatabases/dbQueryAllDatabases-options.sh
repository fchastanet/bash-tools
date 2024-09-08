#!/usr/bin/env bash

declare QUERIES_DIR
declare HOME_QUERIES_DIR
declare queryIsFile="0"
declare optionSeparator="|"

# shellcheck disable=SC2034
declare copyrightBeginYear="2020"
# shellcheck disable=SC2034
declare defaultFromDsn="default.remote"

beforeParseCallback() {
  defaultBeforeParseCallback
  Linux::requireExecutedAsUser
  Linux::requireRealpathCommand
}

initConf() {
  # shellcheck disable=SC2034
  QUERIES_DIR="${BASH_TOOLS_ROOT_DIR}/conf/dbQueries"
  HOME_QUERIES_DIR="${HOME}/.bash-tools/dbQueries"

  Db::checkRequirements
}

optionHelpCallback() {
  dbQueryAllDatabasesCommandHelp
  exit 0
}

optionSeparatorCallback() {
  # shellcheck disable=SC2154
  if ((${#optionSeparator} != 1)); then
    Log::fatal "Command ${SCRIPT_NAME} - only one character is accepted as separator"
  fi

  if [[ ${optionSeparator} =~ [a-zA-Z0-9/\ ] ]]; then
    Log::fatal "Command ${SCRIPT_NAME} - characters alphanumeric, slash(/) and space( ) are not supported as separator"
  fi
}

longDescriptionFunction() {
  local example1=$'dbQueryAllDatabases databaseSize -j 12 --separator "|" --bar 2>/dev/null | column -s "|" -t -n -c 40'

  local queriesList
  queriesList="$(Conf::getMergedList "dbQueries" "sql" "      - " || true)"

  fromDsnOptionLongDescription
  echo
  echo -e "  ${__HELP_TITLE}QUERIES${__HELP_NORMAL}"
  echo -e "    ${__HELP_TITLE}Default queries directory:${__HELP_NORMAL}"
  echo -e "      ${QUERIES_DIR-configuration error}"
  echo
  echo -e "    ${__HELP_TITLE}User queries directory:${__HELP_NORMAL}"
  echo -e "      ${HOME_QUERIES_DIR-configuration error}"
  echo -e "      Allows to override queries defined in 'Default queries directory'"
  echo
  echo -e "    ${__HELP_TITLE}List of available queries:${__HELP_NORMAL}"
  echo -e "${queriesList}"
  echo
  echo -e "  ${__HELP_TITLE}EXAMPLES:${__HELP_NORMAL}"
  echo -e "    ${__HELP_EXAMPLE}${example1}${__HELP_NORMAL}"
}

argQueryHelpFunction() {
  echo "    Query to execute"
  echo "      - <file>, try to execute the mysql query"
  echo "        provided by the file"
  echo '      - <queryFile>, search for query file in'
  echo '        queries directory (see below)'
  echo '      - else the argument is interpreted as'
  echo '        query string'
}

dbQueryAllDatabasesEveryArgumentCallback() {
  if [[ -n "${DB_QUERY_ALL_DATABASES_COMMAND:-}" ]]; then
    # a command is defined, then accept that arguments can be overridden
    return 1
  fi
}

argQueryCallback() {
  if [[ -f "${argQuery}" ]]; then
    queryIsFile="1"
  else
    declare queryAbsoluteFile
    queryAbsoluteFile="$(Conf::getAbsoluteFile "dbQueries" "${argQuery}" "sql")" && {
      # shellcheck disable=SC2034
      queryIsFile="1"
      argQuery="${queryAbsoluteFile}"
      Log::displayInfo "Using query file ${queryAbsoluteFile}"
    }
  fi
}

dbQueryAllDatabasesCommandCallback() {
  if [[ -z "${optionFromDsn}" ]]; then
    # default value for FROM_DSN if from-aws not set
    optionFromDsn="${defaultFromDsn}"
  fi
}
