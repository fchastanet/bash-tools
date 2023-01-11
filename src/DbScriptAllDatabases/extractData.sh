#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/conf/dbScripts/extractData
# ROOT_DIR_RELATIVE_TO_BIN_DIR=../..

.INCLUDE "${TEMPLATE_DIR}/_includes/dbScriptOneDatabase.sh"

HELP="$(
  cat <<EOF
${__HELP_TITLE}Description:${__HELP_NORMAL} example script file that can
be used by bin/dbScriptAllDatabases

.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/author.tpl"
EOF
)"
Args::defaultHelp "${HELP}" "$@"

# shellcheck disable=SC2154
if [[ -z "${scriptParameters[0]}" ]]; then
  Log::fatal "query string or file not provided"
fi

# extra parameters passed through dbScriptAllDatabases
declare query="${scriptParameters[0]}"
declare queryName="customQuery"
declare queryFile="${query}"
queryFile="$(Conf::getAbsoluteFile "dbQueries" "${queryFile}" "sql" 2>/dev/null || echo "")"
if [[ -n "${queryFile}" ]]; then
  queryName="$(basename "${queryFile%.*}")"
  query="$(cat "${queryFile}")"
fi

# create log file
declare logFile=""
if [[ "${LOG_FORMAT}" = "log" ]]; then
  # shellcheck disable=SC2154
  declare logFile="${outputDir}/${db}_${queryName}.log"
  exec 6>&1 1>"${logFile}" # redirect stdout to logFile
fi

Database::skipColumnNames dbInstance 0
Database::query dbInstance "${query}" "${db}" || true
Database::skipColumnNames dbInstance 1

if [[ "${LOG_FORMAT}" = "log" ]]; then
  # restore stdout
  exec 1>&6 6>&-
fi

[[ "${LOG_FORMAT}" = "log" ]] && Log::displayInfo "result available in '${logFile}'"
