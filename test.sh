#!/usr/bin/env bash

BATS_VERSION=v0.4.0
CURRENT_DIR=$( cd "$( readlink -e "${BASH_SOURCE[0]%/*}" )" && pwd )

[[ ! -f "${CURRENT_DIR}/vendor/bats/bin/bats" ]] && (
    rm -Rf "${CURRENT_DIR}/vendor/bats-install" "${CURRENT_DIR}/vendor/bats"
    git clone https://github.com/sstephenson/bats.git "${CURRENT_DIR}/vendor/bats-install"
    cd "${CURRENT_DIR}/vendor/bats-install" || exit 1
    git checkout ${BATS_VERSION}
    ./install.sh "${CURRENT_DIR}/vendor/bats"
)

[[ ! -f "vendor/bats-support/load.bash" ]] && git clone https://github.com/ztombol/bats-support.git "${CURRENT_DIR}/vendor/bats-support"
[[ ! -f "vendor/bats-assert/load.bash" ]] && git clone https://github.com/ztombol/bats-assert.git "${CURRENT_DIR}/vendor/bats-assert"

"${CURRENT_DIR}/vendor/bats/bin/bats"  tests
