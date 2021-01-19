#!/usr/bin/env bash

declare -g toolsDir="$( cd "${BATS_TEST_DIRNAME}/../../bin" && pwd )"
declare -g vendorDir="$( cd "${BATS_TEST_DIRNAME}/../../vendor" && pwd )"

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
        touch bin/mysql bin/mysqldump bin/mysqlshow
        chmod +x bin/*
    )
    export PATH="$PATH:/tmp/home/bin"
}

teardown() {
    rm -Rf /tmp/home || true
    unstub_all
}

@test "${BATS_TEST_FILENAME#/bash/tests/} display help" {
    run ${toolsDir}/dbImportTable --help 2>&1
    [[ "${lines[2]}" = "${__HELP_TITLE}Usage:${__HELP_NORMAL} dbImportTable <remoteDbName> <tableName> [<localDbName>] " ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote DbName not provided" {
    run ${toolsDir}/dbImportTable  2>&1
    [[ "${output}" == *"FATAL - you must provide remoteDbName"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote TableName not provided" {
    run ${toolsDir}/dbImportTable fromDb 2>&1
    [[ "${output}" == *"FATAL - you must provide tableName"* ]]
}


@test "${BATS_TEST_FILENAME#/bash/tests/} --from-aws and --from-dsn are incompatible" {
    run ${toolsDir}/dbImportTable --from-dsn default --from-aws fromDb tableName 2>&1
    [[ "${output}" == *"FATAL - you cannot use from-dsn and from-aws at the same time"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} --from-aws missing S3_BASE_URL" {
    run ${toolsDir}/dbImportTable --from-aws fromDb tableName 2>&1
    [[ "${output}" == *"FATAL - missing S3_BASE_URL, please provide a value in .env file"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} -a and -f are incompatible" {
    run ${toolsDir}/dbImportTable -f default -a fromDb tableName 2>&1
    [[ "${output}" == *"FATAL - you cannot use from-dsn and from-aws at the same time"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} dsn file not found" {
    run ${toolsDir}/dbImportTable -f notFound fromDb tableName
    [[ "${output}" == *"ERROR - conf file 'notFound' not found"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote db(fromDb) doesn't exist" {
    # call 1: check if target db exists to know if it should be created, no error
    # call 2: check if from db exists, this time we answer no
    stub mysqlshow \
        '* * toDb : echo ""' 
        
    run ${toolsDir}/dbImportTable -f default.local fromDb tableName toDb 2>&1
        
    [[ "${output}" == *"FATAL - Target Database toDb does not exist !"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote db(fromDb) fully functional" {
    # call 1 (order 1): check if target db exists to know if it should be created, no error
    # call 2 (order 4): check if from db exists, answers yes
    stub mysqlshow \
        '* * toDb : echo "Database: toDb"' \
        '* * fromDb : echo "Database: fromDb"' 
    
    # call 1 (order 2) check if remote table exists
    # call 2 (order 3): from db default_character_set_name
    # call 3 (order 5): from db table size
    # call 4 (order 7): import dump
    stub mysql \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \* : echo \$9 > /tmp/home/isTableExists ;echo '0'" \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names information_schema -e 'SELECT default_character_set_name FROM information_schema.SCHEMATA WHERE schema_name = \"fromDb\";' : echo 'charset';" \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names : cat - > /tmp/home/tableSize.sql ; echo '50'" \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names toDb : cat - > /tmp/home/dump.sql; "
    
    # call 1 (order 6): dump table
    stub mysqldump \
        "\* --default-character-set=utf8 --compress --hex-blob --routines --triggers --single-transaction --set-gtid-purged=OFF --column-statistics=0 --ssl-mode=DISABLED --skip-add-drop-table --single-transaction=TRUE fromDb tableName : echo 'CREATE TABLE \`tableName\`'"

    run ${toolsDir}/dbImportTable -f default.local fromDb tableName toDb
    
    [[ "${output}" == *"Import table duration : "* ]]
    [[ -f "/tmp/home/isTableExists" ]]
    [[ "$(cat /tmp/home/isTableExists | md5sum)" = "$(cat ${BATS_TEST_DIRNAME}/data/isTableExistsQuery.sql | md5sum)" ]]
    [[ -f "/tmp/home/tableSize.sql" ]]
    [[ "$(cat /tmp/home/tableSize.sql | md5sum)" = "$(cat ${BATS_TEST_DIRNAME}/data/tableSizeQuery.sql | md5sum)" ]]
    [[ -f "/tmp/home/dump.sql" ]]
    [[ "$(cat /tmp/home/dump.sql | md5sum)" = "$(cat ${BATS_TEST_DIRNAME}/data/tableDump.sql | md5sum)" ]]
    [[ -f "/tmp/home/.bash-tools/dbImportDumps/importTable_fromDb_tableName.sql" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote db(fromDb) local table already present" {
    # call 1 (order 1): check if target db exists to know if it should be created, no error
    stub mysqlshow \
        '* * toDb : echo "Database: toDb"'
    
    # call 1 (order 2) check if remote table exists
    stub mysql \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \* : echo \$9 > /tmp/home/isTableExists ;echo '1'" 
    
    run ${toolsDir}/dbImportTable -f default.local fromDb tableName toDb
    
    [[ "${output}" == *"FATAL - use --force to drop it"* ]]
    [[ -f "/tmp/home/isTableExists" ]]
    [[ "$(cat /tmp/home/isTableExists | md5sum)" = "$(cat ${BATS_TEST_DIRNAME}/data/isTableExistsQuery.sql | md5sum)" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} target db does not exists" {
    # call 1 (order 1): check if target db exists
    stub mysqlshow \
        '* * toDb : echo ""'
    
    run ${toolsDir}/dbImportTable -f default.local fromDb tableName toDb
    
    [[ "${output}" == *"FATAL - Target Database toDb does not exist !"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote db(fromDb) local tableName exists but --force" {
    # call 1 (order 1): check if target db exists to know if it should be created, no error
    # call 2 (order 4): check if from db exists, answers yes
    stub mysqlshow \
        '* * toDb : echo "Database: toDb"' \
        '* * fromDb : echo "Database: fromDb"' 
    
    # call 1 (order 2) check if remote table exists
    # call 2 (order 3) drop target table
    # call 2 (order 3): from db default_character_set_name
    # call 3 (order 5): from db table size
    # call 4 (order 7): import dump
    stub mysql \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \* : echo \$9 > /tmp/home/isTableExists ;echo '1'" \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names toDb -e 'DROP TABLE IF EXISTS tableName' : " \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names information_schema -e 'SELECT default_character_set_name FROM information_schema.SCHEMATA WHERE schema_name = \"fromDb\";' : echo 'charset';" \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names : cat - > /tmp/home/tableSize.sql ; echo '50'" \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names toDb : cat - > /tmp/home/dump.sql; "
    
    # call 1 (order 6): dump table
    stub mysqldump \
        "\* --default-character-set=utf8 --compress --hex-blob --routines --triggers --single-transaction --set-gtid-purged=OFF --column-statistics=0 --ssl-mode=DISABLED --skip-add-drop-table --single-transaction=TRUE fromDb tableName : echo 'CREATE TABLE \`tableName\`'"

    run ${toolsDir}/dbImportTable --force -f default.local fromDb tableName toDb
    
    [[ "${output}" == *"Import table duration : "* ]]
    [[ -f "/tmp/home/isTableExists" ]]
    [[ "$(cat /tmp/home/isTableExists | md5sum)" = "$(cat ${BATS_TEST_DIRNAME}/data/isTableExistsQuery.sql | md5sum)" ]]
    [[ -f "/tmp/home/tableSize.sql" ]]
    [[ "$(cat /tmp/home/tableSize.sql | md5sum)" = "$(cat ${BATS_TEST_DIRNAME}/data/tableSizeQuery.sql | md5sum)" ]]
    [[ -f "/tmp/home/dump.sql" ]]
    [[ "$(cat /tmp/home/dump.sql | md5sum)" = "$(cat ${BATS_TEST_DIRNAME}/data/tableDump.sql | md5sum)" ]]
    [[ -f "/tmp/home/.bash-tools/dbImportDumps/importTable_fromDb_tableName.sql" ]]
}


@test "${BATS_TEST_FILENAME#/bash/tests/} remote db(fromDb) dump already present" {
    touch "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql"
    touch "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql"
    # call 1 (order 1): check if target db exists to know if it should be created, no error
    stub mysqlshow \
        '* * toDb : echo ""' 
    # call 5 (order 2): create target db (after dumps have been done)
    # call 6 (order 3): import structure dump into db
    # call 7 (order 4): import data dump into db
    stub mysql \
        $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \'CREATE DATABASE `toDb` CHARACTER SET "utf8" COLLATE "utf8_general_ci"\' : echo "db created"' \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names toDb : echo 'import structure dump'" \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names toDb : echo 'import data dump'"
    
    run ${toolsDir}/dbImport -f default.local fromDb toDb 2>&1
    [[ "${output}" == *"Import database duration : "* ]]
    [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql" ]]
    [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql" ]]
}
