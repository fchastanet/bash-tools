#!/usr/bin/env bash

# shellcheck source=bash-framework/_bootstrap.sh
__bash_framework_envFile="" source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1

import bash-framework/Database

@test "framework is loaded" {
    [[ "${BASH_FRAMEWORK_INITIALIZED}" = "1" ]]
}

@test "Database::createInstance" {
    # TODO
}
