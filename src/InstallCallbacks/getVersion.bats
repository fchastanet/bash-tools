#!/usr/bin/env bash
# shellcheck disable=SC2154
# shellcheck disable=SC2034

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/.." && pwd)/batsHeaders.sh"
# shellcheck source=src/InstallCallbacks/getVersion.sh
source "${rootDir}/src/InstallCallbacks/getVersion.sh"

function setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"
}

function teardown() {
  unstub_all
}

function InstallCallbacks::getVersion::lsVersion { #@test
  stub ls "--version : echo 'ls (GNU coreutils) 8.30'"
  run InstallCallbacks::getVersion arg1 "ls --version | head -n 1"
  assert_success
  assert_output "ls (GNU coreutils) 8.30"
}

function InstallCallbacks::getVersion::invalidCommand { #@test
  stub invalidCommand "--version : exit 1"
  run InstallCallbacks::getVersion arg1 "invalidCommand --version"
  assert_failure 1
  assert_output --partial "Failed to get version"
}
