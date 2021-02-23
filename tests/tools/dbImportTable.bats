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
        cp "${rootDir}/conf/.env" .bash-tools/.env
        sed -i -E 's#^S3_BASE_URL=.*$#S3_BASE_URL=s3://s3server/exports/#g' .bash-tools/.env
        chmod +x bin/*
    )
    export PATH="/tmp/home/bin:$PATH"
}

teardown() {
    rm -Rf /tmp/home || true
    unstub_all
}

@test "${BATS_TEST_FILENAME#/bash/tests/} display help" {
    run ${toolsDir}/dbImportTable --help 2>&1
    [[ "${lines[2]}" = "${__HELP_TITLE}Usage:${__HELP_NORMAL} dbImportTable <fromDbName> <tableName> [<targetDbName>] [<targetTableName>]" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} invalid gawk version" {
    stub gawk \
        '--version : echo "GNU Awk 4.0.1, API: 2.0 (GNU MPFR 4.1.0, GNU MP 6.2.0)"'
    stub mysqlshow
    stub mysql
    stub mysqldump
    run ${toolsDir}/dbImportTable 2>&1
    
    [[ "${lines[0]}" == *"FATAL - gawk minimal version is 5.0.1, your version is 4.0.1"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} missing mysql" {
    stub mysqlshow
    stub mysqldump
    run ${toolsDir}/dbImportTable 2>&1
    [[ "${lines[0]}" == *"ERROR - mysql is not installed, please install it"* ]]
    [[ "${lines[1]}" == *"INFO  - sudo apt-get install -y mysql-client"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} missing mysqlshow" {
    stub mysql
    stub mysqldump
    run ${toolsDir}/dbImportTable 2>&1
    [[ "${lines[0]}" == *"ERROR - mysqlshow is not installed, please install it"* ]]
    [[ "${lines[1]}" == *"INFO  - sudo apt-get install -y mysql-client"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} missing mysqldump" {
    stub mysqlshow
    stub mysql
    run ${toolsDir}/dbImportTable 2>&1
    [[ "${lines[0]}" == *"ERROR - mysqldump is not installed, please install it"* ]]
    [[ "${lines[1]}" == *"INFO  - sudo apt-get install -y mysql-client"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote DbName not provided" {
    stub mysqlshow
    stub mysql
    stub mysqldump
    run ${toolsDir}/dbImportTable  2>&1
    [[ "${output}" == *"FATAL - you must provide fromDbName"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote TableName not provided" {
    stub mysqlshow
    stub mysql
    stub mysqldump
    run ${toolsDir}/dbImportTable fromDb 2>&1
    [[ "${output}" == *"FATAL - you must provide tableName"* ]]
}


@test "${BATS_TEST_FILENAME#/bash/tests/} --from-aws and --from-dsn are incompatible" {
    stub mysqlshow
    stub mysql
    stub mysqldump
    run ${toolsDir}/dbImportTable --from-dsn default --from-aws fromDb tableName 2>&1
    [[ "${output}" == *"FATAL - you cannot use from-dsn and from-aws at the same time"* ]]
}


@test "${BATS_TEST_FILENAME#/bash/tests/} --from-aws and --from-dsn are incompatible shortcut" {
    stub mysqlshow
    stub mysql
    stub mysqldump
    run ${toolsDir}/dbImportTable -f default -a fromDb tableName 2>&1
    [[ "${output}" == *"FATAL - you cannot use from-dsn and from-aws at the same time"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} --from-aws missing S3_BASE_URL" {
    stub mysqlshow
    stub mysql
    stub mysqldump
    sed -i -E 's#^S3_BASE_URL=.*$#S3_BASE_URL=#g' "${HOME}/.bash-tools/.env"
    run ${toolsDir}/dbImportTable --from-aws fromDb tableName 2>&1

    [[ "${output}" == *"FATAL - missing S3_BASE_URL, please provide a value in .env file"* ]]
    run ${toolsDir}/dbImportTable -a fromDb tableName 2>&1
    [[ "${output}" == *"FATAL - missing S3_BASE_URL, please provide a value in .env file"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} -a and -f are incompatible" {
    stub mysqlshow
    stub mysql
    stub mysqldump

    run ${toolsDir}/dbImportTable -f default -a fromDb tableName 2>&1

    [[ "${output}" == *"FATAL - you cannot use from-dsn and from-aws at the same time"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} dsn file not found" {
    stub mysqlshow
    stub mysql
    stub mysqldump

    run ${toolsDir}/dbImportTable -f notFound fromDb tableName
    [[ "${output}" == *"ERROR - conf file 'notFound' not found"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote db(fromDb) doesn't exist" {
    stub mysql
    stub mysqldump

    # call 1: check if target db exists to know if it should be created, no error
    # call 2: check if from db exists, this time we answer no
    stub mysqlshow \
        '* * toDb : echo ""' 
        
    run ${toolsDir}/dbImportTable -f default.local fromDb tableName toDb 2>&1
        
    [[ "${output}" == *"FATAL - Target Database toDb does not exist !"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote db(fromDb) fully functional" {
    stub mysqlshow \
        '* * toDb : echo "Database: toDb"' \
        '* * fromDb : echo "Database: fromDb"' 
    
    stub mysql \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \* : echo \$9 > /tmp/home/isTableExists ;echo '0'" \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names information_schema -e 'SELECT default_character_set_name FROM information_schema.SCHEMATA WHERE schema_name = \"fromDb\";' : echo 'charset';" \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names : cat - > /tmp/home/tableSize.sql ; echo '50'" \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names toDb : cat - > /tmp/home/dump.sql; "
    
    stub mysqldump \
        "\* --default-character-set=utf8 --compress --hex-blob --routines --triggers --single-transaction --set-gtid-purged=OFF --column-statistics=0 --ssl-mode=DISABLED --skip-add-drop-table --single-transaction=TRUE fromDb tableName : echo 'CREATE TABLE \`tableName\`'"

    run ${toolsDir}/dbImportTable -f default.local fromDb tableName toDb
    
    [[ "${output}" == *"Import table duration : "* ]]
    [[ -f "/tmp/home/isTableExists" ]]
    [[ "$(cat /tmp/home/isTableExists | md5sum)" = "$(cat ${BATS_TEST_DIRNAME}/data/isTableExistsQuery.sql | md5sum)" ]]
    [[ -f "/tmp/home/tableSize.sql" ]]
    [[ "$(cat /tmp/home/tableSize.sql | md5sum)" = "$(cat ${BATS_TEST_DIRNAME}/data/tableSizeQuery.sql | md5sum)" ]]
    [[ -f "/tmp/home/.bash-tools/dbImportDumps/importTable_fromDb_tableName.sql.gz" ]]
    [[ "$(zcat /tmp/home/.bash-tools/dbImportDumps/importTable_fromDb_tableName.sql.gz | md5sum)" = "$(cat ${BATS_TEST_DIRNAME}/data/tableDump.sql | md5sum)" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote db(fromDb) local table already present" {
    stub mysqldump
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
    stub mysql
    stub mysqldump

    # call 1 (order 1): check if target db exists
    stub mysqlshow \
        '* * toDb : echo ""'
    
    run ${toolsDir}/dbImportTable -f default.local fromDb tableName toDb
    
    [[ "${output}" == *"FATAL - Target Database toDb does not exist !"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote db(fromDb) local tableName exists but --force" {
    stub mysqlshow \
        '* * toDb : echo "Database: toDb"' \
        '* * fromDb : echo "Database: fromDb"' 

    stub mysql \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e \* : echo \$9 > /tmp/home/isTableExists ;echo '1'" \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names toDb -e 'DROP TABLE IF EXISTS tableName' : " \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names information_schema -e 'SELECT default_character_set_name FROM information_schema.SCHEMATA WHERE schema_name = \"fromDb\";' : echo 'charset';" \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names : cat - > /tmp/home/tableSize.sql ; echo '50'" \
        "\* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names toDb : cat - > /tmp/home/dump.sql; "
    
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
    [[ -f "/tmp/home/.bash-tools/dbImportDumps/importTable_fromDb_tableName.sql.gz" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote db(fromDb) dump already present" {
    touch "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql"
    touch "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql"
    stub mysqldump
    stub mysqlshow \
        '* * fromDb : echo "Database: fromDb"'
    stub mysql \
        $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e * : echo "$9" > /tmp/home/queryTableExists.sql && echo "1"' 
    
    run ${toolsDir}/dbImportTable -f default.local fromDb toDb 2>&1

    [[ "${output}" == *"INFO  - Target table fromDb/toDb already exists"* ]]
    [[ "${output}" == *"FATAL - use --force to drop it"* ]]
    [[ "${status}" == "1" ]]
    [[ "$(cat /tmp/home/queryTableExists.sql)" == "select count(*) from information_schema.tables where table_schema='fromDb' and table_name='toDb'" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} remote db(fromDb) dump already present with --force" {
    touch "${HOME}/.bash-tools/dbImportDumps/fromDb_default.sql"
    touch "${HOME}/.bash-tools/dbImportDumps/fromDb_default_structure.sql"
    stub mysqldump \
        "* --default-character-set=utf8 --compress --hex-blob --routines --triggers --single-transaction --set-gtid-purged=OFF --column-statistics=0 --ssl-mode=DISABLED --skip-add-drop-table --single-transaction=TRUE fromDb tableName : cat '${BATS_TEST_DIRNAME}/data/dump.sql'"
    stub mysqlshow \
        '* * toDb : echo "Database: toDb"' \
        '* * fromDb : echo "Database: fromDb"'
    stub mysql \
        $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e * : echo "$9" > /tmp/home/queryTableExists.sql && echo "1"' \
        $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names toDb -e * : echo "${10}" > /tmp/home/dropTable.sql && echo "1"' \
        $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names information_schema -e * : echo "${10}" > /tmp/home/characterSet.sql && echo "utf8"' \
        $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names : cat - > /tmp/home/tableSize.sql && echo "100"' \
        $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names toDb : cat - > /tmp/home/dump.sql'
    
    run ${toolsDir}/dbImportTable --force -f default.local fromDb tableName toDb 2>&1
    
    [[ "${output}" == *"Import table duration : "* ]]
    [[ "${status}" == "0" ]]
    [[ "$(cat /tmp/home/queryTableExists.sql)" == "select count(*) from information_schema.tables where table_schema='toDb' and table_name='tableName'" ]]
    [[ "$(cat /tmp/home/dropTable.sql)" == "DROP TABLE IF EXISTS tableName" ]]
    [[ "$(cat /tmp/home/characterSet.sql)" == 'SELECT default_character_set_name FROM information_schema.SCHEMATA WHERE schema_name = "fromDb";' ]]    
    [[ "$(cat /tmp/home/tableSize.sql)" == $'SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 0) AS size FROM information_schema.TABLES WHERE table_schema="fromDb" AND table_name=\'tableName\' GROUP BY table_schema' ]]
    grep -q 'SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS = 0;' /tmp/home/dump.sql ; [ $? -eq 0 ] 
}

@test "${BATS_TEST_FILENAME#/bash/tests/} from aws file not found" {
    stub mysqldump
    stub mysqlshow \
        '* * toDb : echo "Database: toDb"'
    stub aws \
        's3 cp s3://s3server/exports/fromDb.tar.gz /tmp/home/.bash-tools/dbImportDumps/fromDb.tar.gz : echo "fatal error: An error occurred (400) when calling the HeadObject operation: Bad Request"; exit 1'
    stub mysql \
        $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e * : echo "$9" > /tmp/home/queryTableExists.sql && echo "0"' 
    
    run ${toolsDir}/dbImportTable -a fromDb.tar.gz tableName toDb 2>&1
    [[ "${output}" == *"FATAL - unable to download dump from S3 : s3://s3server/exports/fromDb.tar.gz"* ]]
    [[ "$(cat /tmp/home/queryTableExists.sql)" == "select count(*) from information_schema.tables where table_schema='toDb' and table_name='tableName'" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} from aws empty dump/table not found" {
    stub mysqldump

    stub mysqlshow \
        '* * toDb : echo "Database: toDb"'
    stub aws \
        's3 cp s3://s3server/exports/fromDb.tar.gz /tmp/home/.bash-tools/dbImportDumps/fromDb.tar.gz : exit 0'
    stub tar \
        "xOfz /tmp/home/.bash-tools/dbImportDumps/fromDb.tar.gz : cat ${BATS_TEST_DIRNAME}/data/empty-dump.sql"
    stub mysql \
        $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e * : echo "$9" > /tmp/home/queryTableExists.sql && echo "0"'
    
    run ${toolsDir}/dbImportTable -a fromDb.tar.gz tableName toDb 2>&1
    
    [[ "${output}" == *"FATAL - dump invalid"* ]]
    [[ "$(cat /tmp/home/queryTableExists.sql)" == "select count(*) from information_schema.tables where table_schema='toDb' and table_name='tableName'" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} from aws real dump" {
    # change modification date 32 days in the past
    touch -d@$(($(date +%s) - 32*86400)) "${HOME}/.bash-tools/dbImportDumps/oldDump.gz"
    # change modification date 1 day in the future
    touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/dumpInTheFuture.sql.gz"
    # create false dump 1 day in the past
    echo "data" | gzip > "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz"
    touch -d@$(($(date +%s) + 86400)) "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz"

    stub mysqlshow \
        '* * toDb : echo "Database: toDb"' 
    stub tar \
        "xOfz ${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz : cat ${BATS_TEST_DIRNAME}/data/dump.sql"
    stub mysql \
        $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e * : echo "$9" > ${HOME}/queryTableExists.sql && echo "0"' \
        $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names toDb : cat - > ${HOME}/dump.sql'
    stub mysqldump

    run ${toolsDir}/dbImportTable -a fromDb.tar.gz dataTable toDb 2>&1
    
    [[ "${output}" == *"Import table duration : "* ]]
    [[ -f ${HOME}/.bash-tools/dbImportDumps/importTable_fromDb_dataTable.sql.gz ]]          
    [[ "$(cat ${HOME}/queryTableExists.sql)" == "select count(*) from information_schema.tables where table_schema='toDb' and table_name='dataTable'" ]]
    [[ -f "${HOME}/dump.sql" ]]
    [[ "$(md5sum ${HOME}/dump.sql | awk '{ print $1 }')" \
        = "$(md5sum "${BATS_TEST_DIRNAME}/data/expectedDbImportTableDump.sql" | awk '{ print $1 }')" ]]
    # check dump file has been touched
    (( $(date +%s) - $(stat -c "%Y" "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz") < 60 ))
    # check garbage
    [[ -f "${HOME}/.bash-tools/dbImportDumps/dumpInTheFuture.sql.gz" ]]
    [[ ! -f "${HOME}/.bash-tools/dbImportDumps/oldDump.sql.gz" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} from aws real dump rename table" {
    # create false dump
    echo "data" | gzip > "${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz"

    stub mysqlshow \
        '* * toDb : echo "Database: toDb"' 
    stub tar \
        "xOfz ${HOME}/.bash-tools/dbImportDumps/fromDb.tar.gz : cat ${BATS_TEST_DIRNAME}/data/dump.sql"
    stub mysql \
        $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names -e * : echo "$9" > ${HOME}/queryTableExists.sql && echo "0"' \
        $'* --batch --raw --default-character-set=utf8 --connect-timeout=5 -s --skip-column-names toDb : cat - > ${HOME}/dump.sql'
    stub mysqldump

    run ${toolsDir}/dbImportTable -a fromDb.tar.gz dataTable toDb newTableName 2>&1
    
    [[ "${output}" == *"Import table duration : "* ]]
    [[ -f ${HOME}/.bash-tools/dbImportDumps/importTable_fromDb_dataTable.sql.gz ]]          
    [[ "$(cat ${HOME}/queryTableExists.sql)" == "select count(*) from information_schema.tables where table_schema='toDb' and table_name='dataTable'" ]]
    [[ -f "${HOME}/dump.sql" ]]
    [[ "$(md5sum ${HOME}/dump.sql | awk '{ print $1 }')" \
        = "$(md5sum "${BATS_TEST_DIRNAME}/data/expectedDbImportTableDumpRenamed.sql" | awk '{ print $1 }')" ]]
}
