#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/dbImportStream
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "$(dynamicTemplateDir _header.tpl)"

HELP="$(
  cat <<EOF
${__HELP_TITLE}Description:${__HELP_NORMAL} stream tar.gz file or gz file through mysql

${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} <dumpFile> <targetDbName> <mysqlAuthFile> [characterSet] [dbImportOptions]
characterSet: default value utf8
dbImportOptions: default value empty

.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/author.tpl"
EOF
)"
Args::defaultHelp "${HELP}" "$@"

DUMP_FILE="$1"
DB_NAME="$2"
PROFILE_COMMAND="${3}"
MYSQL_AUTH_FILE="${4}"
CHARACTER_SET="${5:-utf8}"
DB_IMPORT_OPTIONS="${6:-}"

if [[ -z "${PROFILE_COMMAND}" ]]; then
  Log::fatal "You should provide a profile command"
fi

awkScript="$(
  cat <<'EOF'
.INCLUDE "$(dynamicSrcFile "_binaries/DbImport/dbImportStream.awk")"
EOF
)"
# shellcheck disable=2086
(
  if [[ "${DUMP_FILE}" == *tar.gz ]]; then
    tar xOfz "${DUMP_FILE}"
  elif [[ "${DUMP_FILE}" == *.gz ]]; then
    zcat "${DUMP_FILE}"
  fi
  # zcat will continue to write to stdout whereas awk has finished if table has been found
  # we detect this case because zcat will return code 141 because pipe closed
  status=$?
  if [[ "${status}" -eq "141" ]]; then true; else exit "${status}"; fi
) | awk \
  -v PROFILE_COMMAND="${PROFILE_COMMAND}" \
  -v CHARACTER_SET="${CHARACTER_SET}" \
  --source "${awkScript}" \
  - | mysql --defaults-extra-file="${MYSQL_AUTH_FILE}" ${DB_IMPORT_OPTIONS} "${DB_NAME}" || exit $?
