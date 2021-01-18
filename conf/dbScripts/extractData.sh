#!/usr/bin/env bash

# shellcheck source=bin/_dbScriptOneDatabase.sh
source "$6/bin/_dbScriptOneDatabase.sh"

if [[ -z "${scriptParameters[0]}" ]]; then
    Log::fatal "query string or file not provided"
fi

# extra parameters passed through dbScriptAllDatabases
declare query="${scriptParameters[0]}"
declare queryName="customQuery"
declare queryFile="${query}"
queryFile="$(Functions::getAbsoluteConfFile "dbQueries" "${queryFile}" "sql" 2>/dev/null|| echo "")"
if [ -n "${queryFile}" ]; then
    queryName="$(basename "${queryFile%.*}")"
    query="$(cat "${queryFile}")"
fi

# create log file
declare logFile=""
if [[ "${LOG_FORMAT}" = "log" ]]; then
    declare logFile="${outputDir}/${db}_${queryName}.log" 
    exec 6>&1 1> "${logFile}" # redirect stdout to logfile 
fi

Database::skipColumnNames dbInstance 0
Database::query dbInstance "${query}" "${db}" || true
Database::skipColumnNames dbInstance 1

if [[ "${LOG_FORMAT}" = "log" ]]; then
    # restore stdout
    exec 1>&6 6>&-
fi

[[ "${LOG_FORMAT}" = "log" ]] && Log::displayInfo "result available in '${logFile}'"
