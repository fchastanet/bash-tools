#!/usr/bin/env bash

declare -g toolsDir="$( cd "${BATS_TEST_DIRNAME}/../../bin" && pwd )"
declare -g vendorDir="$( cd "${BATS_TEST_DIRNAME}/../../vendor" && pwd )"

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
    run ${toolsDir}/dbImport --help 2>&1
    [[ "${output}" == *"Description: Import source db into target db"* ]]
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
    run ${toolsDir}/dbImport --from-aws fromDb 2>&1
    [[ "${output}" == *"FATAL - missing S3_BASE_URL, please provide a value in .env file"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} -a and -f are incompatible" {
    run ${toolsDir}/dbImport -f default -a fromDb 2>&1
    [[ "${output}" == *"FATAL - you cannot use from-dsn and from-aws at the same time"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} dsn file not found" {
    run ${toolsDir}/dbImport -f notFound fromDb 2>&1
    [[ "${output}" == *"ERROR - dsn file notFound not found"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote db(fromDb) doesn't exist" {
    # call 1: check if target db exists to know if it should be created, no error
    # call 2: check if from db exists, this time we answer no
    stub mysqlshow \
        '* * toDb : echo ""' \
        '* * fromDb : echo ""' 
    run ${toolsDir}/dbImport -f default.local fromDb toDb 2>&1
    [[ "${output}" == *"FATAL - Remote Database fromDb does not exist"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote db(fromDb) fully functional" {
    # call 1 (order 1): check if target db exists to know if it should be created, no error
    # call 2 (order 2): check if from db exists, answers yes
    stub mysqlshow \
        '* * toDb : echo ""' \
        '* * fromDb : echo "Database: fromDb"' 
    # call 1 (order 3): from db default_collation_name
    # call 2 (order 4): from db default_character_set_name
    # call 3 (order 5): from db list tables
    # call 4 (order 6): estimate dump size
    # call 5 (order 9): create target db (after dumps have been done)
    # call 6 (order 10): import structure dump into db
    # call 7 (order 11): import data dump into db
    stub mysql \
        "\* \* \* \* information_schema -e 'SELECT default_collation_name FROM information_schema.SCHEMATA WHERE schema_name = \"fromDb\";' : echo 'collation'" \
        "\* \* \* \* information_schema -e 'SELECT default_character_set_name FROM information_schema.SCHEMATA WHERE schema_name = \"fromDb\";' : echo 'charset'" \
        "\* \* \* \* fromDb -e 'show tables' : echo 'table1'" \
        "\* -s --skip-column-names --connect-timeout=5 : echo '100'" \
        "\* -s --skip-column-names --connect-timeout=5 -e 'CREATE DATABASE \`toDb\` CHARACTER SET \"charset\" COLLATE \"collation\"' : echo 'db created'" \
        "\* -s --skip-column-names --connect-timeout=5 toDb : echo 'import structure dump'" \
        "\* -s --skip-column-names --connect-timeout=5 toDb : echo 'import data dump'"

    # call 1 (order 7): dump data
    # call 2 (order 8): dump structure
    stub mysqldump \
        "\* --default-character-set=utf8 --compress --compact --hex-blob --routines --triggers --single-transaction --set-gtid-purged=OFF --column-statistics=0 --ssl-mode=DISABLED --no-create-info --skip-add-drop-table --single-transaction=TRUE fromDb 'table1' : echo '####data####'" \
        "\* --default-character-set=utf8 --compress --compact --hex-blob --routines --triggers --single-transaction --set-gtid-purged=OFF --column-statistics=0 --ssl-mode=DISABLED --no-data --skip-add-drop-table --single-transaction=TRUE fromDb : echo '####structure####'"

    run ${toolsDir}/dbImport -f default.local fromDb toDb 2>&1 
    [[ "${output}" == *"Import database duration : "* ]]
    [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql" ]]
    [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql" ]]
    [[ "$(cat "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql" | grep '####data####')" = "####data####" ]]
    [[ "$(cat "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql" | grep '####structure####')" = "####structure####" ]]
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
        "\* -s --skip-column-names --connect-timeout=5 -e 'CREATE DATABASE \`toDb\` CHARACTER SET \"utf8\" COLLATE \"utf8_general_ci\"' : echo 'db created'" \
        "\* -s --skip-column-names --connect-timeout=5 toDb : echo 'import structure dump'" \
        "\* -s --skip-column-names --connect-timeout=5 toDb : echo 'import data dump'"
    
    run ${toolsDir}/dbImport -f default.local fromDb toDb 2>&1
    [[ "${output}" == *"Import database duration : "* ]]
    [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql" ]]
    [[ -f "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql" ]]
}
