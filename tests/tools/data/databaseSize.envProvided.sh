#!/usr/bin/env bash

HOSTNAME="hostOverriden"
USER="userOverriden"
# shellcheck disable=SC2034
PASSWORD="passOverriden"
# shellcheck disable=SC2034
PORT="portOverriden"

mysqlMocked() {
    local envFile="$(echo $1 | awk -F '=' '{print $2}' )"
    local result="$(cat ${envFile} | grep -v "${HOSTNAME}" | grep -v "${USER}"  | grep -v "${PASSWORD}"  | grep -v "${PORT}")"

    [[ -n "${result}" ]] && echo "parameters OK"
}
alias mysql="mysqlMocked"
# shellcheck disable=SC2034
MYSQL_COMMAND="mysql"
