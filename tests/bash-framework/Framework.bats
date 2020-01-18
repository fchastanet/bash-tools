#!/usr/bin/env bash

declare -g logFile
setup() {
  logFile="$(mktemp "${TMPDIR:-/tmp}/bash.framework.XXXXXXXXXXXX.log")"
}

teardown() {
  rm -f "${logFile}" || true
}

# shellcheck source=bash-framework/_bootstrap.sh
__bash_framework_envFile="" source "$(cd "$( readlink -e "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1

@test "framework is loaded" {
    [[ "${BASH_FRAMEWORK_INITIALIZED}" = "1" ]]
}

@test "default value for BASH_FRAMEWORK_DISPLAY_LEVEL" {
    [[ "${BASH_FRAMEWORK_DISPLAY_LEVEL}" = "${__LEVEL_INFO}" ]]
}

@test "default value for BASH_FRAMEWORK_LOG_LEVEL" {
    [[ "${BASH_FRAMEWORK_LOG_LEVEL}" = "${__LEVEL_OFF}" ]]
}

@test "default value for BASH_FRAMEWORK_LOG_FILE" {
    [[ "${BASH_FRAMEWORK_LOG_FILE}" = "" ]]
}

@test "__bash_framework_rootLibPath" {
    [[ "${__bash_framework_rootLibPath}" = "$( cd "${BATS_TEST_DIRNAME}/../../bash-framework" && pwd )" ]]
}

@test "__bash_framework_rootCallingScriptPath" {
    [[ "${__bash_framework_rootCallingScriptPath}" = "$( cd "${BATS_TEST_DIRNAME}/../../vendor/bats/libexec/bats-core" && pwd )" ]]
}

@test "__bash_framework_rootVendorPath" {
    [[ "${__bash_framework_rootVendorPath}" = "$( cd "${BATS_TEST_DIRNAME}/../.." && pwd )" ]]
}

@test "load alternative env file " {
    BASH_FRAMEWORK_INITIALIZED=0  __bash_framework_envFile="${BATS_TEST_DIRNAME}/data/Framework.env" source "$(cd "$( readlink -e "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1
    [[ "${BASH_FRAMEWORK_DISPLAY_LEVEL}" = "${__LEVEL_ERROR}" ]]
    [[ "${BASH_FRAMEWORK_LOG_LEVEL}" = "${__LEVEL_OFF}" ]] # because log file not provided
}

@test "load alternative env file 2" {
    BASH_FRAMEWORK_INITIALIZED=0  __bash_framework_envFile="${BATS_TEST_DIRNAME}/data/Framework-debug.env" source "$(cd "$( readlink -e "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1
    [[ "${BASH_FRAMEWORK_DISPLAY_LEVEL}" = "${__LEVEL_DEBUG}" ]]
    [[ "${BASH_FRAMEWORK_LOG_LEVEL}" = "${__LEVEL_OFF}" ]] # because log file not provided
}

@test "load alternative env file 2 with log file provided" {
    BASH_FRAMEWORK_LOG_FILE="${logFile}" BASH_FRAMEWORK_INITIALIZED=0  __bash_framework_envFile="${BATS_TEST_DIRNAME}/data/Framework-debug.env" source "$(cd "$( readlink -e "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1
    [[ "${BASH_FRAMEWORK_DISPLAY_LEVEL}" = "${__LEVEL_DEBUG}" ]]
    [[ "${BASH_FRAMEWORK_LOG_LEVEL}" = "${__LEVEL_DEBUG}" ]] # because log file not provided
}
