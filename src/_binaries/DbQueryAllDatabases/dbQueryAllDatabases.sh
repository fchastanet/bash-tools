#!/usr/bin/env bash
# BIN_FILE=${FRAMEWORK_ROOT_DIR}/bin/dbQueryAllDatabases
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE
# EMBED Db::queryOneDatabase as dbQueryOneDatabase

.INCLUDE "$(dynamicTemplateDir _binaries/DbQueryAllDatabases/dbQueryAllDatabases.options.tpl)"

dbQueryAllDatabasesCommand parse "${BASH_FRAMEWORK_ARGV[@]}"

declare awkScript
awkScript="$(
  cat <<'EOF'
.INCLUDE "$(dynamicSrcFile "_binaries/DbQueryAllDatabases/dbQueryAllDatabases.awk")"

EOF
)"

# @require Linux::requireExecutedAsUser
run() {

  # check dependencies
  Assert::commandExists mysql "sudo apt-get install -y mysql-client"
  Assert::commandExists mysqlshow "sudo apt-get install -y mysql-client"
  Assert::commandExists parallel "sudo apt-get install -y parallel"
  Assert::commandExists gawk "sudo apt-get install -y gawk"
  Assert::commandExists awk "sudo apt-get install -y gawk"
  Version::checkMinimal "gawk" "--version" "5.0.1"


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
  echo "${allDbs}" |
    SHELL=$(type -p bash) parallel --eta --progress "${PARALLEL_OPTIONS[@]}" \
      "${embed_function_DbQueryOneDatabase}" |
    awk --source "${awkScript}" -
}

if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "1" ]]; then
  run &>/dev/null
else
  run
fi
