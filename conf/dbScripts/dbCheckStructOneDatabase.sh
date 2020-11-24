#!/usr/bin/env bash

############################################################
# INTERNAL USE ONLY
# USED BY bin/dbScriptAllDatabases
############################################################
if [[  "${USER}" = "root" ]]; then
    Log::displayError "The script must not be run as root"
    exit 1
fi

declare REMOTE="$1"
declare VERBOSE="$2"
declare outputDir="$3"
declare db="$4"

# load ckls-bootstrap
# shellcheck source=/bash-framework/_bootstrap.sh
source "${BASH_TOOLS_FOLDER}/vendor/bash-framework/_bootstrap.sh"

# ensure that Ctrl-C is trapped by this script and not sub mysql process
trap 'exit 130' INT

CONTAINER="${PROJECT_NAMESPACE}-${WEB_HOSTNAME}"
MYSQL_OPTIONS=""

if [[ "${REMOTE}" = "1" ]] ; then
    HOSTNAME="${REMOTE_MYSQL_HOSTNAME}"
    USER="${REMOTE_MYSQL_USER}"
    PASSWORD="${REMOTE_MYSQL_PASSWORD}"
    PORT="${REMOTE_MYSQL_PORT}"
else
    HOSTNAME="${MYSQL_HOSTNAME}"
    USER="${MYSQL_USER}"
    PASSWORD="${MYSQL_PASSWORD}"
    PORT="${MYSQL_PORT}"
fi

import bash-framework/Database
#initialize Database lib in order to use to docker
if which docker; then
    Database::setMysqlPrefix "docker exec -i ${CONTAINER}"
fi

declare repairScript="${outputDir}/checkStruct_${db}.sql"

Log::displayInfo "process db '${db}'"

# MYSQL_OPTIONS must have been exported by calling script
Database::setMysqlOptions "${MYSQL_OPTIONS}"

# errors will be shown on stderr, result on stdout
Database::ifDbInitialized "${HOSTNAME}" "${PORT}" "${USER}" "${PASSWORD}" "${db}" >/dev/null 2>/dev/null || {
    (>&2 Log::displayError "DB '${db}' is not initialized")
    exit 1
}

Log::displayInfo "check DB structure of '${db}'"
rm -f "${repairScript}" 2>/dev/null || true
checkStructParams="-u"${USER}" -p"${PASSWORD}" --host="${HOSTNAME}" --no-interaction --full-check --do-repair --repair-script-filename="${repairScript}""
if [[ "${VERBOSE}" = "1" ]]; then
    checkStructParams+=" -vv"
fi

let start=$(date +%s)
ret=0
error=$("${__rootSrcPath__}/bin/console" crossknowledge:database:check-struct ${checkStructParams} "${db}" 2>&1) || {
    ret=$?
}
let end=$(date +%s)
duration=$(( end - start ))

echo "$error"
Log::displayInfo "DB structure of '${db}' checked in ${duration}s"

if [[ "${ret}" != "0" ]]; then
    Log::displayError "error when checking DB structure of '${db}' : ${error}"
    exit 1
elif [[ "$(cat "${repairScript}" 2>/dev/null || echo -n "")" = "" ]]; then
    #rm -f "${repairScript}" 2>/dev/null
    Log::displaySuccess "DB structure of '${db}' is OK"
    exit 0
else
    Log::displayError "DB repair script : ${repairScript}"
    exit 1
fi