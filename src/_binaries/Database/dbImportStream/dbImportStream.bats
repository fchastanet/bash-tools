#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)/batsHeaders.sh"

# shellcheck source=vendor/bash-tools-framework/src/Log/_.sh
source "${FRAMEWORK_ROOT_DIR}/src/Log/_.sh" || exit 1

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"
  export HOME="${BATS_TEST_TMPDIR}/home"

  mkdir -p \
    "${HOME}" \
    "${HOME}/bin" \
    "${HOME}/.bash-tools/dsn" \
    "${HOME}/.bash-tools/dbImportDumps" \
    "${HOME}/.bash-tools/dbImportProfiles"
  cp "${BATS_TEST_DIRNAME}/testsData/dsn/"* "${HOME}/.bash-tools/dsn/"
  touch "${HOME}/bin/mysql" "${HOME}/bin/mysqldump" "${HOME}/bin/mysqlshow" "${HOME}/bin/builtinCommandWrapper"
  chmod +x "${HOME}/bin/"*
  cp "${rootDir}/conf/.env" "${HOME}/.bash-tools/.env"

  export BASH_FRAMEWORK_COMMAND="builtinCommandWrapper"

  export PATH="${PATH}:${HOME}/bin"
}

teardown() {
  unstub_all
}

function Database::dbImportStream::display_help { #@test
  testCommand "${binDir}/dbImportStream" dbImportStream.help.txt
}
