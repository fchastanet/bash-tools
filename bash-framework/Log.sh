#!/usr/bin/env bash

#---
# @internal common log message
#---
__logMessage() {
    local msg="$1"
    local date

    date="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "${date} - ${msg}" >> "${BASH_FRAMEWORK_LOG_FILE}"
}

__displayError() {
    local msg="ERROR - ${1}"
    (>&2 echo -e "${__ERROR_COLOR}${msg}${__RESET_COLOR}")
    Log::logError "${msg}"
}

__displayWarning() {
    local msg="WARN  - ${1}"

    (>&2 echo -e "${__WARNING_COLOR}${msg}${__RESET_COLOR}")
    Log::logWarning "${msg}"
}

__displayInfo() {
    local msg="INFO  - ${1}"
    (>&2 echo -e "${__INFO_COLOR}${msg}${__RESET_COLOR}")
    Log::logInfo "${msg}"
}

__displayDebug() {
    local msg="DEBUG - ${1}"

    (>&2 echo -e "${__DEBUG_COLOR}${msg}${__RESET_COLOR}")
    Log::logDebug "${msg}"
}

__displaySuccess() {
    local msg="${1}"
    (>&2 echo -e "${__SUCCESS_COLOR}${msg}${__RESET_COLOR}")
    Log::logSuccess "${msg}"
}
