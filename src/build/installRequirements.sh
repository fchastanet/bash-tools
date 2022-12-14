#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/installRequirements
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

.INCLUDE "${TEMPLATE_DIR}/_includes/executedAsUser.sh"

Git::cloneOrPullIfNoChanges \
  "${ROOT_DIR}/vendor/bash-tools-framework" \
  "https://github.com/fchastanet/bash-tools-framework.git"
