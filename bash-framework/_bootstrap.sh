#!/usr/bin/env bash

# inspired by https://github.com/niieani/bash-oo-framework

# shellcheck disable=2155
declare -g __bash_framework_rootLibPath="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
# shellcheck disable=2155
declare -g __bash_framework_rootCallingScriptPath="$( cd "$(dirname "$0")" && pwd )"
# shellcheck disable=2155,2034
declare -g __bash_framework_rootVendorPath="$( cd "${__bash_framework_rootLibPath}/.." && pwd )"

## stubs in case either exception or log is not loaded
Log::displayError() {
    echo "Error: $1" 1>&2
}

# shellcheck source=bash-framework/Framework.sh
source "${__bash_framework_rootLibPath}/Framework.sh" || {
    Log::displayError "FATAL ERROR: Unable to bootstrap (missing bash-fraemwork directory?)"
    exit 1
}
# shellcheck source=bash-framework/Array.sh
source "${__bash_framework_rootLibPath}/Array.sh" || {
    Log::displayError "FATAL ERROR: Unable to bootstrap (missing lib directory?)"
    exit 1
}

#---
## Initialize some default variables
## List of variables
## * BASH_FRAMEWORK_INITIALIZED=1 lazy initialization
## * BASH_FRAMEWORK_DISPLAY_LEVEL(default value: __LEVEL_INFO)
## * BASH_FRAMEWORK_LOG_LEVEL(default value: __LEVEL_OFF)
## * BASH_FRAMEWORK_LOG_FILE(default value: ""}
##
## all these variables can be overridden by a .env file that will be searched in the following directories
## in this order (stop on first file found):
## * __bash_framework_rootCallingScriptPath: upper directory
## * ~ : home path
## alternatively you can force a given .env file to be loaded using
## __bash_framework_envFile=<fullPathToEnvFile or empty if no file to be loaded>
#---
Framework::bootstrap() {
    if [[ "${BASH_FRAMEWORK_INITIALIZED:-0}" = "1" ]]; then
        return
    fi

    # default values
    BASH_FRAMEWORK_DISPLAY_LEVEL=${__LEVEL_INFO}
    BASH_FRAMEWORK_LOG_LEVEL=${__LEVEL_OFF}
    BASH_FRAMEWORK_LOG_FILE=""

    # import .env file
    set -o allexport
    if [[ -z "${__bash_framework_envFile+xxx}" ]]; then
        # __bash_framework_envFile not defined
        if [ -f "${__bash_framework_rootCallingScriptPath}/.env" ]; then
            source "${__bash_framework_rootCallingScriptPath}/.env" || exit 1
        elif [ -f "${HOME}/.env" ]; then
            # shellcheck source=~/.env
            source "${HOME}/.env" || exit 1
        fi
    elif [[ -z "${__bash_framework_envFile}" ]]; then
        # __bash_framework_envFile defined but empty - nothing to do
        true
    else
        # load __bash_framework_envFile
        [[ ! -f "${__bash_framework_envFile}" ]] && {
            Log::displayError "env file not not found - ${__bash_framework_envFile}"
            exit 1
        }
        source "${__bash_framework_envFile}"
    fi

    if (( ${BASH_FRAMEWORK_LOG_LEVEL} > ${__LEVEL_OFF} )); then
        if [[ -z "${BASH_FRAMEWORK_LOG_FILE}" ]]; then
            Log::displayError "BASH_FRAMEWORK_LOG_FILE - log file not specified"
        else
            if ! touch --no-create "${BASH_FRAMEWORK_LOG_FILE}" ; then
                Log::displayError "Log file ${__bash_framework_rootCallingScriptPath}/${BASH_FRAMEWORK_LOG_FILE} is not writable"
                BASH_FRAMEWORK_LOG_LEVEL=${__LEVEL_OFF}
            fi
        fi
    fi

    set +o allexport

    BASH_FRAMEWORK_INITIALIZED=1
}

shopt -s expand_aliases
alias import="__bash_framework__allowFileReloading=false Framework::Import"
alias source="__bash_framework__allowFileReloading=true Framework::ImportOne"
alias .="__bash_framework__allowFileReloading=true Framework::ImportOne"

#########################
### INITIALIZE SYSTEM ###
#########################
import bash-framework/Log
import bash-framework/Functions

# Bash will remember & return the highest exit code in a chain of pipes.
# This way you can catch the error inside pipes, e.g. mysqldump | gzip
set -o pipefail
set -o errexit
# use nullglob so that (file*.php) will return an empty array if no file matches the wildcard
shopt -s nullglob
# a log is generated when a command fails
set -o errtrace

export TERM=xterm-256color

Framework::bootstrap
