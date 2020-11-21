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
    finalContainerArg="apache2"
fi
# manage container aliases
case "${containerArg}" in
  web) finalContainerArg="apache2";;
esac

# user changes following the container used
if [[ -z "${userArg}" ]]; then
    finalUserArg="www-data"
    case "${containerArg}" in
        node) finalUserArg="node";;
        redis)finalUserArg="redis";;
        mysql|mysqlRemote)finalUserArg="mysql";;
    esac
fi

if [[ -z "${commandArg}" ]]; then
    # we are using // to keep compatibility with "windows git bash"
    finalCommandArg="//bin/bash"
    case ${containerArg} in
        redis)finalCommandArg="redis-cli";;
        mysql)finalCommandArg="//bin/bash -c 'mysql -h${MYSQL_HOSTNAME} -u${MYSQL_USER} -p${MYSQL_PASSWORD} -P${HOST_MYSQL_PORT}'";;
        mysqlRemote)
            finalContainerArg="mysql"
            finalCommandArg="//bin/bash -c 'mysql -h${REMOTE_MYSQL_HOSTNAME} -u${REMOTE_MYSQL_USER} -p${REMOTE_MYSQL_PASSWORD}  -P${REMOTE_MYSQL_PORT}'"
            ;;
    esac
fi
