#!/usr/bin/env bash

set -o errexit
set -o pipefail

BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

(
  cd "${BASE_DIR}"
  
  gawk \
    -v PROFILE_COMMAND="conf/dbImportProfiles/default.sh" \
    -v CHARACTER_SET="${CHARACTER_SET}" \
    --lint -f bin/dbImportStream.awk < tests/tools/data/dbImportTableDump.sql
)
status=$?
exit ${status}