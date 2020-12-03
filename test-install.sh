#!/usr/bin/env bash

BATS_VERSION=master
CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

[[ ! -f "${CURRENT_DIR}/vendor/bats/bin/bats" ]] && (
    rm -Rf "${CURRENT_DIR}/vendor/bats-install" "${CURRENT_DIR}/vendor/bats"
    git clone https://github.com/bats-core/bats-core.git "${CURRENT_DIR}/vendor/bats-install"
    cd "${CURRENT_DIR}/vendor/bats-install" || exit 1
    git checkout ${BATS_VERSION}
    ./install.sh "${CURRENT_DIR}/vendor/bats"
)

[[ ! -d "${CURRENT_DIR}/vendor/bats-support/.git" ]] && (
    rm -Rf "${CURRENT_DIR}/vendor/bats-support"
    git clone git@github.com:bats-core/bats-support.git "${CURRENT_DIR}/vendor/bats-support"
)

[[ ! -d "${CURRENT_DIR}/vendor/bats-assert/.git" ]] && (
    rm -Rf "${CURRENT_DIR}/vendor/bats-assert"
    git clone git@github.com:bats-core/bats-assert.git "${CURRENT_DIR}/vendor/bats-assert"
)