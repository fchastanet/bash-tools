#!/usr/bin/env bash

rootDir="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
# shellcheck disable=SC2034
binDir="${rootDir}/bin"
vendorDir="${rootDir}/vendor"
FRAMEWORK_DIR="$(cd "${vendorDir}/bash-tools-framework" && pwd -P)"
export FRAMEWORK_DIR

# shellcheck source=vendor/bash-tools-framework/src/Log/_.sh
source "${FRAMEWORK_DIR}/src/Log/_.sh" || exit 1

load "${FRAMEWORK_DIR}/vendor/bats-support/load.bash"
load "${FRAMEWORK_DIR}/vendor/bats-assert/load.bash"
load "${FRAMEWORK_DIR}/vendor/bats-mock-Flamefire/load.bash"
