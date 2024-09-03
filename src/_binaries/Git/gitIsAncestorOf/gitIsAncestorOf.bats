#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)/batsHeaders.sh"

load "${FRAMEWORK_ROOT_DIR}/src/_standalone/Bats/assert_lines_count.sh"

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"
  export HOME="${BATS_TEST_TMPDIR}/home"
  export BASH_FRAMEWORK_ENV_FILEPATH="${BATS_TEST_DIRNAME}/testsData/.env"
  mkdir -p "${HOME}/.bash-tools"
  cp "${rootDir}/conf/.env" "${HOME}/.bash-tools/.env"
}

teardown() {
  unstub_all
}

function Git::gitIsAncestorOf::display_help { #@test
  testCommand "${binDir}/gitIsAncestorOf" gitIsAncestorOf.help.txt
}
