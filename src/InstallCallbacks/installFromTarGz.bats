#!/usr/bin/env bash
# shellcheck disable=SC2154
# shellcheck disable=SC2034

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/.." && pwd)/batsHeaders.sh"
# shellcheck source=src/InstallCallbacks/installFromTarGz.sh
source "${rootDir}/src/InstallCallbacks/installFromTarGz.sh"

function setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"
}

function teardown() {
  unstub_all
}

function InstallCallbacks::installFromTarGz::success { #@test
  stub sudo \
    "tar xzvf /tmp/file.tgz -C /usr/local/bin binary : exit 0" \
    "chmod +x /usr/local/bin/binary : exit 0" \
    "rm -f /tmp/file.tgz : exit 0"
  run InstallCallbacks::installFromTarGz /tmp/file.tgz /usr/local/bin/binary
  assert_success
  assert_output --partial "INFO    - Installing /tmp/file.tgz to /usr/local/bin/binary"
}
