#!/usr/bin/env bash

load '../../vendor/bats-support/load'
load '../../vendor/bats-assert/load'

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
    [[ "${__bash_framework_rootCallingScriptPath}" = "$( cd "${BATS_TEST_DIRNAME}/../../vendor/bats/libexec" && pwd )" ]]
}

@test "__bash_framework_rootVendorPath" {
    [[ "${__bash_framework_rootVendorPath}" = "$( cd "${BATS_TEST_DIRNAME}/../.." && pwd )" ]]
}

@test "load alternative env file " {
    BASH_FRAMEWORK_INITIALIZED=0  __bash_framework_envFile="${BATS_TEST_DIRNAME}/data/Framework.env" source "$(cd "$( readlink -e "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1
    [[ "${BASH_FRAMEWORK_DISPLAY_LEVEL}" = "${__LEVEL_ERROR}" ]]
    [[ "${BASH_FRAMEWORK_LOG_LEVEL}" = "${__LEVEL_INFO}" ]]
}
