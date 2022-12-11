#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/dockerLint
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

# check if command in PATH is already the minimal version needed
if ! Version::checkMinimal "hadolint" "--version" "2.12.0"; then
  Github::upgradeRelease \
    "${VENDOR_BIN_DIR}/hadolint" \
    "https://github.com/hadolint/hadolint/releases/download/v@latestVersion@/hadolint-Linux-x86_64"
fi

if (($# == 0)); then
  set -- -f checkstyle
fi

find . -type f -name 'Dockerfile*' -print0 | xargs -0 hadolint "$@"
