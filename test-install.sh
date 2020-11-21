#!/usr/bin/env bash

set -x
BATS_VERSION=master
CURRENT_DIR=$( cd "$( readlink -f "${BASH_SOURCE[0]%/*}" )" && pwd )

[[ ! -f "${CURRENT_DIR}/vendor/bats/bin/bats" ]] && (
    rm -Rf "${CURRENT_DIR}/vendor/bats-install" "${CURRENT_DIR}/vendor/bats"
    git clone https://github.com/bats-core/bats-core.git "${CURRENT_DIR}/vendor/bats-install"
    cd "${CURRENT_DIR}/vendor/bats-install" || exit 1
    git checkout ${BATS_VERSION}
    ./install.sh "${CURRENT_DIR}/vendor/bats"
)