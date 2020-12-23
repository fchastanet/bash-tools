#!/usr/bin/env bash

# Internal: common log message
#
# **Arguments**:
# * $1 - message's level description
# * $2 - messsage
# **Output**:
# if levelMsg empty
# [date] - message
# else
# [date] - [levelMsg] - message
#
# **Examples**:
# <pre>
# 2020-01-19 19:20:21 - ERROR   - log message
# </pre>
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

# Public: display fatal message on stderr
#
# **Arguments**:
# * $1 - messsage
# **Output**: using fatal color
# ERROR - message
__displayFatal() {
    local msg="FATAL - ${1}"
    (>&2 echo -e "${__FATAL_COLOR}${msg}${__RESET_COLOR}")
    Log::logError "${1}"
}

# Public: display error message on stderr
#
# **Arguments**:
# * $1 - messsage
# **Output**: using error color
# ERROR - message
__displayError() {
    local msg="ERROR - ${1}"
    (>&2 echo -e "${__ERROR_COLOR}${msg}${__RESET_COLOR}")
    Log::logError "${1}"
}

# Public: display warning message on stderr
#
# **Arguments**:
# * $1 - messsage
# **Output**: using warning color
# WARN - message
__displayWarning() {
    local msg="WARN  - ${1}"

    (>&2 echo -e "${__WARNING_COLOR}${msg}${__RESET_COLOR}")
    Log::logWarning "${1}"
}

# Public: display info message on stderr
#
# **Arguments**:
# * $1 - messsage
# **Output**: using info color
# INFO - message
__displayInfo() {
    local msg="INFO  - ${1}"
    (>&2 echo -e "${__INFO_COLOR}${msg}${__RESET_COLOR}")
    Log::logInfo "${1}"
}

# Public: display debug message on stderr
#
# **Arguments**:
# * $1 - messsage
# **Output**: using debug color
# DEBUG - message
__displayDebug() {
    local msg="DEBUG - ${1}"

    (>&2 echo -e "${__DEBUG_COLOR}${msg}${__RESET_COLOR}")
    Log::logDebug "${1}"
}

# Public: display success message on stderr
#
# **Arguments**:
# * $1 - messsage
# **Output**: using success color
# message
__displaySuccess() {
    local msg="${1}"
    (>&2 echo -e "${__SUCCESS_COLOR}${msg}${__RESET_COLOR}")
    Log::logSuccess "${1}"
}
