#!/usr/bin/env bash

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

############################################################
# INTERNAL USE ONLY
# USED BY bin/dbScriptAllDatabases sub scripts
# eg: src/DbScriptAllDatabases/extractData.sh
############################################################
Assert::expectNonRootUser

Framework::loadEnv

declare DSN="$1"
# shellcheck disable=SC2034
declare LOG_FORMAT="$2"
# shellcheck disable=SC2034
declare VERBOSE="$3"
# shellcheck disable=SC2034
declare outputDir="$4"
# shellcheck disable=SC2034
declare callingDir="$5"

declare -i length=$(($# - 6))
# shellcheck disable=SC2034
declare -a scriptParameters=("${@:6:${length}}")
# shellcheck disable=SC2034,SC2124
declare db="${@:$(($#)):1}"

[[ "${VERBOSE}" = "1" ]] && Log::displayInfo "process db '${db}'"

# shellcheck disable=SC2034
declare -A dbInstance
Database::newInstance dbInstance "${DSN}"
Database::setQueryOptions dbInstance "${dbInstance[QUERY_OPTIONS]} --connect-timeout=5"
