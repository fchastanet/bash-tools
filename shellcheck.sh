#!/usr/bin/env bash

set -o errexit
set -o pipefail

BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if (( $# == 0 )); then
  set -- --check-sourced -x -f checkstyle
fi

(
  cd "${BASE_DIR}"
  # shellcheck disable=SC2046
  LC_ALL=C.UTF-8 shellcheck "$@" \
        $(find bin bash-framework conf .build -type f -regextype posix-egrep \
        ! -regex '.*\.(env|log|sql|puml|awk)$' ! -name '.*')
)
status=$?
exit ${status}
