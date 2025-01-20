#!/usr/bin/env bash
# shellcheck disable=SC2154
# shellcheck disable=SC2034

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/.." && pwd)/batsHeaders.sh"
# shellcheck source=src/InstallCallbacks/installDeb.sh
source "${rootDir}/src/InstallCallbacks/installDeb.sh"

function setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"
}

function teardown() {
  unstub_all
}

function InstallCallbacks::installDeb::success { #@test
  stub sudo \
    "dpkg -i file.deb : exit 0" \
    "rm -f file.deb : exit 0"
  run InstallCallbacks::installDeb file.deb
  assert_success
  assert_output --partial "INFO    - Installing Debian package file.deb"
}
