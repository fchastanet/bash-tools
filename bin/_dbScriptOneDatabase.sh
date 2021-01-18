#!/usr/bin/env bash

# load bash-framework
# shellcheck source=bash-framework/_bootstrap.sh
source "${__BASH_FRAMEWORK_ROOT_PATH}/_bootstrap.sh"
############################################################
# INTERNAL USE ONLY
# USED BY bin/dbScriptAllDatabases
############################################################
Framework::expectNonRootUser

# ensure that Ctrl-C is trapped by this script and not sub mysql process
Functions::trapAdd 'exit 130' INT

import bash-framework/Database

declare DSN="$1"
# shellcheck disable=SC2034
declare LOG_FORMAT="$2"
# shellcheck disable=SC2034
declare VERBOSE="$3"
# shellcheck disable=SC2034
declare outputDir="$4"
# shellcheck disable=SC2034
declare callingDir="$5"
# shellcheck disable=SC2034
declare bashFrameworkVendorPath="$6"

declare -i length=$(($#-7))
# shellcheck disable=SC2034
declare -a scriptParameters=("${@:7:$length}")
# shellcheck disable=SC2034,SC2124
declare db="${@:$(($#)):1}"

[[ "${VERBOSE}" = "1" ]] && Log::displayInfo "process db '${db}'"

# shellcheck disable=SC2034
declare -A dbInstance
Database::newInstance dbInstance "${DSN}"
Database::setQueryOptions dbInstance "${dbInstance[QUERY_OPTIONS]} --connect-timeout=5"
