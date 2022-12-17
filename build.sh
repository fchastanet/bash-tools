#!/usr/bin/env bash

ROOT_DIR=$(cd "$(readlink -e "${BASH_SOURCE[0]%/*}")" && pwd -P)
SRC_DIR="$(cd "${ROOT_DIR}/src" && pwd -P)"
FRAMEWORK_DIR="$(cd "${ROOT_DIR}/vendor/bash-tools-framework" && pwd -P)"
BIN_DIR="${ROOT_DIR}/bin"

# shellcheck source=./vendor/bash-tools-framework/src/_includes/_header.sh
source "${FRAMEWORK_DIR}/src/_includes/_header.sh"
# shellcheck source=./vendor/bash-tools-framework/src/Log/_.sh
source "${FRAMEWORK_DIR}/src/Log/_.sh"
# shellcheck source=./vendor/bash-tools-framework/src/Log/displayInfo.sh
source "${FRAMEWORK_DIR}/src/Log/displayInfo.sh"
# shellcheck source=./vendor/bash-tools-framework/src/Log/displayError.sh
source "${FRAMEWORK_DIR}/src/Log/displayError.sh"
# shellcheck source=./vendor/bash-tools-framework/src/Log/fatal.sh
source "${FRAMEWORK_DIR}/src/Log/fatal.sh"

export REPOSITORY_URL="https://github.com/fchastanet/bash-tools/tree/master"
if (($# == 0)); then
  while IFS= read -r file; do
    "${FRAMEWORK_DIR}/bin/constructBinFile" "${file}" "${SRC_DIR}" "${BIN_DIR}" "${ROOT_DIR}"
  done < <(find "${SRC_DIR}" -name "*.sh")
else
  for file in "$@"; do
    "${FRAMEWORK_DIR}/bin/constructBinFile" "${file}" "${SRC_DIR}" "${BIN_DIR}" "${ROOT_DIR}"
  done
fi
