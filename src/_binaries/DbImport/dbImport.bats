#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"
  export HOME="${BATS_TEST_TMPDIR}/home"

  mkdir -p "${HOME}"
  mkdir -p \
    "${HOME}/bin" \
    "${HOME}/.bash-tools/dsn" \
    "${HOME}/.bash-tools/dbImportDumps" \
    "${HOME}/.bash-tools/dbImportProfiles"
  cp "${BATS_TEST_DIRNAME}/testsData/pv" "${HOME}/bin"
  cp "${BATS_TEST_DIRNAME}/testsData/gawk" "${HOME}/bin"
  cp "${BATS_TEST_DIRNAME}/testsData/gawk" "${HOME}/bin/awk"
  cp "${BATS_TEST_DIRNAME}/testsData/dbImportProfiles/"* "${HOME}/.bash-tools/dbImportProfiles/"
  cp "${BATS_TEST_DIRNAME}/testsData/dsn/"* "${HOME}/.bash-tools/dsn/"
  touch "${HOME}/bin/mysql" "${HOME}/bin/mysqldump" "${HOME}/bin/mysqlshow"
  chmod +x "${HOME}/bin/"*
  cp "${BATS_TEST_DIRNAME}/testsData/.env" "${HOME}/.bash-tools/.env"

  export DB_IMPORT_DUMP_DIR="${HOME}/.bash-tools/dbImportDumps"
  export BASH_FRAMEWORK_ENV_FILEPATH=${HOME}/.bash-tools/.env
  export PATH="${PATH}:${HOME}/bin"
  unset BASH_FRAMEWORK_INITIALIZED
}

teardown() {
  unstub_all
}

function Database::dbImport::display_help { #@test
  testCommand "${binDir}/dbImport" dbImport.help.txt
}

function Database::dbImport::remoteDbName_not_provided { #@test
  # shellcheck disable=SC2154
  run "${binDir}/dbImport" 2>&1
  assert_failure 1
  assert_lines_count 1
  assert_output --partial "ERROR   - Command dbImport - Argument 'fromDbName' should be provided at least 1 time(s)"
}

function Database::dbImport::from_aws_and_aws_not_installed { #@test
  run "${binDir}/dbImport" --from-aws fromAws fromDb
  assert_failure 1
  # if it fails, check you are running it from docker so aws command is not available
  assert_lines_count 3
  assert_line --index 0 --partial "INFO    - Using profile /tmp"
  assert_line --index 1 --partial "ERROR   - aws is not installed, please install it"
  assert_line --index 2 --partial "INFO    - Command dbImport - missing aws, please check https://docs.aws.amazon.com/fr_fr/cli/latest/userguide/install-cliv2.html"
}

function Database::dbImport::from_aws_and_from_dsn_are_incompatible { #@test
  stub aws
  run "${binDir}/dbImport" --from-dsn default --from-aws fromAws fromDb 2>&1
  assert_failure 1
  assert_lines_count 2
  assert_line --index 0 --partial "INFO    - Using profile /tmp"
  assert_line --index 1 --partial "FATAL   - Command dbImport - you cannot use from-dsn and from-aws at the same time"
}

function Database::dbImport::from_aws_missing_S3_BASE_URL { #@test
  stub aws
  sed -i -E 's#^S3_BASE_URL=.*$##g' "${HOME}/.bash-tools/.env"
  run "${binDir}/dbImport" --from-aws fromAws fromDb 2>&1
  assert_failure 1
  assert_lines_count 2
  assert_line --index 0 --partial "INFO    - Using profile /tmp"
  assert_line --index 1 --partial "FATAL   - Command dbImport - missing S3_BASE_URL, please provide a value in .env file"
}

function Database::dbImport::a_and_f_are_incompatible { #@test
  stub aws
  run "${binDir}/dbImport" -f default -a fromAws fromDb 2>&1
  assert_failure 1
  assert_lines_count 2
  assert_line --index 0 --partial "INFO    - Using profile /tmp"
  assert_line --index 1 --partial "FATAL   - Command dbImport - you cannot use from-dsn and from-aws at the same time"
}

function Database::dbImport::missing_aws { #@test
  # missing argument
  run "${binDir}/dbImport" -a fromAws fromDb --verbose 2>&1
  assert_failure 1
  assert_lines_count 3
  assert_line --index 0 --partial "INFO    - Using profile /tmp"
  assert_line --index 1 --partial "ERROR   - aws is not installed, please install it"
  assert_line --index 2 --partial "INFO    - Command dbImport - missing aws, please check"
}

