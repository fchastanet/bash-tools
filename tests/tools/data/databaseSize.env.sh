#!/usr/bin/env bash

HOSTNAME="127.0.0.1"
USER="root"
PASSWORD="root"
PORT="3306"
___CURRENT_DIR="$( cd "$( readlink -e "${BASH_SOURCE[0]%/*}" )" && pwd )"

mysqlMocked() {
    case "$2" in
    "db1")
        mysqlMockedStep="db2"
        cat "${___CURRENT_DIR}/databaseSize.result_db1"
        ;;
    "db2")
        cat "${___CURRENT_DIR}/databaseSize.result_db2"
        mysqlMockedStep="noMore"
        ;;
    "-e")
        cat "${___CURRENT_DIR}/databaseSize.dbList"
        mysqlMockedStep="db1"
        ;;

    esac
    return 0
}
alias mysql="mysqlMocked"
MYSQL_COMMAND="mysql"
