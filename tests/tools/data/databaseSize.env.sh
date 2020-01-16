#!/usr/bin/env bash

HOSTNAME="127.0.0.1"
USER="root"
# shellcheck disable=SC2034
PASSWORD="root"
# shellcheck disable=SC2034
PORT="3306"
___CURRENT_DIR="$( cd "$( readlink -e "${BASH_SOURCE[0]%/*}" )" && pwd )"

mysqlMocked() {
    case "$2" in
    "db1")
        cat "${___CURRENT_DIR}/databaseSize.result_db1"
        ;;
    "db2")
        cat "${___CURRENT_DIR}/databaseSize.result_db2"
        ;;
    "-e")
        cat "${___CURRENT_DIR}/databaseSize.dbList"
        ;;

    esac
    return 0
}
alias mysql="mysqlMocked"
# shellcheck disable=SC2034
MYSQL_COMMAND="mysql"
