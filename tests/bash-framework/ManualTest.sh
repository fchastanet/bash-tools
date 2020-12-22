#!/usr/bin/env bash

# test used for bats debugging purpose

BATS_TEST_DIRNAME=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
declare -g vendorDir="$( cd "${BATS_TEST_DIRNAME}/../../vendor" && pwd )"
declare -g toolsDir="$( cd "${BATS_TEST_DIRNAME}/../../bin" && pwd )"

# shellcheck source=bash-framework/Constants.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/Constants.sh" || exit 1
export HOME="/tmp/home"
mkdir -p /tmp/home
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1
source "${vendorDir}/bats-mock-Flamefire/load.bash" || exit 1

export HOME="/tmp/home"
(
    mkdir -p "${HOME}" 
    cd "${HOME}"
    mkdir -p \
        bin \
        .bash-tools/dsn \
        .bash-tools/dbImportDumps \
        .bash-tools/dbImportProfiles
    cp "${BATS_TEST_DIRNAME}/../tools/mocks/pv" bin
    touch bin/mysql bin/mysqldump bin/mysqlshow
    chmod +x bin/*
)
export PATH="$PATH:/tmp/home/bin"


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
set -x
${toolsDir}/dbImport -f default.local fromDb toDb 2>&1
