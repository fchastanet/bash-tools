#!/usr/bin/env bash

CURRENT_DIR=$( cd "$( readlink -f "${BASH_SOURCE[0]%/*}" )" && pwd )

if [ ! -d "${CURRENT_DIR}/vendor/bats" ]; then
  (>&2 echo "please run ./test-install.sh")
  exit 1
fi

#[[ ! -f "vendor/bats-support/load.bash" ]] && git clone https://github.com/ztombol/bats-support.git "${CURRENT_DIR}/vendor/bats-support"
#[[ ! -f "vendor/bats-assert/load.bash" ]] && git clone https://github.com/ztombol/bats-assert.git "${CURRENT_DIR}/vendor/bats-assert"
# https://github.com/grayhemp/bats-mock
# https://github.com/mbland/go-script-bash#introduction

(
  cd "${CURRENT_DIR}" || exit 1
  if (( $# < 1)); then
    "${CURRENT_DIR}/vendor/bats/bin/bats" -r tests
  else
    "${CURRENT_DIR}/vendor/bats/bin/bats" "$@"
  fi
)