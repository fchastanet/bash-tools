#!/usr/bin/env bash

############################################################
# INTERNAL USE ONLY
# USED BY .dev/tools/dbScriptAllDatabases
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
# shellcheck source=.dev/vendor/bash-framework/_bootstrap.sh
source "$( cd "$( readlink -f "${BASH_SOURCE[0]%/*}/../.." )" && pwd )/vendor/bash-framework/_bootstrap.sh"

# ensure that Ctrl-C is trapped by this script and not sub mysql process
trap 'exit 130' INT

CURRENT_DIR=$( cd "$( readlink -f "${BASH_SOURCE[0]%/*}" )" && pwd )
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

declare repairPhpScript="${outputDir}/${db}_propelMigration.php"
declare repairSqlScript="${outputDir}/${db}_up.sql"
declare repairLog="${outputDir}/${db}.log"
declare dbNotInitializedFile="${outputDir}/${db}_NotInitialized.log"
declare dbOKFile="${outputDir}/${db}_OK.log"
declare PROPEL_OUTPUT_DIR="not created yet"

declare ERROR_TRAPPED=0
trapError() {
    local script="${BASH_SOURCE[1]#./}"
    local line="$1"
    Log::displayError "script error at ${script}(${line})"
    ERROR_TRAPPED=1
}
trap 'trapError $LINENO' ERR

trapExit() {
    local exitCode=$?
    local msg=""
    if [[ "${ERROR_TRAPPED}" = "1" || "${exitCode}" != "0" ]]; then
        msg="an error occurred, keeping temporary directory '${PROPEL_OUTPUT_DIR}'"
        Log::displayError "${msg}"
    else
        rm-Rf "${PROPEL_OUTPUT_DIR}" 2>/dev/null || true
    fi

    # close fd 3 if opened
    if [[ ! -z "${repairLogFd}" ]]; then
        exec {repairLogFd}>&-
    fi
    [[ ! -z "${msg}" ]] && echo "${msg}" >> "${repairLog}"

    exit ${exitCode}
}
trap "trapExit" EXIT

createRepairScript() {
    # MYSQL_OPTIONS must have been exported by calling script
    Database::setMysqlOptions "${MYSQL_OPTIONS}"

    # errors will be shown on stderr, result on stdout
    Database::ifDbInitialized "${HOSTNAME}" "${PORT}" "${USER}" "${PASSWORD}" "${db}" >/dev/null 2>/dev/null || {
        local msg="DB '${db}' is not initialized"
        Log::displayError "${msg}"
        echo "${msg}" > "${dbNotInitializedFile}"
        return 1
    }

    Log::displayInfo "check DB structure of '${db}'"

    # create unique and empty temp directory
    while : ; do
        PROPEL_OUTPUT_DIR=$(mktemp -d -t "${db}-$(date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXX")
        [[ -d  "${PROPEL_OUTPUT_DIR}" &&  -z "${PROPEL_OUTPUT_DIR}" ]] || break
    done

    let start=$(date +%s)

    cmd=""
    # these overrides are used by app/config/elms-conf.php
    cmd+="OVERRIDE_DATABASE_HOST="${HOSTNAME}" "
    cmd+="OVERRIDE_DATABASE_USER="${USER}" "
    cmd+="OVERRIDE_DATABASE_PASSWORD="${PASSWORD}" "
    cmd+="OVERRIDE_DATABASE_NAME="${db}" "
    # the propel output dir is overridden in app/config/config_remote.yml
    cmd+="SYMFONY__PROPEL__OUTPUT__DIR="${PROPEL_OUTPUT_DIR}" "
    cmd+=""${__rootSrcPath__}/bin/console" crossknowledge:migration:generate-diff "
    # to target app/config/config_remote.yml
    cmd+="--env=remote "
    if [[ "${VERBOSE}" = "1" ]]; then
        cmd+=" -vvv"
    else
        # verbosity normal only for logging
        cmd+=" -v"
    fi

    msg="execute command : ${cmd}"
    if [[ "${VERBOSE}" = "1" ]]; then
        Log::displayInfo "${msg}"
    else
        echo "${msg}" >&${repairLogFd}
    fi
    declare ret="0"
    error=$(eval "${cmd}" 2>&1) || { ret="$?"; } || true
    let end=$(date +%s)
    duration=$(( end - start ))
    if [[ "${VERBOSE}" = "1" ]]; then
        echo "${error}"
    else
        echo "${error}" >&${repairLogFd}
    fi
    Log::displayInfo "DB structure of '${db}' checked in ${duration}s"

    if [[ "${ret}" != "0" ]]; then
        Log::displayError "error when checking DB structure of '${db}' : see ${repairLog} file for details"
        return 1
    fi

    # does propel file generated ?
    PROPEL_FILE_PATTERN="${PROPEL_OUTPUT_DIR}/PropelMigration_*.php"
    if ls ${PROPEL_FILE_PATTERN} 1> /dev/null 2>&1; then
        Log::displayError "DB repair script : ${repairPhpScript}"
        cp ${PROPEL_FILE_PATTERN} "${repairPhpScript}" || {
            Log::displayError "invalid pattern ? ${PROPEL_FILE_PATTERN}"
            return 1
        }
        # extract up sql part
        tail -n +45 "${repairPhpScript}" | sed '/public function getDownSQL/q' | head -n -13 | sed -e "s/[\\]'/'/g" | cat > "${repairSqlScript}"
        if [[ ! -f "${repairSqlScript}" ]]; then
            Log::displayWarning "Unable to create ${repairSqlScript}"
        fi
    else
        Log::displaySuccess "DB structure of '${db}' is OK"
        echo "DB structure of '${db}' checked in ${duration}s" > "${dbOKFile}"
    fi
}

Log::displayInfo "process db '${db}'"

if [[ -f "${dbNotInitializedFile}" ]]; then
    Log::displayWarning "db '${db}' skipped as marked as not initialized, file '${dbNotInitializedFile}' exists"
elif [[ -f "${repairPhpScript}" && -f "${repairSqlScript}" ]]; then
    Log::displayWarning "db '${db}' skipped as repair script file '${repairPhpScript}' already exists"
else
    # remove eventually existing repair log
    rm -f "${repairLog}" 2>/dev/null || true
    # open file descriptor for writing to repairLog
    exec {repairLogFd}>${repairLog}

    createRepairScript 2>&1 > >( tee -a >(cat - | sed -r -e "s/\x1B\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g" >&${repairLogFd}) )

    exit $?
fi