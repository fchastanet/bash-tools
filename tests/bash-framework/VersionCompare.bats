#!/usr/bin/env bash

# shellcheck source=bash-framework/_bootstrap.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1

import bash-framework/Version

@test "${BATS_TEST_FILENAME#/bash/tests/} versionCompare equals 1 number" {
    run Version::compare 1 1
    [[ "$status" = "0" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} versionCompare equals 3 numbers" {
    run Version::compare 5.6.7  5.6.7
    [[ "$status" = "0" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} versionCompare equals 3 numbers some with left 0" {
    run Version::compare 1.01.1 1.1.1
    [[ "$status" = "0" ]]
    run Version::compare 1.1.1 1.01.1
    [[ "$status" = "0" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} versionCompare equals 1=1.0" {
    run Version::compare 1 1.0
    [[ "$status" = "0" ]]
    run Version::compare 1.0 1
    [[ "$status" = "0" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} versionCompare equals even if ends with zero" {
    run Version::compare 1 1.0
    [[ "$status" = "0" ]]
    run Version::compare 1.0 1
    [[ "$status" = "0" ]]
    run Version::compare 1 1.0.0
    [[ "$status" = "0" ]]
    run Version::compare 1.0.0 1
    [[ "$status" = "0" ]]
    run Version::compare 1.1.0 1.1
    [[ "$status" = "0" ]]
    run Version::compare 1.1 1.1.0
    [[ "$status" = "0" ]]
    run Version::compare 1..0 1.0
    [[ "$status" = "0" ]]
    run Version::compare 1.0 1..0
    [[ "$status" = "0" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} versionCompare less than" {
    run Version::compare 2.1          2.2
    [[ "$status" = "2" ]]
    run Version::compare 4.08         4.08.01
    [[ "$status" = "2" ]]
    run Version::compare 3.2          3.2.1.9.8144
    [[ "$status" = "2" ]]
    run Version::compare 1.2          2.1
    [[ "$status" = "2" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} versionCompare greater than" {
    run Version::compare 3.0.4.10     3.0.4.2
    [[ "$status" = "1" ]]
    run Version::compare 3.2.1.9.8144 3.2
    [[ "$status" = "1" ]]
    run Version::compare 2.1          1.2
    [[ "$status" = "1" ]]
}




