#!/usr/bin/env bash

# shellcheck source=bash-framework/Constants.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/Constants.sh" || exit 1

assertDisplayLogs() {
    local displayLevel=$1

    local debugMsg=$(Log::displayDebug "debug" 2>&1)
    local expectedDebugMsg="$(echo -e "${__DEBUG_COLOR}DEBUG - debug${__RESET_COLOR}")"
    local infoMsg=$(Log::displayInfo "info" 2>&1)
    local expectedInfoMsg="$(echo -e "${__INFO_COLOR}INFO  - info${__RESET_COLOR}")"
    local successMsg=$(Log::displaySuccess "success" 2>&1)
    local expectedSuccessMsg="$(echo -e "${__SUCCESS_COLOR}success${__RESET_COLOR}")"
    local warningMsg=$(Log::displayWarning "warning" 2>&1)
    local expectedWarningMsg="$(echo -e "${__WARNING_COLOR}WARN  - warning${__RESET_COLOR}")"
    local errorMsg=$(Log::displayError "error" 2>&1)
    local expectedErrorMsg="$(echo -e "${__ERROR_COLOR}ERROR - error${__RESET_COLOR}")"

    if (( displayLevel == __LEVEL_OFF )); then
        [[
          -z "${debugMsg}" &&
          -z "${infoMsg}" &&
          -z "${successMsg}" &&
          -z "${warningMsg}" &&
          -z "${errorMsg}"
        ]] && return 0
    elif (( displayLevel == __LEVEL_DEBUG )); then
        [[
          "${debugMsg}" == "${expectedDebugMsg}" &&
          "${infoMsg}" == "${expectedInfoMsg}" &&
          "${successMsg}" == "${expectedSuccessMsg}" &&
          "${warningMsg}" == "${expectedWarningMsg}" &&
          "${errorMsg}" == "${expectedErrorMsg}"
        ]] && return 0
    elif (( displayLevel == __LEVEL_INFO )); then
        [[
          -z "${debugMsg}" &&
          "${infoMsg}" == "${expectedInfoMsg}" &&
          "${successMsg}" == "${expectedSuccessMsg}" &&
          "${warningMsg}" == "${expectedWarningMsg}" &&
          "${errorMsg}" == "${expectedErrorMsg}"
        ]] && return 0
    elif (( displayLevel == __LEVEL_SUCCESS )); then
        [[
            -z "${debugMsg}" &&
            "${infoMsg}" == "${expectedInfoMsg}" &&
            "${successMsg}" == "${expectedSuccessMsg}" &&
            "${warningMsg}" == "${expectedWarningMsg}" &&
            "${errorMsg}" == "${expectedErrorMsg}"
        ]] && return 0
    elif (( displayLevel == __LEVEL_WARNING )); then
        [[
            -z "${debugMsg}"  &&
            -z "${infoMsg}"  &&
            -z "${successMsg}"  &&
            "${warningMsg}" == "${expectedWarningMsg}"  &&
            "${errorMsg}" == "${expectedErrorMsg}"
        ]] && return 0
    elif (( displayLevel == __LEVEL_ERROR )); then
        [[
            -z "${debugMsg}" &&
            -z "${infoMsg}" &&
            -z "${successMsg}" &&
            -z "${warningMsg}" &&
            "${errorMsg}" == "${expectedErrorMsg}"
        ]]  && return 0
    fi
    return 1
}

@test "Log::displayDebug activated with envfile" {
    BASH_FRAMEWORK_INITIALIZED=0  __bash_framework_envFile="${BATS_TEST_DIRNAME}/data/Log.debug.env" source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertDisplayLogs ${__LEVEL_DEBUG}
    [[ "${status}" == "0" ]]
}

@test "Log::displayDebug activated with env var" {
    BASH_FRAMEWORK_INITIALIZED=0 BASH_FRAMEWORK_DISPLAY_LEVEL=${__LEVEL_DEBUG} source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertDisplayLogs ${__LEVEL_DEBUG}
    [[ "${status}" == "0" ]]
}

@test "Log::displayInfo activated with envfile" {
    BASH_FRAMEWORK_INITIALIZED=0  __bash_framework_envFile="${BATS_TEST_DIRNAME}/data/Log.info.env" source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertDisplayLogs ${__LEVEL_INFO}
    [[ "${status}" == "0" ]]
}

@test "Log::displayInfo activated with env var" {
    BASH_FRAMEWORK_INITIALIZED=0 BASH_FRAMEWORK_DISPLAY_LEVEL=${__LEVEL_INFO} source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertDisplayLogs ${__LEVEL_INFO}
    [[ "${status}" == "0" ]]
}

@test "Log::displaySuccess activated with envfile" {
    BASH_FRAMEWORK_INITIALIZED=0  __bash_framework_envFile="${BATS_TEST_DIRNAME}/data/Log.success.env" source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertDisplayLogs ${__LEVEL_SUCCESS}
    [[ "${status}" == "0" ]]
}

@test "Log::displaySuccess activated with env var" {
    BASH_FRAMEWORK_INITIALIZED=0 BASH_FRAMEWORK_DISPLAY_LEVEL=${__LEVEL_SUCCESS} source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertDisplayLogs ${__LEVEL_SUCCESS}
    [[ "${status}" == "0" ]]
}

@test "Log::displayWarning activated with envfile" {
    BASH_FRAMEWORK_INITIALIZED=0  __bash_framework_envFile="${BATS_TEST_DIRNAME}/data/Log.warning.env" source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertDisplayLogs ${__LEVEL_WARNING}
    [[ "${status}" == "0" ]]
}

@test "Log::displayWarning activated with env var" {
    BASH_FRAMEWORK_INITIALIZED=0 BASH_FRAMEWORK_DISPLAY_LEVEL=${__LEVEL_WARNING} source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertDisplayLogs ${__LEVEL_WARNING}
    [[ "${status}" == "0" ]]
}

@test "Log::displayError activated with envfile" {
    BASH_FRAMEWORK_INITIALIZED=0  __bash_framework_envFile="${BATS_TEST_DIRNAME}/data/Log.error.env" source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertDisplayLogs ${__LEVEL_ERROR}
    [[ "${status}" == "0" ]]
}

@test "Log::displayError activated with env var" {
    BASH_FRAMEWORK_INITIALIZED=0 BASH_FRAMEWORK_DISPLAY_LEVEL=${__LEVEL_ERROR} source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertDisplayLogs ${__LEVEL_ERROR}
    [[ "${status}" == "0" ]]
}

@test "display off with env file" {
    BASH_FRAMEWORK_INITIALIZED=0  __bash_framework_envFile="${BATS_TEST_DIRNAME}/data/Log.off.env" source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertDisplayLogs ${__LEVEL_OFF}
    [[ "${status}" == "0" ]]
}

@test "display off with env var" {
    BASH_FRAMEWORK_INITIALIZED=0 BASH_FRAMEWORK_DISPLAY_LEVEL=${__LEVEL_OFF} source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertDisplayLogs ${__LEVEL_OFF}
    [[ "${status}" == "0" ]]
}
