#!/usr/bin/env bash
# shellcheck disable=SC2154
# shellcheck disable=SC2034

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/.." && pwd)/batsHeaders.sh"
# shellcheck source=src/InstallCallbacks/installFromTarXz.sh
source "${rootDir}/src/InstallCallbacks/installFromTarXz.sh"

function setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"
}

function teardown() {
  unstub_all
}

function InstallCallbacks::installFromTarXz::success { #@test
  stub tar \
    "xvf /tmp/file.tar.xz -C * : exit 0"

  stub sudo \
    "find * -type f -name binary -exec mv {} /usr/local/bin/binary \; : exit 0" \
    "chmod +x /usr/local/bin/binary : exit 0" \
    "rm -rf * /tmp/file.tar.xz : exit 0"
  run InstallCallbacks::installFromTarXz /tmp/file.tar.xz /usr/local/bin/binary
  assert_success
  assert_output --partial "INFO    - Installing /tmp/file.tar.xz to /usr/local/bin/binary"
}
