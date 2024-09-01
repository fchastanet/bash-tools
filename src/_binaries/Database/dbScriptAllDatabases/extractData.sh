#!/usr/bin/env bash

# extra parameters passed through dbScriptAllDatabases
# shellcheck disable=SC2154
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

if [[ "${LOG_FORMAT}" = "log" ]]; then
  Log::displayInfo "result available in '${logFile}'"
fi
