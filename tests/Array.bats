#!/usr/bin/env bash

load '../vendor/bats-support/load'
load '../vendor/bats-assert/load'

# shellcheck source=bash-framework/_bootstrap.sh
__bash_framework_envFile="" source "$(cd "$( readlink -e "${BATS_TEST_DIRNAME}/..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1
set +o errexit

import bash-framework/Array

@test "framework is loaded" {
    [[ "${BASH_FRAMEWORK_INITIALIZED}" = "1" ]]
}

@test "Array::contains" {
    declare -a tab=("elem1" "elem2" "elem3")

    Array::contains "elem0" "${tab[@]}"
    [[ "${status}" = "1" ]]
    Array::contains "elem1" "${tab[@]}"
    [[ "${status}" = "0" ]]
    Array::contains "elem3" "${tab[@]}"
    [[ "${status}" = "0" ]]
}
