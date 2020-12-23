#!/usr/bin/env bash

# inspired by https://github.com/niieani/bash-oo-framework

shopt -s expand_aliases

# shellcheck disable=2155
declare -g __bash_framework_rootLibPath="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
# shellcheck disable=2155
declare -g __bash_framework_rootCallingScriptPath="$( cd "$(dirname "$0")" && pwd )"
# shellcheck disable=2155,2034
declare -g __bash_framework_rootVendorPath="$( cd "${__bash_framework_rootLibPath}/.." && pwd )"

## stubs in case either exception or log is not loaded
Log::fatal() {
  (>&2 echo "FATAL  : $1")
  exit 1
}

# shellcheck source=bash-framework/Constants.sh
source "${__bash_framework_rootLibPath}/Constants.sh" || 
    Log::fatal "Unable to bootstrap (missing lib directory?)"

# shellcheck source=bash-framework/Framework.sh
source "${__bash_framework_rootLibPath}/Framework.sh" || 
    Log::fatal "Unable to bootstrap (missing bash-framework directory?)"

# shellcheck source=bash-framework/Array.sh
source "${__bash_framework_rootLibPath}/Array.sh" || 
    Log::fatal "Unable to bootstrap (missing lib directory?)"

shopt -s expand_aliases
alias import="__bash_framework__allowFileReloading=false Framework::Import"
alias source="__bash_framework__allowFileReloading=true Framework::ImportOne"
alias .="__bash_framework__allowFileReloading=true Framework::ImportOne"

#---
## Initialize some default variables
## List of variables
## * BASH_FRAMEWORK_INITIALIZED=1 lazy initialization
## * BASH_FRAMEWORK_DISPLAY_LEVEL(default value: __LEVEL_INFO)
## * BASH_FRAMEWORK_LOG_LEVEL(default value: __LEVEL_OFF)
## * BASH_FRAMEWORK_LOG_FILE(default value: ""}
##
## default conf/.env file is loaded
## 
## then all these variables can be overridden by a .env file that will be searched in the following directories
## in this order (stop on first file found):
## * __bash_framework_rootCallingScriptPath: upper directory
## * ~/ : home path
## * ~/.bash-tools : home path .bash-tools
## alternatively you can force a given .env file to be loaded using
## __bash_framework_envFile=<fullPathToEnvFile or empty if no file to be loaded>
#---
Framework::bootstrap() {
    if [[ "${BASH_FRAMEWORK_INITIALIZED:-0}" = "1" ]]; then
        return
    fi

    # default values
    # shellcheck disable=SC2034
    BASH_FRAMEWORK_DISPLAY_LEVEL=${BASH_FRAMEWORK_DISPLAY_LEVEL:-${__LEVEL_INFO}}
    # shellcheck disable=SC2034
    BASH_FRAMEWORK_LOG_LEVEL=${BASH_FRAMEWORK_LOG_LEVEL:-${__LEVEL_OFF}}
    # shellcheck disable=SC2034
    BASH_FRAMEWORK_LOG_FILE="${BASH_FRAMEWORK_LOG_FILE:-${BASH_FRAMEWORK_LOG_FILE}}"

    # import default .env file
    # shellcheck source=/conf/.env
    source "${__bash_framework_rootVendorPath}/conf/.env" || exit 1

    # import custom .env file
    if [[ -z "${__bash_framework_envFile+xxx}" ]]; then
        # __bash_framework_envFile not defined
        if [[ -f "${__bash_framework_rootCallingScriptPath}/.env" ]]; then
            source "${__bash_framework_rootCallingScriptPath}/.env" || exit 1
        elif [[ -f "${HOME}/.env" ]]; then
            # shellcheck source=~/.env
            source "${HOME}/.env" || exit 1
        elif [[ -f "${HOME}/.bash-tools/.env" ]]; then
            # shellcheck source=~/.bash-tools/.env
            source "${HOME}/.bash-tools/.env" || exit 1
        fi
    elif [[ -z "${__bash_framework_envFile}" ]]; then
        # __bash_framework_envFile defined but empty - nothing to do
        true
    else
        # load __bash_framework_envFile
        [[ ! -f "${__bash_framework_envFile}" ]] && 
            Log::fatal "env file not not found - ${__bash_framework_envFile}"
        source "${__bash_framework_envFile}"
    fi

    source bash-framework/LogBootstrap

    set +o allexport

    BASH_FRAMEWORK_INITIALIZED=1
}

#########################
### INITIALIZE SYSTEM ###
#########################
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

import bash-framework/Functions
import bash-framework/Log
