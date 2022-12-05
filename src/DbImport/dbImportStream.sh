#!/usr/bin/env bash

set -o errexit
set -o pipefail

CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# load bash-framework
# shellcheck source=bash-framework/_bootstrap.sh
source "$( cd "${CURRENT_DIR}/.." && pwd )/bash-framework/_bootstrap.sh"

DUMP_FILE="$1"
DB_NAME="$2"
PROFILE_COMMAND="${3}"
MYSQL_AUTH_FILE="${4}"
CHARACTER_SET="${5:-utf8}"
DB_IMPORT_OPTIONS="${6:-}"

if [[ -z "${PROFILE_COMMAND}" ]]; then
  Log::fatal "You should provide a profile command"
fi

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
  if [[ $status -eq 141 ]]; then true; else exit $status; fi
) | awk \
  -v PROFILE_COMMAND="${PROFILE_COMMAND}" \
  -v CHARACTER_SET="${CHARACTER_SET}" \
  -f "${CURRENT_DIR}/dbImportStream.awk" \
  - | mysql --defaults-extra-file="${MYSQL_AUTH_FILE}" ${DB_IMPORT_OPTIONS} "${DB_NAME}" || exit $?
