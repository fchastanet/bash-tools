#!/usr/bin/env bash
set -x
CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# load bash-framework
# shellcheck source=bash-framework/_bootstrap.sh
source "$( cd "${CURRENT_DIR}" && pwd )/bash-framework/_bootstrap.sh"
import bash-framework/Git

Git::ShallowClone \
  "https://github.com/fchastanet/tomdoc.sh.git" \
  "${CURRENT_DIR}/vendor/fchastanet.tomdoc.sh" \
  "master" \
  "1"

Git::ShallowClone \
  "https://github.com/bats-core/bats-core.git" \
  "${CURRENT_DIR}/vendor/bats" \
  "v1.2.1" \
  "1"

Git::ShallowClone \
  "https://github.com/bats-core/bats-support.git" \
  "${CURRENT_DIR}/vendor/bats-support" \
  "d140a65044b2d6810381935ae7f0c94c7023c8c3" \
  "1"

Git::ShallowClone \
  "https://github.com/bats-core/bats-assert.git" \
  "${CURRENT_DIR}/vendor/bats-assert" \
  "0a8dd57e2cc6d4cc064b1ed6b4e79b9f7fee096f" \
  "1"

Git::ShallowClone \
  "https://github.com/Flamefire/bats-mock.git" \
  "${CURRENT_DIR}/vendor/bats-mock-Flamefire" \
  "1838e83473b14c79014d56f08f4c9e75d885d6b2" \
  "1"