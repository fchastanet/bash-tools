#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/dbQueryOneDatabase
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

############################################################
# INTERNAL USE ONLY
# USED BY bin/dbQueryAllDatabases
############################################################

Assert::expectNonRootUser

HELP="$(
  cat <<EOF
${__HELP_TITLE}Description:${__HELP_NORMAL} INTERNAL USE ONLY - USED BY bin/dbQueryAllDatabases

.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/author.tpl"
EOF
)"
Args::defaultHelp "${HELP}" "$@"

Env::load

# ensure that Ctrl-C is trapped by this script and not sub mysql process
trap 'exit 130' INT

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
