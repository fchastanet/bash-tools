#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/dockerLint
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

if (($# == 0)); then
  set -- -f checkstyle
fi

# shellcheck disable=SC2046
find . -type f -name 'Dockerfile*' -print0 | xargs -0 hadolint "$@"
