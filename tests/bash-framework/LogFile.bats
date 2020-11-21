#!/usr/bin/env bash

# shellcheck source=bash-framework/Constants.sh
source "$(cd "$( readlink -f "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/Constants.sh" || exit 1

declare -g logFile
setup() {
  logFile="$(mktemp -p "${TMPDIR:-/tmp}" -t "bash.framework.XXXXXXXXXXXX")"
}

teardown() {
  rm -f "${logFile}" || true
}

assertFileLogs() {
    local logLevel=$1

    dateMocked() {
        echo "dateMocked"
    }
    alias date='dateMocked'

    >"${logFile}"

    local expectedDebugMsg="dateMocked - DEBUG   - debug"
    Log::logDebug "debug"
    local debugMsg="$(cat "${logFile}")"
    > "${logFile}"

    local expectedInfoMsg="dateMocked - INFO    - info"
    Log::logInfo "info"
    local infoMsg="$(cat "${logFile}")"
    > "${logFile}"

    Log::logSuccess "success"
    local expectedSuccessMsg="dateMocked - SUCCESS - success"
    local successMsg="$(cat "${logFile}")"
    > "${logFile}"

    Log::logWarning "warning"
    local expectedWarningMsg="dateMocked - WARNING - warning"
    local warningMsg="$(cat "${logFile}")"
    > "${logFile}"

    Log::logError "error"
    local expectedErrorMsg="dateMocked - ERROR   - error"
    local errorMsg="$(cat "${logFile}")"
    > "${logFile}"

    if (( logLevel == __LEVEL_OFF )); then
        [[
          -z "${debugMsg}" &&
          -z "${infoMsg}" &&
          -z "${successMsg}" &&
          -z "${warningMsg}" &&
          -z "${errorMsg}"
        ]] && return 0
    elif (( logLevel == __LEVEL_DEBUG )); then
        [[
          "${debugMsg}" == "${expectedDebugMsg}" &&
          "${infoMsg}" == "${expectedInfoMsg}" &&
          "${successMsg}" == "${expectedSuccessMsg}" &&
          "${warningMsg}" == "${expectedWarningMsg}" &&
          "${errorMsg}" == "${expectedErrorMsg}"
        ]] && return 0
    elif (( logLevel == __LEVEL_INFO )); then
        [[
          -z "${debugMsg}" &&
          "${infoMsg}" == "${expectedInfoMsg}" &&
          "${successMsg}" == "${expectedSuccessMsg}" &&
          "${warningMsg}" == "${expectedWarningMsg}" &&
          "${errorMsg}" == "${expectedErrorMsg}"
        ]] && return 0
    elif (( logLevel == __LEVEL_SUCCESS )); then
        [[
            -z "${debugMsg}" &&
            "${infoMsg}" == "${expectedInfoMsg}" &&
            "${successMsg}" == "${expectedSuccessMsg}" &&
            "${warningMsg}" == "${expectedWarningMsg}" &&
            "${errorMsg}" == "${expectedErrorMsg}"
        ]] && return 0
    elif (( logLevel == __LEVEL_WARNING )); then
        [[
            -z "${debugMsg}"  &&
            -z "${infoMsg}"  &&
            -z "${successMsg}"  &&
            "${warningMsg}" == "${expectedWarningMsg}"  &&
            "${errorMsg}" == "${expectedErrorMsg}"
        ]] && return 0
    elif (( logLevel == __LEVEL_ERROR )); then
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

@test "Log::log... log file not specified" {
    BASH_FRAMEWORK_LOG_FILE="" BASH_FRAMEWORK_INITIALIZED=0  __bash_framework_envFile="${BATS_TEST_DIRNAME}/data/Log.debug.env" source "$(cd "$( readlink -f "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1
    [[ "${BASH_FRAMEWORK_LOG_LEVEL}" == "${__LEVEL_OFF}" ]]
}

@test "Log::log... log file not writable" {
    chmod 400 "${logFile}"
    BASH_FRAMEWORK_LOG_FILE="" BASH_FRAMEWORK_INITIALIZED=0  __bash_framework_envFile="${BATS_TEST_DIRNAME}/data/Log.debug.env" source "$(cd "$( readlink -f "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1
    [[ "${BASH_FRAMEWORK_LOG_LEVEL}" == "${__LEVEL_OFF}" ]]
}

@test "Log::logDebug activated with envfile" {
    BASH_FRAMEWORK_LOG_FILE="${logFile}"
    BASH_FRAMEWORK_INITIALIZED=0  __bash_framework_envFile="${BATS_TEST_DIRNAME}/data/Log.debug.env" source "$(cd "$( readlink -f "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1

    assertFileLogs ${__LEVEL_DEBUG}
    [[ "$?" == "0" ]]
}

@test "Log::logDebug activated with env var" {
    BASH_FRAMEWORK_LOG_FILE="${logFile}"
    BASH_FRAMEWORK_INITIALIZED=0 BASH_FRAMEWORK_LOG_LEVEL=${__LEVEL_DEBUG} source "$(cd "$( readlink -f "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1
    assertFileLogs ${__LEVEL_DEBUG}
    [[ "$?" == "0" ]]
}

@test "Log::logInfo activated with envfile" {
    BASH_FRAMEWORK_LOG_FILE="${logFile}"
    BASH_FRAMEWORK_INITIALIZED=0  __bash_framework_envFile="${BATS_TEST_DIRNAME}/data/Log.info.env" source "$(cd "$( readlink -f "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertFileLogs ${__LEVEL_INFO}
    [[ "$?" == "0" ]]
}

@test "Log::logInfo activated with env var" {
    BASH_FRAMEWORK_LOG_FILE="${logFile}"
    BASH_FRAMEWORK_INITIALIZED=0 BASH_FRAMEWORK_DISPLAY_LEVEL=${__LEVEL_INFO} source "$(cd "$( readlink -f "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertFileLogs ${__LEVEL_INFO}
    [[ "$?" == "0" ]]
}

@test "Log::logSuccess activated with envfile" {
    BASH_FRAMEWORK_LOG_FILE="${logFile}"
    BASH_FRAMEWORK_INITIALIZED=0  __bash_framework_envFile="${BATS_TEST_DIRNAME}/data/Log.success.env" source "$(cd "$( readlink -f "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertFileLogs ${__LEVEL_SUCCESS}
    [[ "$?" == "0" ]]
}

@test "Log::logSuccess activated with env var" {
    BASH_FRAMEWORK_LOG_FILE="${logFile}"
    BASH_FRAMEWORK_INITIALIZED=0 BASH_FRAMEWORK_DISPLAY_LEVEL=${__LEVEL_SUCCESS} source "$(cd "$( readlink -f "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertFileLogs ${__LEVEL_SUCCESS}
    [[ "$?" == "0" ]]
}

@test "Log::logWarning activated with envfile" {
    BASH_FRAMEWORK_LOG_FILE="${logFile}"
    BASH_FRAMEWORK_INITIALIZED=0  __bash_framework_envFile="${BATS_TEST_DIRNAME}/data/Log.warning.env" source "$(cd "$( readlink -f "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertFileLogs ${__LEVEL_WARNING}
    [[ "$?" == "0" ]]
}

@test "Log::logWarning activated with env var" {
    BASH_FRAMEWORK_LOG_FILE="${logFile}"
    BASH_FRAMEWORK_INITIALIZED=0 BASH_FRAMEWORK_DISPLAY_LEVEL=${__LEVEL_WARNING} source "$(cd "$( readlink -f "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertFileLogs ${__LEVEL_WARNING}
    [[ "$?" == "0" ]]
}

@test "Log::logError activated with envfile" {
    BASH_FRAMEWORK_LOG_FILE="${logFile}"
    BASH_FRAMEWORK_INITIALIZED=0  __bash_framework_envFile="${BATS_TEST_DIRNAME}/data/Log.error.env" source "$(cd "$( readlink -f "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertFileLogs ${__LEVEL_ERROR}
    [[ "$?" == "0" ]]
}

@test "Log::logError activated with env var" {
    BASH_FRAMEWORK_LOG_FILE="${logFile}"
    BASH_FRAMEWORK_INITIALIZED=0 BASH_FRAMEWORK_DISPLAY_LEVEL=${__LEVEL_ERROR} source "$(cd "$( readlink -f "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertFileLogs ${__LEVEL_ERROR}
    [[ "$?" == "0" ]]
}

@test "log off with env file" {
    BASH_FRAMEWORK_LOG_FILE="${logFile}"
    BASH_FRAMEWORK_INITIALIZED=0  __bash_framework_envFile="${BATS_TEST_DIRNAME}/data/Log.off.env" source "$(cd "$( readlink -f "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertFileLogs ${__LEVEL_OFF}
    [[ "$?" == "0" ]]
}

@test "log off with env var" {
    BASH_FRAMEWORK_LOG_FILE="${logFile}"
    BASH_FRAMEWORK_INITIALIZED=0 BASH_FRAMEWORK_DISPLAY_LEVEL=${__LEVEL_OFF} source "$(cd "$( readlink -f "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1
    run assertFileLogs ${__LEVEL_OFF}
    [[ "$?" == "0" ]]
}
