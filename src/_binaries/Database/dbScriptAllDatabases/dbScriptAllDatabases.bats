#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)/batsHeaders.sh"

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"

  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p \
    "${HOME}/bin" \
    "${HOME}/.bash-tools/dsn" \
    "${HOME}/.bash-tools/dbImportDumps" \
    "${HOME}/.bash-tools/dbImportProfiles" \
    "${HOME}/.bash-tools/dbQueries" \
    "${HOME}/.bash-tools/dbScripts"
  cp "${BATS_TEST_DIRNAME}/testsData/pv" "${HOME}/bin"
  cp "${rootDir}/conf/.env" "${HOME}/.bash-tools/.env"
  touch \
    "${HOME}/bin/mysqldump" \
    "${HOME}/bin/mysqlshow" \
    "${HOME}/bin/builtinCommandWrapper"
  chmod +x "${HOME}/bin/"*
  export BASH_FRAMEWORK_COMMAND="builtinCommandWrapper"

  cp "${BATS_TEST_DIRNAME}/testsData/dsn_"* "${HOME}/.bash-tools/dsn"

  export PATH="${HOME}/bin:${PATH}"
}

teardown() {
  unstub_all
}

function Database::dbScriptAllDatabases::display_help { #@test
  testCommand "${binDir}/dbScriptAllDatabases" dbScriptAllDatabases.help.txt
}

function Database::dbScriptAllDatabases::script_file_not_provided { #@test
  cp "${BATS_TEST_DIRNAME}/testsData/parallel" "${HOME}/bin"

  f() {
    # shellcheck disable=SC2154,SC2317
    "${binDir}/dbScriptAllDatabases" 2>&1
  }
  run f
  assert_failure 1
  assert_output --partial "ERROR   - Command dbScriptAllDatabases - Argument 'scriptToExecute' should be provided at least 1 time(s)"
}

function Database::dbScriptAllDatabases::extractData { #@test
  export BATS_TEST_DIRNAME
  export HOME
  # shellcheck disable=SC2016
  stub mysql \
    '* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e * : echo "$@" > "${HOME}/query0" ; cat "${BATS_TEST_DIRNAME}/testsData/getUserDbList.result"' \
    '* --batch --raw --default-character-set=utf8 --connect-timeout=5 db1 -e * : echo "$8" > "${HOME}/query1" ; cat "${BATS_TEST_DIRNAME}/testsData/databaseSize.result_db1"' \
    '* --batch --raw --default-character-set=utf8 --connect-timeout=5 db2 -e * : echo "$8" > "${HOME}/query2" ; cat "${BATS_TEST_DIRNAME}/testsData/databaseSize.result_db2"'

  # shellcheck disable=SC2016
  stub parallel \
    '--bar --eta --progress --tag -j 1 * * * * * * * * : while IFS= read -r db; do "${@:7}" "${db}"; done'

  run "${binDir}/dbScriptAllDatabases" \
    -f "${BATS_TEST_DIRNAME}/testsData/databaseSize.envProvided.sh" \
    "${rootDir}/conf/dbScripts/extractData" \
    "${rootDir}/conf/dbQueries/databaseSize.sql"

  assert_success
  [[ -f "${HOME}/query1" ]]
  [[ "$(md5sum <"${HOME}/query1")" == "$(md5sum <"${rootDir}/conf/dbQueries/databaseSize.sql")" ]]

  [[ -f "${HOME}/query2" ]]
  [[ "$(md5sum <"${HOME}/query2")" = "$(md5sum <"${rootDir}/conf/dbQueries/databaseSize.sql")" ]]

  assert_output "$(cat "${BATS_TEST_DIRNAME}/testsData/dbScriptAllDatabases.result")"
}
