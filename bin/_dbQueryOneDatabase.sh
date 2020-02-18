#!/bin/bash

############################################################
# INTERNAL USE ONLY
# USED BY bin/dbQueryAllDatabases
############################################################

# load bash-framework
# shellcheck source=bash-framework/_bootstrap.sh
source "$( cd "$( readlink -e "${BASH_SOURCE[0]%/*}/.." )" && pwd )/bash-framework/_bootstrap.sh"

Framework::expectNonRootUser

# ensure that Ctrl-C is trapped by this script and not sub mysql process
trap 'exit 130' INT

import bash-framework/Database

declare HOSTNAME="$1"
declare PORT="$2"
declare USER="$3"
declare PASSWORD="$4"
declare MYSQL_OPTIONS="$5"
declare DB="$6"

declare -Agx dbInstance
Database::newInstance dbInstance "${HOSTNAME}" "${PORT}" "${USER}" "${PASSWORD}"
Database::setOptions dbInstance "${MYSQL_OPTIONS} --connect-timeout=5"

# identify columns header
echo -n "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

# errors will be shown on stderr, result on stdout
# shellcheck disable=SC2154
Database::query dbInstance "${query}" "${DB}" ||
    Log::displayError "database ${DB} error" 1>&2
