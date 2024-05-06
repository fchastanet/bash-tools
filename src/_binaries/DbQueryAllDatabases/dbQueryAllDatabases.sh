#!/usr/bin/env bash
# BIN_FILE=${BASH_TOOLS_ROOT_DIR}/bin/dbQueryAllDatabases
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE
# shellcheck disable=SC2034

# later on, parallel calls this script(inception)
if [[ "$1" = "DbQueryOneDatabase" ]]; then
  shift || true
  Linux::requireExecutedAsUser
  Db::queryOneDatabase "$@"
  exit 0
fi

#default values
# default value for FROM_DSN if from-aws not set
declare queryIsFile="0"
declare optionSeparator="|"
declare argQuery=""

# other configuration
declare copyrightBeginYear="2020"
declare QUERIES_DIR="${BASH_TOOLS_ROOT_DIR}/conf/dbQueries"
declare HOME_QUERIES_DIR="${HOME}/.bash-tools/dbQueries"

.INCLUDE "$(dynamicTemplateDir _binaries/DbQueryAllDatabases/dbQueryAllDatabases.options.tpl)"

declare awkScript
awkScript="$(
  cat <<'EOF'
.INCLUDE "$(dynamicSrcFile "_binaries/DbQueryAllDatabases/dbQueryAllDatabases.awk")"

EOF
)"

# @require Linux::requireExecutedAsUser
run() {

  # query contains the sql from argQuery or from query string if -q option is provided
  declare query="${argQuery}"
  if [[ "${queryIsFile}" = "1" ]]; then
    query="$(cat "${argQuery}")"
  fi

  declare -Agx dbInstance
  Database::newInstance dbInstance "${optionFromDsn}"
  Database::setQueryOptions dbInstance "${dbInstance['QUERY_OPTIONS']} --connect-timeout=5"
  Log::displayInfo "Using dsn ${dbInstance['DSN_FILE']}"

  # list of all databases
  allDbs="$(Database::getUserDbList dbInstance)"
  PARALLEL_OPTIONS+=("--linebuffer" "-j" "${optionJobs}")

  # query all databases
  export query
  export optionSeparator
  export optionFromDsn
  # shellcheck disable=SC2154
  echo "${allDbs}" |
    SHELL=$(type -p bash) parallel --eta --progress -m "${PARALLEL_OPTIONS[@]}" \
      ::: "$0" "DbQueryOneDatabase" "${optionFromDsn}" |
    awk --source "${awkScript}" -
}

if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "1" ]]; then
  run &>/dev/null
else
  run
fi
