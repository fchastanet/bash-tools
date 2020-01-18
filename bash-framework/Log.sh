#!/usr/bin/env bash

#---
# @internal common log message
#---
__logMessage() {
    local levelMsg="$1"
    local msg="$2"
    local date

    date="$(date '+%Y-%m-%d %H:%M:%S')"

    if [[ -n "${levelMsg}" ]]; then
      levelMsg=" - ${levelMsg}"
    fi
    echo "${date}${levelMsg} - ${msg}" >> "${BASH_FRAMEWORK_LOG_FILE}"
}

__displayError() {
    local msg="ERROR - ${1}"
    (>&2 echo -e "${__ERROR_COLOR}${msg}${__RESET_COLOR}")
    Log::logError "${1}"
}

__displayWarning() {
    local msg="WARN  - ${1}"

    (>&2 echo -e "${__WARNING_COLOR}${msg}${__RESET_COLOR}")
    Log::logWarning "${1}"
}

__displayInfo() {
    local msg="INFO  - ${1}"
    (>&2 echo -e "${__INFO_COLOR}${msg}${__RESET_COLOR}")
    Log::logInfo "${1}"
}

__displayDebug() {
    local msg="DEBUG - ${1}"

    (>&2 echo -e "${__DEBUG_COLOR}${msg}${__RESET_COLOR}")
    Log::logDebug "${1}"
}

__displaySuccess() {
    local msg="${1}"
    (>&2 echo -e "${__SUCCESS_COLOR}${msg}${__RESET_COLOR}")
    Log::logSuccess "${1}"
}
