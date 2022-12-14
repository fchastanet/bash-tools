#!/usr/bin/env bash

rootDir="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
binDir="${rootDir}/bin"
vendorDir="${rootDir}/vendor"

# shellcheck source=vendor/bash-tools-framework/src/Log/_.sh
source "${vendorDir}/bash-tools-framework/src/Log/_.sh" || exit 1

load "${vendorDir}/bats-support/load.bash"
load "${vendorDir}/bats-assert/load.bash"
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
    cp "${BATS_TEST_DIRNAME}/mocks/pv" bin
    cp "${BATS_TEST_DIRNAME}/mocks/gawk" bin
    cp "${BATS_TEST_DIRNAME}/mocks/gawk" bin/awk
    touch bin/mysql bin/mysqldump bin/mysqlshow
    cp "${rootDir}/conf/.env" .bash-tools/.env
    sed -i -E 's#^S3_BASE_URL=.*$#S3_BASE_URL=s3://s3server/exports/#g' .bash-tools/.env
    chmod +x bin/*
  )
  export PATH="${PATH}:/tmp/home/bin"
}

teardown() {
  rm -Rf /tmp/home || true
  unstub_all
}

function display_help { #@test
  run "${binDir}/dbImport" --help 2>&1
  # shellcheck disable=SC2154
  assert_line --index 0 "Description: Import source db into target db"
}

function remoteDbName_not_provided { #@test
  run "${binDir}/dbImport" 2>&1
  # shellcheck disable=SC2154
  assert_output --partial "FATAL   - you must provide remoteDbName"
}

function from_aws_and_aws_not_installed { #@test
  run "${binDir}/dbImport" --from-dsn default --from-aws fromDb 2>&1
  assert_output --partial "ERROR   - aws is not installed, please install it"
}

function from_aws_and_from_dsn_are_incompatible { #@test
  stub aws
  run "${binDir}/dbImport" --from-dsn default --from-aws fromDb 2>&1
  assert_output --partial "FATAL   - you cannot use from-dsn and from-aws at the same time"
}

function from_aws_missing_S3_BASE_URL { #@test
  stub aws
  sed -i -E 's#^S3_BASE_URL=.*$##g' "${HOME}/.bash-tools/.env"
  run "${binDir}/dbImport" --from-aws fromDb 2>&1
  assert_output --partial "FATAL   - missing S3_BASE_URL, please provide a value in .env file"
}

function a_and_f_are_incompatible { #@test
  stub aws
  run "${binDir}/dbImport" -f default -a fromDb 2>&1
  assert_output --partial "FATAL   - you cannot use from-dsn and from-aws at the same time"
}

function missing_aws { #@test
  # missing argument
  run "${binDir}/dbImport" -a fromDb 2>&1
  assert_output --partial "ERROR   - aws is not installed, please install it"
  assert_output --partial "INFO    - missing aws, please check"
}

function tables_invalid { #@test
  stub aws
  # missing argument
  run "${binDir}/dbImport" -a fromDb --tables 2>&1
  assert_output --partial "FATAL   - invalid options specified"

  # invalid argument
  run "${binDir}/dbImport" -a fromDb --tables ddd@ 2>&1
  assert_output --partial "FATAL   - Table list is not valid : ddd@"

  # invalid argument
  run "${binDir}/dbImport" -a fromDb --tables ddd, 2>&1
  assert_output --partial "FATAL   - Table list is not valid : ddd,"

  # invalid argument
  run "${binDir}/dbImport" -a fromDb --tables ddd,dd, 2>&1
  assert_output --partial "FATAL   - Table list is not valid : ddd,dd,"

  # invalid argument
  run "${binDir}/dbImport" -a fromDb --tables ddd- 2>&1
  assert_output --partial "FATAL   - Table list is not valid : ddd-"
}

function aws_file_not_found { #@test
  stub aws \
    "s3 ls --human-readable s3://s3server/exports/fromDb : exit 1"
  run "${binDir}/dbImport" -a fromDb 2>&1
  assert_output --partial "FATAL   - unable to get information on S3 object : s3://s3server/exports/fromDb"
}

function dsn_file_not_found { #@test
  run "${binDir}/dbImport" -f notFound fromDb
  assert_output --partial "ERROR   - conf file 'notFound' not found"
}

function remote_db_fully_functional { #@test
  # call 1 (order 1): check if target db exists to know if it should be created, no error
  # call 2 (order 2): check if from db exists, answers yes
  stub mysqlshow \
    '* * fromDb : echo "Database: fromDb"'
  # call 1 (order 3): from db default_collation_name
  # call 2 (order 4): from db default_character_set_name
  # call 3 (order 5): from db list tables
  # call 4 (order 6): estimate dump size
  # call 5 (order 9): create target db (after dumps have been done)
  # call 6 (order 10): import structure dump into db
  # call 7 (order 11): import data dump into db
  stub mysql \
    "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names information_schema -e 'SELECT default_collation_name FROM information_schema.SCHEMATA WHERE schema_name = \"fromDb\";' : echo 'collation'" \
    "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names information_schema -e 'SELECT default_character_set_name FROM information_schema.SCHEMATA WHERE schema_name = \"fromDb\";' : echo 'charset';" \
    "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names fromDb -e 'show tables' : echo 'table1'" \
    "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names : echo '100'" \
    $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \'CREATE DATABASE IF NOT EXISTS `toDb` CHARACTER SET "charset" COLLATE "collation"\' : echo "db created"' \
    "\* --connect-timeout=5 --batch --raw --default-character-set=utf8 -s --skip-column-names toDb : echo 'import structure dump'" \
    $'* --connect-timeout=5 --batch --raw --default-character-set=utf8 toDb : i=0 ; while read line; do ((i=i+1)); echo "line $i"; done < /dev/stdin'

  # call 1 (order 7): dump data
  # call 2 (order 8): dump structure
  stub mysqldump \
    "\* --default-character-set=utf8 --compress --hex-blob --routines --triggers --single-transaction --set-gtid-purged=OFF --column-statistics=0 --ssl-mode=DISABLED --no-create-info --skip-add-drop-table --single-transaction=TRUE fromDb table1 : echo '####data####'" \
    "\* --default-character-set=utf8 --compress --hex-blob --routines --triggers --single-transaction --set-gtid-purged=OFF --column-statistics=0 --ssl-mode=DISABLED --no-data --skip-add-drop-table --single-transaction=TRUE fromDb : echo '####structure####'"

  stub zcat \
    "\* : echo 'structure'" \
    "\* : cat ${BATS_TEST_DIRNAME}/data/dumpMissingSchema.sql"

  run "${binDir}/dbImport" -f default.local fromDb toDb 2>&1
  unstub zcat
  assert_output --partial "Import database duration : "
  assert_output --partial "begin insert emptyTable"
  assert_output --partial "begin insert dataTable"
  assert_output --partial "begin insert otherTable"
  [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz" ]]
  [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz" ]]
  [[ "$(zcat "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz" | grep '####data####')" = "####data####" ]]
  [[ "$(zcat "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz" | grep '####structure####')" = "####structure####" ]]
}

function remote_db_dump_already_present { #@test
  # change modification date 32 days in the past
  touch -d@$(($(date +%s) - 32 * 86400)) "${HOME}/.bash-tools/dbImportDumps/oldDump.sql.gz"
  # change modification date 1 day in the future
  touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/dumpInTheFuture.sql.gz"
  # create false dump 1 day in the past
  gzip <"${BATS_TEST_DIRNAME}/data/dumpMissingSchema.sql" >"${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz"
  gzip <"${BATS_TEST_DIRNAME}/data/dumpSchema.sql" >"${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz"
  touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz"
  touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz"
  # call 5 (order 2): create target db (after dumps have been done)
  # call 6 (order 3): import structure dump into db
  # call 7 (order 4): import data dump into db
  stub mysql \
    $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \'CREATE DATABASE IF NOT EXISTS `toDb` CHARACTER SET "utf8" COLLATE "utf8_general_ci"\' : echo "db created"' \
    "\* --connect-timeout=5 --batch --raw --default-character-set=utf8 -s --skip-column-names toDb : echo 'import structure dump'" \
    $'* --connect-timeout=5 --batch --raw --default-character-set=utf8  toDb : i=0 ; while read line; do ((i=i+1)); echo "line $i"; done < /dev/stdin'

  run "${binDir}/dbImport" -f default.local fromDb toDb 2>&1

  assert_output --partial "Import database duration : "
  assert_output --partial "begin insert emptyTable"
  assert_output --partial "begin insert dataTable"
  assert_output --partial "begin insert otherTable"
  [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz" ]]
  [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz" ]]
  # check files have been touched
  (($(date +%s) - $(stat -c "%Y" "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz") < 60))
  (($(date +%s) - $(stat -c "%Y" "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz") < 60))
  # check garbage
  [[ -f "${HOME}/.bash-tools/dbImportDumps/dumpInTheFuture.sql.gz" ]]
  [[ ! -f "${HOME}/.bash-tools/dbImportDumps/oldDump.sql.gz" ]]
}

function remote_db_fully_functional_from_aws { #@test

  stub aws \
    's3 ls --human-readable s3://s3server/exports/fromDb.tar.gz : exit 0' \
    's3 cp s3://s3server/exports/fromDb.tar.gz /tmp/home/.bash-tools/dbImportDumps/fromDb.tar.gz : exit 0'
  stub tar \
    "xOfz /tmp/home/.bash-tools/dbImportDumps/fromDb.tar.gz : cat ${BATS_TEST_DIRNAME}/data/dump.sql"

  # call 5 (order 9): create target db
  # call 7 (order 11): import data dump into db
  stub mysql \
    $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \'CREATE DATABASE IF NOT EXISTS `toDb` CHARACTER SET "utf8" COLLATE "utf8_general_ci"\' : echo "db created"' \
    $'* --connect-timeout=5  --batch --raw --default-character-set=utf8 toDb : i=0 ; while read line; do ((i=i+1)); echo "line $i"; done < /dev/stdin'

  run "${binDir}/dbImport" --from-aws fromDb.tar.gz toDb 2>&1

  assert_output --partial "Import database duration : "
  assert_output --partial "begin insert emptyTable"
  assert_output --partial "begin insert dataTable"
  assert_output --partial "begin insert otherTable"
}

function remote_db_dump_already_present_from_aws { #@test
  stub aws
  # create false dump 1 day in the past
  tar cvzf "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz" "${BATS_TEST_DIRNAME}/data/dump.sql"
  touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz"
  # call 5 (order 2): create target db (after dumps have been done)
  # call 7 (order 4): import data dump into db
  stub mysql \
    $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \'CREATE DATABASE IF NOT EXISTS `toDb` CHARACTER SET "utf8" COLLATE "utf8_general_ci"\' : echo "db created"' \
    $'* --connect-timeout=5  --batch --raw --default-character-set=utf8 toDb : i=0 ; while read line; do ((i=i+1)); echo "line $i"; done < /dev/stdin'

  run "${binDir}/dbImport" --from-aws fromDb.tar.gz toDb 2>&1

  assert_output --partial "Import database duration : "
  assert_output --partial "begin insert emptyTable"
  assert_output --partial "begin insert dataTable"
  assert_output --partial "begin insert otherTable"
  [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz" ]]
  # check files have been touched
  (($(date +%s) - $(stat -c "%Y" "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz") < 60))
}

function import_local_dump_not_aws_with_tables_filter { #@test
  # create false dump 1 day in the past
  gzip <"${BATS_TEST_DIRNAME}/data/dumpMissingSchema.sql" >"${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz"
  gzip <"${BATS_TEST_DIRNAME}/data/dumpSchema.sql" >"${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz"
  touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz"
  touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz"
  # call 5 (order 2): create target db (after dumps have been done)
  # call 6 (order 3): import structure dump into db
  # call 7 (order 4): import data dump into db
  stub mysql \
    $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \'CREATE DATABASE IF NOT EXISTS `toDb` CHARACTER SET "utf8" COLLATE "utf8_general_ci"\' : echo "db created"' \
    "\* --connect-timeout=5 --batch --raw --default-character-set=utf8 -s --skip-column-names toDb : echo 'import structure dump'" \
    $'* --connect-timeout=5 --batch --raw --default-character-set=utf8  toDb : i=0 ; while read line; do ((i=i+1)); echo "line $i"; done < /dev/stdin'

  run "${binDir}/dbImport" -f default.local fromDb toDb --tables dataTable,otherTable 2>&1
  assert_output --partial "Import database duration : "
  assert_output --partial "ignore table emptyTable"
  assert_output --partial "begin insert dataTable"
  assert_output --partial "begin insert otherTable"
  [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz" ]]
  [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz" ]]
  # check files have been touched
  (($(date +%s) - $(stat -c "%Y" "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz") < 60))
  (($(date +%s) - $(stat -c "%Y" "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz") < 60))
}

function import_from_aws_with_tables_filter { #@test
  stub aws
  # create false dump 1 day in the past
  (cd "${BATS_TEST_DIRNAME}/data" && tar cvzf "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz" dump.sql)
  touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz"
  # call 5 (order 2): create target db (after dumps have been done)
  # call 7 (order 4): import data dump into db (read stdin to avoid sigpipe code 141)
  stub mysql \
    $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \'CREATE DATABASE IF NOT EXISTS `toDb` CHARACTER SET "utf8" COLLATE "utf8_general_ci"\' : echo "db created"' \
    $'* --connect-timeout=5  --batch --raw --default-character-set=utf8 toDb : i=0 ; while read line; do ((i=i+1)); echo "line $i"; done < /dev/stdin'
  run "${binDir}/dbImport" --from-aws fromDb.tar.gz toDb --tables dataTable,otherTable 2>&1

  assert_output --partial "Import database duration : "
  assert_output --partial "ignore table emptyTable"
  assert_output --partial "begin insert dataTable"
  assert_output --partial "begin insert otherTable"
  [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz" ]]
  # check files have been touched
  (($(date +%s) - $(stat -c "%Y" "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz") < 60))
}
