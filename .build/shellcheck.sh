#!/usr/bin/env bash

set -o errexit
set -o pipefail

BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )

(
  cd "${BASE_DIR}"
  targets=()
  while IFS= read -r line; do
      targets+=("$line")
  done < <(
    (
      find \
        bin \
        bash-framework \
        ./*.sh \
        -type f \
      && find \
        conf \
        -name '*.sh' \
    ) | grep -v '.awk' | grep -v './bin/deepsource'
  ) 

  LC_ALL=C.UTF-8 shellcheck "${targets[@]}"
)
status=$?
exit ${status}