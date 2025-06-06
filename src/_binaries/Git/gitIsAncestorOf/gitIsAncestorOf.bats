#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)/batsHeaders.sh"

load "${FRAMEWORK_ROOT_DIR}/src/_standalone/Bats/assert_lines_count.sh"

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}/.bash-tools"
  cp "${rootDir}/conf/defaultEnv/.env" "${HOME}/.bash-tools/.env"
}

teardown() {
  unstub_all
}

function Git::gitIsAncestorOf::display_help { #@test
  testCommand "${binDir}/gitIsAncestorOf" gitIsAncestorOf.help.txt
}
