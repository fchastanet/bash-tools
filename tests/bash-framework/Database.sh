#!/usr/bin/env bash
CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
BASH_FRAMEWORK_FOLDER="$(cd "${CURRENT_DIR}/../.." && pwd)/bash-framework"
# shellcheck source=bash-framework/_bootstrap.sh
__bash_framework_envFile="" source "${BASH_FRAMEWORK_FOLDER}/_bootstrap.sh" || exit 1

import bash-framework/Database

(
    mkdir -p /tmp/home/.bash-tools/dsn
    cd /tmp/home/.bash-tools/dsn
    cp ${CURRENT_DIR}/data/dsn_* /tmp/home/.bash-tools/dsn
    touch default.local.env
    touch other.local.env
)
set -x
(Database::checkDsnFile ${CURRENT_DIR}/data/dsn_missing_password.env 2>&1)
status=$?
echo $output
[ "$status" -eq 1 ]
[[ "${output}" == *"Description: rename git local branch, use options to push new branch and delete old branch"* ]]