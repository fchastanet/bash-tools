#!/usr/bin/env bash

set -o errexit
set -o pipefail

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

exit $?