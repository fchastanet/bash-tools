#!/usr/bin/env bash

toolsDir="$(cd "${BATS_TEST_DIRNAME}/../../bin" && pwd)"
vendorDir="$(cd "${BATS_TEST_DIRNAME}/../../vendor" && pwd)"

# shellcheck source=bash-framework/Constants.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/Constants.sh" || exit 1

load "${vendorDir}/bats-mock-Flamefire/load.bash"

setup() {
  export HOME="/tmp/home"
  (
    mkdir -p "${HOME}"
    cd "${HOME}" || exit 1
    mkdir -p \
      bin \
      .bash-tools/dsn \
      .bash-tools/dbImportDumps \
      .bash-tools/dbImportProfiles
    touch bin/mysql bin/mysqldump bin/mysqlshow
    chmod +x bin/*
  )
  export PATH="${PATH}:/tmp/home/bin"
}

teardown() {
  #    rm -Rf /tmp/home || true
  unstub_all
}

function display_help { #@test
  run "${toolsDir}/dbImportProfile" --help 2>&1
  # shellcheck disable=SC2154
  [[ "${lines[0]}" = "${__HELP_TITLE}Description:${__HELP_NORMAL} generate optimized profiles to be used by dbImport" ]]
  run "${toolsDir}/dbImportProfile" -h 2>&1
  [[ "${lines[0]}" = "${__HELP_TITLE}Description:${__HELP_NORMAL} generate optimized profiles to be used by dbImport" ]]
}

function fromDbName_not_provided { #@test
  run "${toolsDir}/dbImportProfile" 2>&1
  # shellcheck disable=SC2154
  [[ "${output}" == *"FATAL - you must provide fromDbName"* ]]
  # shellcheck disable=SC2154
  [[ "${status}" == "1" ]]
}

function dsn_file_not_found { #@test
  run "${toolsDir}/dbImportProfile" -f notFound fromDb
  [[ "${output}" == *"ERROR - conf file 'notFound' not found"* ]]
  [[ "${status}" == "1" ]]
  run "${toolsDir}/dbImportProfile" --from-dsn notFound fromDb
  [[ "${output}" == *"ERROR - conf file 'notFound' not found"* ]]
  [[ "${status}" == "1" ]]
}

function ratio_not_a_number { #@test
  run "${toolsDir}/dbImportProfile" -f default.local -r ratio fromDb
  [[ "${output}" == *"FATAL - Ratio value should be a number"* ]]
  [[ "${status}" == "1" ]]
  run "${toolsDir}/dbImportProfile" -f default.local --ratio ratio fromDb
  [[ "${output}" == *"FATAL - Ratio value should be a number"* ]]
  [[ "${status}" == "1" ]]
}

function ratio_less_than_0 { #@test
  run "${toolsDir}/dbImportProfile" -f default.local -r -1 fromDb
  [[ "${output}" == *"FATAL - Ratio value should be between 0 and 100"* ]]
  [[ "${status}" == "1" ]]
  run "${toolsDir}/dbImportProfile" -f default.local --ratio -1 fromDb
  [[ "${output}" == *"FATAL - Ratio value should be between 0 and 100"* ]]
  [[ "${status}" == "1" ]]
}

function ratio_greater_than_100 { #@test
  run "${toolsDir}/dbImportProfile" -f default.local -r 101 fromDb
  [[ "${output}" == *"FATAL - Ratio value should be between 0 and 100"* ]]
  [[ "${status}" == "1" ]]
  run "${toolsDir}/dbImportProfile" -f default.local --ratio 101 fromDb
  [[ "${output}" == *"FATAL - Ratio value should be between 0 and 100"* ]]
  [[ "${status}" == "1" ]]
}

function remote_db_not_found { #@test
  stub mysqlshow \
    '* * dbNotFound : echo ""'
  run "${toolsDir}/dbImportProfile" -f default.local dbNotFound 2>&1
  [[ "${output}" == *"FATAL - From Database dbNotFound does not exist !"* ]]
}

function remote_db_fully_functional { #@test
  stub mysqlshow \
    '* * fromDb : echo "Database: fromDb"'
  stub mysql \
    "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names information_schema -e \* : echo \${10} > /tmp/home/tableSizeQuery.sql; cat \"${BATS_TEST_DIRNAME}/data/dbImportProfile.tableList1\""

  run "${toolsDir}/dbImportProfile" -f default.local fromDb 2>&1

  [[ -f "/tmp/home/tableSizeQuery.sql" ]]
  [[ "${output}" == *"Profile generated - 1/3 tables bigger than 70% of max table size (29MB) automatically excluded"* ]]
  [[ "$(md5sum /tmp/home/tableSizeQuery.sql | awk '{ print $1 }')" == "$(md5sum "${BATS_TEST_DIRNAME}/data/expectedDbImportProfileTableListQuery.sql" | awk '{ print $1 }')" ]]
  [[ -f "/tmp/home/.bash-tools/dbImportProfiles/auto_default.local_fromDb.sh" ]]
  [[ "$(md5sum /tmp/home/.bash-tools/dbImportProfiles/auto_default.local_fromDb.sh | awk '{ print $1 }')" == "$(md5sum "${BATS_TEST_DIRNAME}/data/auto_default.local_fromDb_70.sh" | awk '{ print $1 }')" ]]
}

function remote_db_fully_functional_ratio_20 { #@test
  stub mysqlshow \
    '* * fromDb : echo "Database: fromDb"'
  stub mysql \
    "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names information_schema -e \* : echo \${10} > /tmp/home/tableSizeQuery.sql; cat \"${BATS_TEST_DIRNAME}/data/dbImportProfile.tableList1\""

  run "${toolsDir}/dbImportProfile" -f default.local -r 20 fromDb 2>&1

  [[ -f "/tmp/home/tableSizeQuery.sql" ]]
  [[ "${output}" == *"Profile generated - 2/3 tables bigger than 20% of max table size (29MB) automatically excluded"* ]]
  [[ "$(md5sum /tmp/home/tableSizeQuery.sql | awk '{ print $1 }')" == "$(md5sum "${BATS_TEST_DIRNAME}/data/expectedDbImportProfileTableListQuery.sql" | awk '{ print $1 }')" ]]
  [[ -f "/tmp/home/.bash-tools/dbImportProfiles/auto_default.local_fromDb.sh" ]]
  [[ "$(md5sum /tmp/home/.bash-tools/dbImportProfiles/auto_default.local_fromDb.sh | awk '{ print $1 }')" == "$(md5sum "${BATS_TEST_DIRNAME}/data/auto_default.local_fromDb_20.sh" | awk '{ print $1 }')" ]]
}
