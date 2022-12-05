#!/usr/bin/env bash

############################################################
# INTERNAL USE ONLY
# USED BY bin/dbQueryAllDatabases
############################################################

# load bash-framework
# shellcheck source=bash-framework/_bootstrap.sh
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )/bash-framework/_bootstrap.sh"

Framework::expectNonRootUser

# ensure that Ctrl-C is trapped by this script and not sub mysql process
trap 'exit 130' INT

import bash-framework/Database

# query is passed via export
declare DSN_FILE="$1"
declare DB="$2"

declare -Agx dbInstance
Database::newInstance dbInstance "${DSN_FILE}"
Database::setQueryOptions dbInstance "${dbInstance[QUERY_OPTIONS]} --connect-timeout=5"

# identify columns header
echo -n "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
Database::skipColumnNames dbInstance 0

# shellcheck disable=SC2154
Database::query dbInstance "${query}" "${DB}" ||
    Log::displayError "database ${DB} error" 1>&2
