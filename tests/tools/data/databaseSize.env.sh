#!/usr/bin/env bash

HOSTNAME="127.0.0.1"
USER="root"
# shellcheck disable=SC2034
PASSWORD="root"
# shellcheck disable=SC2034
PORT="3306"
___CURRENT_DIR="$( cd "$( readlink -e "${BASH_SOURCE[0]%/*}" )" && pwd )"

mysqlMocked() {
    if [[ "$5" = "show databases" ]]; then
      cat "${___CURRENT_DIR}/databaseSize.dbList"
    elif [[ "$4" == "db"* ]]; then
      cat "${___CURRENT_DIR}/databaseSize.result_$4"
    fi
    return 0
}
alias mysql="mysqlMocked"
# shellcheck disable=SC2034
MYSQL_COMMAND="mysql"
