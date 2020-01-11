#!/usr/bin/env bash

# log level constants
readonly __LEVEL_OFF=0
readonly __LEVEL_ERROR=1
readonly __LEVEL_WARNING=2
readonly __LEVEL_INFO=3
readonly __LEVEL_SUCCESS=3
readonly __LEVEL_DEBUG=4

# check colors applicable https://misc.flogisoft.com/bash/tip_colors_and_formatting
readonly __ERROR_COLOR='\e[31m'           # Red
readonly __INFO_COLOR='\e[44m'            # white on lightBlue
readonly __SUCCESS_COLOR='\e[32m'         # Green
readonly __WARNING_COLOR='\e[33m'         # Yellow
readonly __DEBUG_COLOR='\e[37m'           # Grey
readonly __RESET_COLOR='\e[0m'            # Reset Color

Log::displayError() {
    local msg="ERROR - ${1}"
    if (( ${BASH_FRAMEWORK_DISPLAY_LEVEL} >= ${__LEVEL_ERROR} )); then
        echo -e "${__ERROR_COLOR}${msg}${__RESET_COLOR}"
    fi
    Log::logMessage ${__LEVEL_ERROR} "${msg}"
}

Log::displayWarning() {
    local msg="WARN  - ${1}"
    if (( ${BASH_FRAMEWORK_DISPLAY_LEVEL} >= ${__LEVEL_WARNING} )); then
        echo -e "${__WARNING_COLOR}${msg}${__RESET_COLOR}"
    fi
    Log::logMessage ${__LEVEL_WARNING} "${msg}"
}

Log::displayInfo() {
    local msg="INFO  - ${1}"
    if (( ${BASH_FRAMEWORK_DISPLAY_LEVEL} >= ${__LEVEL_INFO} )); then
        echo -e "${__INFO_COLOR}${msg}${__RESET_COLOR}"
    fi
    Log::logMessage ${__LEVEL_INFO} "${msg}"
}

Log::displaySuccess() {
    local msg="${1}"
    echo -e "${__SUCCESS_COLOR}${msg}${__RESET_COLOR}"
    Log::logMessage ${__LEVEL_SUCCESS} "${msg}"
}


Log::displayDebug() {
    local msg="DEBUG - ${1}"

    if (( ${BASH_FRAMEWORK_DISPLAY_LEVEL} >= ${__LEVEL_DEBUG} )); then
        echo -e "${__DEBUG_COLOR}${msg}${__RESET_COLOR}"
    fi
    Log::logMessage ${__LEVEL_DEBUG} "${msg}"
}

Log::logMessage() {
    local minLogLevel=$1
    local msg="$2"
    local date

    if (( ${BASH_FRAMEWORK_LOG_LEVEL} >= ${minLogLevel} )); then
        date="$(date '+%Y-%m-%d %H:%M:%S')"
        echo "${date} - ${msg}" >> "${BASH_FRAMEWORK_LOG_FILE}"
    fi
}