function Database::dbImport::tables_invalid { #@test
  stub aws

  export BASH_FRAMEWORK_ENV_FILEPATH="${BATS_TEST_DIRNAME}/testsData/.env"

  # missing argument
  run "${binDir}/dbImport" -a fromAws fromDb --tables 2>&1
  assert_failure 1
  assert_output --partial "ERROR   - Command dbImport - Option --tables - a value needs to be specified"

  # invalid argument
  run "${binDir}/dbImport" -a fromAws fromDb --tables ddd@ 2>&1
  assert_failure 1
  assert_output --partial "FATAL   - Command dbImport - Table list is not valid : ddd@"

  # invalid argument
  run "${binDir}/dbImport" -a fromAws fromDb --tables ddd, 2>&1
  assert_failure 1
  assert_output --partial "FATAL   - Command dbImport - Table list is not valid : ddd,"

  # invalid argument
  run "${binDir}/dbImport" -a fromAws fromDb --tables ddd,dd, 2>&1
  assert_failure 1
  assert_output --partial "FATAL   - Command dbImport - Table list is not valid : ddd,dd,"

  # invalid argument
  run "${binDir}/dbImport" -a fromAws fromDb --tables ddd- 2>&1
  assert_failure 1
  assert_output --partial "FATAL   - Command dbImport - Table list is not valid : ddd-"
}

function Database::dbImport::aws_file_not_found { #@test
  stub aws \
    "s3 ls --human-readable s3://s3server/exports/fromAws.tar.gz : exit 1"

  export BASH_FRAMEWORK_ENV_FILEPATH="${BATS_TEST_DIRNAME}/testsData/.env"

  run "${binDir}/dbImport" -a fromAws.tar.gz fromDb 2>&1
  assert_failure 1
  assert_output --partial "FATAL   - Command dbImport - unable to get information on S3 object : s3://s3server/exports/fromAws.tar.gz"
}

function Database::dbImport::dsn_file_not_found { #@test
  run "${binDir}/dbImport" -f notFound fromDb
  assert_output --partial "ERROR   - conf file 'notFound' not found"
}

