#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"

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
  cp "${rootDir}/conf/.env" "${HOME}/.bash-tools/.env"

  touch "${HOME}/bin/mysql" "${HOME}/bin/mysqldump" "${HOME}/bin/mysqlshow" "${HOME}/bin/builtinCommandWrapper"
  chmod +x "${HOME}/bin/"*

  export BASH_FRAMEWORK_COMMAND="builtinCommandWrapper"

  export PATH="${PATH}:${HOME}/bin"
}

teardown() {
  unstub_all
}

function Database::dbImportProfile::display_help { #@test
  testCommand "${binDir}/dbImportProfile" dbImportProfile.help.txt
}

function Database::dbImportProfile::fromDbName_not_provided { #@test
  # shellcheck disable=SC2154
  run "${binDir}/dbImportProfile" 2>&1
  assert_output --partial "ERROR   - Command dbImportProfile - Argument 'fromDbName' should be provided at least 1 time(s)"
  assert_failure
}

function Database::dbImportProfile::dsn_file_not_found { #@test
  # shellcheck disable=SC2154
  run "${binDir}/dbImportProfile" -f notFound fromDb
  assert_output --partial "ERROR   - conf file 'notFound' not found"
  assert_failure
  run "${binDir}/dbImportProfile" --from-dsn notFound fromDb
  assert_output --partial "ERROR   - conf file 'notFound' not found"
  assert_failure
}

function Database::dbImportProfile::ratio_not_a_number { #@test
  # shellcheck disable=SC2154
  run "${binDir}/dbImportProfile" --verbose -f default.local -r ratio fromDb
  assert_output --partial "FATAL   - Ratio value should be a number"
  assert_failure
  run "${binDir}/dbImportProfile" -f default.local --ratio ratio fromDb
  assert_output --partial "FATAL   - Ratio value should be a number"
  assert_failure
}

function Database::dbImportProfile::ratio_less_than_0 { #@test
  # shellcheck disable=SC2154
  run "${binDir}/dbImportProfile" --verbose -f default.local -r -1 fromDb
  assert_output --partial "FATAL   - Ratio value should be between 0 and 100"
  assert_failure
  run "${binDir}/dbImportProfile" -f default.local --ratio -1 fromDb
  assert_output --partial "FATAL   - Ratio value should be between 0 and 100"
  assert_failure
}

function Database::dbImportProfile::ratio_greater_than_100 { #@test
  # shellcheck disable=SC2154
  run "${binDir}/dbImportProfile" -f default.local -r 101 fromDb
  assert_output --partial "FATAL   - Ratio value should be between 0 and 100"
  assert_failure
  run "${binDir}/dbImportProfile" -f default.local --ratio 101 fromDb
  assert_output --partial "FATAL   - Ratio value should be between 0 and 100"
  assert_failure
}

function Database::dbImportProfile::remote_db_not_found { #@test
  stub mysqlshow \
    '* * dbNotFound : echo ""'
  # shellcheck disable=SC2154
  run "${binDir}/dbImportProfile" --verbose -f default.local dbNotFound 2>&1
  assert_output --partial "FATAL   - From Database dbNotFound does not exist !"
}

function Database::dbImportProfile::remote_db_fully_functional_default_ratio { #@test
  stub mysqlshow \
    '* * fromDb : echo "Database: fromDb"'
  stub mysql \
    "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names information_schema -e \* : echo \${10} > ${HOME}/tableSizeQuery.sql; cat \"${BATS_TEST_DIRNAME}/testsData/dbImportProfile.tableList1\""

  # shellcheck disable=SC2154
  run "${binDir}/dbImportProfile" --verbose -f default.local fromDb 2>&1

  [[ -f "${HOME}/tableSizeQuery.sql" ]]
  assert_lines_count 3
  assert_line --index 0 --partial "INFO    - Using from dsn"
  assert_line --index 1 --partial "INFO    - Profile generated - 1/3 tables bigger than 70% of max table size (29MB) automatically excluded"
  assert_line --index 2 --partial "INFO    - File saved"
  diff >&3 "${HOME}/tableSizeQuery.sql" "${BATS_TEST_DIRNAME}/testsData/expectedDbImportProfileTableListQuery.sql"
  [[ -f "${HOME}/.bash-tools/dbImportProfiles/auto_default.local_fromDb.sh" ]]
  diff -u "${HOME}/.bash-tools/dbImportProfiles/auto_default.local_fromDb.sh" \
    "${BATS_TEST_DIRNAME}/testsData/auto_default.local_fromDb_70.sh"
}

function Database::dbImportProfile::remote_db_fully_functional_ratio_20 { #@test
  stub mysqlshow \
    '* * fromDb : echo "Database: fromDb"'
  stub mysql \
    "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names information_schema -e \* : echo \${10} > '${HOME}/tableSizeQuery.sql'; cat \"${BATS_TEST_DIRNAME}/testsData/dbImportProfile.tableList1\""

  # shellcheck disable=SC2154
  run "${binDir}/dbImportProfile" --verbose -f default.local -r 20 fromDb 2>&1

  [[ -f "${HOME}/tableSizeQuery.sql" ]]

  assert_lines_count 3 || assert_output ""
  assert_line --index 0 --partial "INFO    - Using from dsn"
  assert_line --index 1 --partial "Profile generated - 2/3 tables bigger than 20% of max table size (29MB) automatically excluded"
  assert_line --index 2 --partial "INFO    - File saved in"

  [[ "$(md5sum "${HOME}/tableSizeQuery.sql" | awk '{ print $1 }')" == "$(md5sum "${BATS_TEST_DIRNAME}/testsData/expectedDbImportProfileTableListQuery.sql" | awk '{ print $1 }')" ]]

  [[ -f "${HOME}/.bash-tools/dbImportProfiles/auto_default.local_fromDb.sh" ]]
  diff -u "${HOME}/.bash-tools/dbImportProfiles/auto_default.local_fromDb.sh" \
    "${BATS_TEST_DIRNAME}/testsData/auto_default.local_fromDb_20.sh"
}
