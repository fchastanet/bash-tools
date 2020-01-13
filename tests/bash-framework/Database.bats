#!/usr/bin/env bash

load '../../vendor/bats-support/load'
load '../../vendor/bats-assert/load'

# shellcheck source=bash-framework/_bootstrap.sh
__bash_framework_envFile="" source "$(cd "$( readlink -e "${BATS_TEST_DIRNAME}/../..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1

import bash-framework/Database

@test "framework is loaded" {
    [[ "${BASH_FRAMEWORK_INITIALIZED}" = "1" ]]
}

@test "Database::createInstance" {
    # TODO
}
