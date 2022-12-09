#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/installDevRequirements
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

.INCLUDE "${TEMPLATE_DIR}/_includes/executedAsUser.sh"

if [[ -f "${BIN_DIR}/installRequirements" ]]; then
  "${BIN_DIR}/installRequirements"
else
  Log::displayError "missing script file ${BIN_DIR}/installRequirements"
fi

Git::shallowClone \
  "https://github.com/bats-core/bats-core.git" \
  "${ROOT_DIR}/vendor/bats" \
  "v1.5.0" \
  "FORCE_DELETION"

# last revision 2019
Git::shallowClone \
  "https://github.com/bats-core/bats-support.git" \
  "${ROOT_DIR}/vendor/bats-support" \
  "master" \
  "FORCE_DELETION"

Git::shallowClone \
  "https://github.com/bats-core/bats-assert.git" \
  "${ROOT_DIR}/vendor/bats-assert" \
  "34551b1d7f8c7b677c1a66fc0ac140d6223409e5" \
  "FORCE_DELETION"

Git::shallowClone \
  "https://github.com/Flamefire/bats-mock.git" \
  "${ROOT_DIR}/vendor/bats-mock-Flamefire" \
  "1838e83473b14c79014d56f08f4c9e75d885d6b2" \
  "FORCE_DELETION"
