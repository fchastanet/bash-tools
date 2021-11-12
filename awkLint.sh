#!/usr/bin/env bash

set -o errexit
set -o pipefail

BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

(
  cd "${BASE_DIR}"
  trap 'rm -f /tmp/awkLint.log' ERR EXIT
  find bin bash-framework conf .build -type f -name '*.awk' -exec sh -c 'awk --source "BEGIN { exit(0) } END { exit(0) }" --lint=no-ext -f "$1" < /dev/null' _ {} \; | tee /tmp/awkLint.log
  grep -q 'fatal:' /tmp/awkLint.log
)
status=$?
exit ${status}
