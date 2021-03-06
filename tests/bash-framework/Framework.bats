#!/usr/bin/env bash

declare logFile
setup() {
  export HOME="/tmp/home"
  mkdir -p /tmp/home
  logFile="$(mktemp -p "${TMPDIR:-/tmp}" -t "bash.framework.XXXXXXXXXXXX")"
}

teardown() {
  rm -f "${logFile}" || true
}


@test "${BATS_TEST_FILENAME#/bash/tests/} framework is loaded" {
    # shellcheck source=bash-framework/_bootstrap.sh
    __BASH_FRAMEWORK_ENV_FILEPATH="" source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1

    [[ "${BASH_FRAMEWORK_INITIALIZED}" = "1" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} default value for BASH_FRAMEWORK_DISPLAY_LEVEL" {
    # shellcheck source=bash-framework/_bootstrap.sh
    __BASH_FRAMEWORK_ENV_FILEPATH="" source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1

    [[ "${BASH_FRAMEWORK_DISPLAY_LEVEL}" = "${__LEVEL_INFO}" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} default value for BASH_FRAMEWORK_LOG_LEVEL" {
    # shellcheck source=bash-framework/_bootstrap.sh
    __BASH_FRAMEWORK_ENV_FILEPATH="" source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1

    [[ "${BASH_FRAMEWORK_LOG_LEVEL}" = "${__LEVEL_OFF}" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} default value for BASH_FRAMEWORK_LOG_FILE" {
    # shellcheck source=bash-framework/_bootstrap.sh
    __BASH_FRAMEWORK_ENV_FILEPATH="" source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1

    [[ "${BASH_FRAMEWORK_LOG_FILE}" = "/tmp/home/.bash-tools/logs/bash.log" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} __BASH_FRAMEWORK_ROOT_PATH" {
    # shellcheck source=bash-framework/_bootstrap.sh
    __BASH_FRAMEWORK_ENV_FILEPATH="" source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1

    [[ "${__BASH_FRAMEWORK_ROOT_PATH}" = "$( cd "${BATS_TEST_DIRNAME}/../../bash-framework" && pwd )" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} __BASH_FRAMEWORK_CALLING_SCRIPT" {
    # shellcheck source=bash-framework/_bootstrap.sh
    __BASH_FRAMEWORK_ENV_FILEPATH="" source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1

    [[ "${__BASH_FRAMEWORK_CALLING_SCRIPT}" = "$( cd "${BATS_TEST_DIRNAME}/../../vendor/bats/libexec/bats-core" && pwd )" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} __BASH_FRAMEWORK_VENDOR_PATH" {
    # shellcheck source=bash-framework/_bootstrap.sh
    __BASH_FRAMEWORK_ENV_FILEPATH="" source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1

    [[ "${__BASH_FRAMEWORK_VENDOR_PATH}" = "$( cd "${BATS_TEST_DIRNAME}/../.." && pwd )" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} load alternative env file " {
    BASH_FRAMEWORK_INITIALIZED=0  __BASH_FRAMEWORK_ENV_FILEPATH="${BATS_TEST_DIRNAME}/data/Framework.env" source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1
    [[ "${BASH_FRAMEWORK_DISPLAY_LEVEL}" = "${__LEVEL_ERROR}" ]]
    [[ "${BASH_FRAMEWORK_LOG_LEVEL}" = "${__LEVEL_OFF}" ]] # because log file not provided
}

@test "${BATS_TEST_FILENAME#/bash/tests/} load alternative env file 2" {
    BASH_FRAMEWORK_INITIALIZED=0  __BASH_FRAMEWORK_ENV_FILEPATH="${BATS_TEST_DIRNAME}/data/Framework-debug.env" source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1
    [[ "${BASH_FRAMEWORK_DISPLAY_LEVEL}" = "${__LEVEL_DEBUG}" ]]
    [[ "${BASH_FRAMEWORK_LOG_LEVEL}" = "${__LEVEL_OFF}" ]] # because log file not writable
}

@test "${BATS_TEST_FILENAME#/bash/tests/} load alternative env file 2 with log file provided" {
    BASH_FRAMEWORK_LOG_FILE="${logFile}" BASH_FRAMEWORK_INITIALIZED=0  __BASH_FRAMEWORK_ENV_FILEPATH="${BATS_TEST_DIRNAME}/data/Framework-debug-nologfile.env" source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1
    [[ "${BASH_FRAMEWORK_DISPLAY_LEVEL}" = "${__LEVEL_DEBUG}" ]]
    [[ "${BASH_FRAMEWORK_LOG_LEVEL}" = "${__LEVEL_DEBUG}" ]]
}
