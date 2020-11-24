#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2154
finalContainerArg="${containerArg}"
# shellcheck disable=SC2034
# shellcheck disable=SC2154
finalUserArg="${userArg}"
# shellcheck disable=SC2034
# shellcheck disable=SC2154
finalCommandArg="${commandArg}"

if [[ -z "${containerArg}" ]]; then
    finalContainerArg="ckls-php"
fi
case "${containerArg}" in
web|php|ckls)
    finalContainerArg="ckls-php"
    ;;
esac

if [[ -z "${userArg}" ]]; then
    finalUserArg="www-data"
    case "${containerArg}" in
        node)
            finalUserArg="node"
            finalContainerArg="ckls-node"
            ;;
        redis)
            finalUserArg="redis"
            finalContainerArg="ckls-redis"
            ;;
        mysql|mysqlRemote)
            finalUserArg="mysql"
            finalContainerArg="ckls-mysql8"
            ;;
    esac
fi

if [[ -z "${commandArg}" ]]; then
    # we are using // to keep compatibility with "windows git bash"
    finalCommandArg="//bin/bash"
    case ${containerArg} in
        redis)finalCommandArg="redis-cli";;
        mysql)finalCommandArg="//bin/bash -c 'mysql -h${MYSQL_HOSTNAME} -u${MYSQL_USER} -p${MYSQL_PASSWORD} -P${MYSQL_PORT}'";;
        mysqlRemote)
            finalCommandArg="//bin/bash -c 'mysql -h${REMOTE_MYSQL_HOSTNAME} -u${REMOTE_MYSQL_USER} -p${REMOTE_MYSQL_PASSWORD}  -P${REMOTE_MYSQL_PORT}'"
            ;;
    esac
fi