function Database::dbImport::remote_db_fully_functional_from_mysql { #@test
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
    "\* : cat ${BATS_TEST_DIRNAME}/testsData/dumpMissingSchema.sql"

  export BASH_FRAMEWORK_ENV_FILEPATH="${BATS_TEST_DIRNAME}/testsData/.env"

  run "${binDir}/dbImport" --verbose -f default.local fromDb toDb 2>&1
  unstub_all
  assert_output --partial "Import database duration : "
  assert_output --partial "begin insert emptyTable"
  assert_output --partial "begin insert dataTable"
  assert_output --partial "begin insert otherTable"
  [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz" ]]
  [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz" ]]
  [[ "$(zcat "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz" | grep '####data####')" = "####data####" ]]
  [[ "$(zcat "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz" | grep '####structure####')" = "####structure####" ]]
}

function Database::dbImport::remote_db_dump_already_present_from_db { #@test
  # change modification date 32 days in the past
  touch -d@$(($(date +%s) - 32 * 86400)) "${HOME}/.bash-tools/dbImportDumps/oldDump.sql.gz"
  # change modification date 1 day in the future
  touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/dumpInTheFuture.sql.gz"
  # create false dump 1 day in the past
  gzip <"${BATS_TEST_DIRNAME}/testsData/dumpMissingSchema.sql" >"${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz"
  gzip <"${BATS_TEST_DIRNAME}/testsData/dumpSchema.sql" >"${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz"
  touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz"
  touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz"
  # call 5 (order 2): create target db (after dumps have been done)
  # call 6 (order 3): import structure dump into db
  # call 7 (order 4): import data dump into db
  stub mysql \
    $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \'CREATE DATABASE IF NOT EXISTS `toDb` CHARACTER SET "utf8" COLLATE "utf8_general_ci"\' : echo "db created"' \
    "\* --connect-timeout=5 --batch --raw --default-character-set=utf8 -s --skip-column-names toDb : echo 'import structure dump'" \
    $'* --connect-timeout=5 --batch --raw --default-character-set=utf8 toDb : i=0 ; while read line; do ((i=i+1)); echo "line $i"; done < /dev/stdin'

  export BASH_FRAMEWORK_ENV_FILEPATH="${BATS_TEST_DIRNAME}/testsData/.env"

  run "${binDir}/dbImport" --verbose -f default.local fromDb toDb 2>&1

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

function Database::dbImport::remote_db_fully_functional_from_aws { #@test

  stub aws \
    's3 ls --human-readable s3://s3server/exports/fromDb.tar.gz : exit 0' \
    "s3 cp s3://s3server/exports/fromDb.tar.gz '${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz' : touch '${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz'; exit 0"
  stub tar \
    "xOfz '${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz' : cat '${BATS_TEST_DIRNAME}/testsData/dump.sql'"

  # call 5 (order 9): create target db
  # call 7 (order 11): import data dump into db
  stub mysql \
    $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \'CREATE DATABASE IF NOT EXISTS `toDb` CHARACTER SET "utf8" COLLATE "utf8_general_ci"\' : echo "db created"' \
    $'* --connect-timeout=5  --batch --raw --default-character-set=utf8 toDb : i=0 ; while read line; do ((i=i+1)); echo "line $i"; done < /dev/stdin'

  export BASH_FRAMEWORK_ENV_FILEPATH="${BATS_TEST_DIRNAME}/testsData/.env"

  run "${binDir}/dbImport" --verbose --from-aws fromDb.tar.gz toDb 2>&1

  assert_output --partial "Import database duration : "
  assert_output --partial "begin insert emptyTable"
  assert_output --partial "begin insert dataTable"
  assert_output --partial "begin insert otherTable"
}

function Database::dbImport::remote_db_dump_already_present_from_aws { #@test
  stub aws
  # create false dump 1 day in the past
  tar cvzf "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz" "${BATS_TEST_DIRNAME}/testsData/dump.sql"
  touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz"
  # call 5 (order 2): create target db (after dumps have been done)
  # call 7 (order 4): import data dump into db
  stub mysql \
    $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \'CREATE DATABASE IF NOT EXISTS `toDb` CHARACTER SET "utf8" COLLATE "utf8_general_ci"\' : echo "db created"' \
    $'* --connect-timeout=5  --batch --raw --default-character-set=utf8 toDb : i=0 ; while read line; do ((i=i+1)); echo "line $i"; done < /dev/stdin'

  export BASH_FRAMEWORK_ENV_FILEPATH="${BATS_TEST_DIRNAME}/testsData/.env"

  run "${binDir}/dbImport" --verbose --from-aws fromDb.tar.gz toDb 2>&1

  assert_output --partial "Import database duration : "
  assert_output --partial "begin insert emptyTable"
  assert_output --partial "begin insert dataTable"
  assert_output --partial "begin insert otherTable"
  [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz" ]]
  # check files have been touched
  (($(date +%s) - $(stat -c "%Y" "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz") < 60))
}

function Database::dbImport::import_local_dump_not_aws_with_tables_filter { #@test
  # create false dump 1 day in the past
  gzip <"${BATS_TEST_DIRNAME}/testsData/dumpMissingSchema.sql" >"${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz"
  gzip <"${BATS_TEST_DIRNAME}/testsData/dumpSchema.sql" >"${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz"
  touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz"
  touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz"
  # call 5 (order 2): create target db (after dumps have been done)
  # call 6 (order 3): import structure dump into db
  # call 7 (order 4): import data dump into db
  stub mysql \
    $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \'CREATE DATABASE IF NOT EXISTS `toDb` CHARACTER SET "utf8" COLLATE "utf8_general_ci"\' : echo "db created"' \
    "\* --connect-timeout=5 --batch --raw --default-character-set=utf8 -s --skip-column-names toDb : echo 'import structure dump'" \
    $'* --connect-timeout=5 --batch --raw --default-character-set=utf8  toDb : i=0 ; while read line; do ((i=i+1)); echo "line $i"; done < /dev/stdin'

  run "${binDir}/dbImport" --verbose -f default.local fromDb toDb --tables dataTable,otherTable 2>&1
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

function Database::dbImport::import_from_aws_with_tables_filter { #@test
  stub aws
  # create false dump 1 day in the past
  (cd "${BATS_TEST_DIRNAME}/testsData" && tar cvzf "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz" dump.sql)
  touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz"
  # call 5 (order 2): create target db (after dumps have been done)
  # call 7 (order 4): import data dump into db (read stdin to avoid sigpipe code 141)
  stub mysql \
    $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \'CREATE DATABASE IF NOT EXISTS `toDb` CHARACTER SET "utf8" COLLATE "utf8_general_ci"\' : echo "db created"' \
    $'* --connect-timeout=5  --batch --raw --default-character-set=utf8 toDb : i=0 ; while read line; do ((i=i+1)); echo "line $i"; done < /dev/stdin'

  export BASH_FRAMEWORK_ENV_FILEPATH="${BATS_TEST_DIRNAME}/testsData/.env"

  run "${binDir}/dbImport" --verbose --from-aws fromDb.tar.gz toDb --tables dataTable,otherTable 2>&1
  assert_output --partial "Import database duration : "
  assert_output --partial "ignore table emptyTable"
  assert_output --partial "begin insert dataTable"
  assert_output --partial "begin insert otherTable"
  [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz" ]]
  # check files have been touched
  (($(date +%s) - $(stat -c "%Y" "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz") < 60))
}
