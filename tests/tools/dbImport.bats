#!/usr/bin/env bash

declare -g rootDir="$( cd "${BATS_TEST_DIRNAME}/../.." && pwd )"
declare -g toolsDir="${rootDir}/bin"
declare -g vendorDir="${rootDir}/vendor"

# shellcheck source=bash-framework/Constants.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/Constants.sh" || exit 1

load "${vendorDir}/bats-mock-Flamefire/load.bash"

setup() {
    export HOME="/tmp/home"
    (
        mkdir -p "${HOME}" 
        cd "${HOME}"
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
    export PATH="$PATH:/tmp/home/bin"
}

teardown() {
    rm -Rf /tmp/home || true
    unstub_all
}

@test "${BATS_TEST_FILENAME#/bash/tests/} display help" {
    run ${toolsDir}/dbImport --help 2>&1
    [[ "${lines[0]}" = "${__HELP_TITLE}Description:${__HELP_NORMAL} Import source db into target db" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remoteDbName not provided" {
    run ${toolsDir}/dbImport  2>&1
    [[ "${output}" == *"FATAL - you must provide remoteDbName"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} --from-aws and --from-dsn are incompatible" {
    run ${toolsDir}/dbImport --from-dsn default --from-aws fromDb 2>&1
    [[ "${output}" == *"FATAL - you cannot use from-dsn and from-aws at the same time"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} --from-aws missing S3_BASE_URL" {
    sed -i -E 's#^S3_BASE_URL=.*$##g' "${HOME}/.bash-tools/.env"
    run ${toolsDir}/dbImport --from-aws fromDb 2>&1
    [[ "${output}" == *"FATAL - missing S3_BASE_URL, please provide a value in .env file"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} -a and -f are incompatible" {
    run ${toolsDir}/dbImport -f default -a fromDb 2>&1
    [[ "${output}" == *"FATAL - you cannot use from-dsn and from-aws at the same time"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} dsn file not found" {
    run ${toolsDir}/dbImport -f notFound fromDb
    [[ "${output}" == *"ERROR - conf file 'notFound' not found"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote db(fromDb) fully functional" {
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
        "\* --connect-timeout=5 --batch --raw --default-character-set=utf8 -s --skip-column-names toDb : echo 'import data dump'"

    # call 1 (order 7): dump data
    # call 2 (order 8): dump structure
    stub mysqldump \
        "\* --default-character-set=utf8 --compress --hex-blob --routines --triggers --single-transaction --set-gtid-purged=OFF --column-statistics=0 --ssl-mode=DISABLED --no-create-info --skip-add-drop-table --single-transaction=TRUE fromDb 'table1 ' : echo '####data####'" \
        "\* --default-character-set=utf8 --compress --hex-blob --routines --triggers --single-transaction --set-gtid-purged=OFF --column-statistics=0 --ssl-mode=DISABLED --no-data --skip-add-drop-table --single-transaction=TRUE fromDb : echo '####structure####'"

    run ${toolsDir}/dbImport -f default.local fromDb toDb 2>&1 
    [[ "${output}" == *"Import database duration : "* ]]
    [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz" ]]
    [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz" ]]
    [[ "$(zcat "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz" | grep '####data####')" = "####data####" ]]
    [[ "$(zcat "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz" | grep '####structure####')" = "####structure####" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote db(fromDb) dump already present" {
    # change modification date 32 days in the past
    touch -d@$(($(date +%s) - 32*86400)) "${HOME}/.bash-tools/dbImportDumps/oldDump.sql.gz"
    # change modification date 1 day in the future
    touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/dumpInTheFuture.sql.gz"
    # create false dump 1 day in the past
    echo "data" | gzip > "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz"
    echo "structure" | gzip > "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz"
    touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz"
    touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz"
    # call 5 (order 2): create target db (after dumps have been done)
    # call 6 (order 3): import structure dump into db
    # call 7 (order 4): import data dump into db
    stub mysql \
        $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \'CREATE DATABASE IF NOT EXISTS `toDb` CHARACTER SET "utf8" COLLATE "utf8_general_ci"\' : echo "db created"' \
        "\* --connect-timeout=5 --batch --raw --default-character-set=utf8 -s --skip-column-names toDb : echo 'import structure dump'" \
        "\* --connect-timeout=5 --batch --raw --default-character-set=utf8 -s --skip-column-names toDb : echo 'import data dump'"
    
    run ${toolsDir}/dbImport -f default.local fromDb toDb 2>&1

    [[ "${output}" == *"Import database duration : "* ]]
    [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz" ]]
    [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz" ]]
    # check files have been touched
    (( $(date +%s) - $(stat -c "%Y" "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql.gz") < 60 ))
    (( $(date +%s) - $(stat -c "%Y" "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql.gz") < 60 ))
    # check garbage
    [[ -f "${HOME}/.bash-tools/dbImportDumps/dumpInTheFuture.sql.gz" ]]
    [[ ! -f "${HOME}/.bash-tools/dbImportDumps/oldDump.sql.gz" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote db(fromDb) fully functional from aws" {
    
    stub aws \
        's3 ls --human-readable s3://s3server/exports/fromDb.tar.gz : exit 0' \
        's3 cp s3://s3server/exports/fromDb.tar.gz /tmp/home/.bash-tools/dbImportDumps/fromDb.tar.gz : exit 0'
    stub tar \
        "xOfz /tmp/home/.bash-tools/dbImportDumps/fromDb.tar.gz : cat ${BATS_TEST_DIRNAME}/data/empty-dump.sql"
    stub awk \
        '-v PROFILE_COMMAND=/bash/conf/dbImportProfiles/default.sh -v CHARACTER_SET=utf8 -f /bash/bin/dbImportStream.awk - : exit 0'    
    
    # call 5 (order 9): create target db
    # call 7 (order 11): import data dump into db
    stub mysql \
        $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \'CREATE DATABASE IF NOT EXISTS `toDb` CHARACTER SET "utf8" COLLATE "utf8_general_ci"\' : echo "db created"' \
        "\* --connect-timeout=5  --batch --raw --default-character-set=utf8 toDb : echo 'import dump'"

    run ${toolsDir}/dbImport --from-aws fromDb.tar.gz toDb 2>&1 
    [[ "${output}" == *"Import database duration : "* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote db(fromDb) dump already present from aws" {
    # create false dump 1 day in the past
    echo "data" | gzip > "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz"
    touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz"
    # call 5 (order 2): create target db (after dumps have been done)
    # call 7 (order 4): import data dump into db
    stub mysql \
        $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \'CREATE DATABASE IF NOT EXISTS `toDb` CHARACTER SET "utf8" COLLATE "utf8_general_ci"\' : echo "db created"' \
        "\* --connect-timeout=5  --batch --raw --default-character-set=utf8 toDb : echo 'import data dump'"
    
    run ${toolsDir}/dbImport --from-aws fromDb.tar.gz toDb 2>&1
    [[ "${output}" == *"Import database duration : "* ]]
    [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz" ]]
    # check files have been touched
    (( $(date +%s) - $(stat -c "%Y" "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz") < 60 ))
}
