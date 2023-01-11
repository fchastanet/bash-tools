#!/usr/bin/env bash

ROOT_DIR=$(cd "$(readlink -e "${BASH_SOURCE[0]%/*}")" && pwd -P)
SRC_DIR="$(cd "${ROOT_DIR}/src" && pwd -P)"
FRAMEWORK_DIR="$(cd "${ROOT_DIR}/vendor/bash-tools-framework" && pwd -P)"
BIN_DIR="${ROOT_DIR}/bin"

# shellcheck source=./vendor/bash-tools-framework/src/_includes/_header.sh
source "${FRAMEWORK_DIR}/src/_includes/_header.sh"
# shellcheck source=./vendor/bash-tools-framework/src/Env/load.sh
source "${FRAMEWORK_DIR}/src/Env/load.sh"
# shellcheck source=./vendor/bash-tools-framework/src/Log/__all.sh
source "${FRAMEWORK_DIR}/src/Log/__all.sh"

export REPOSITORY_URL="https://github.com/fchastanet/bash-tools"
# srcFile     : file that needs to be compiled
# templateDir : directory from which bash-tpl templates will be searched
# binDir      : fallback bin directory in case BIN_FILE has not been provided
# rootDir     : directory used to compute src file relative path
# srcDirs     : additional directories where to find the functions
declare -a params=("${SRC_DIR}" "${BIN_DIR}" "${ROOT_DIR}" "${SRC_DIR}")
if (($# == 0)); then
  find "${SRC_DIR}" -name "*.sh" -print0 | xargs -0 -n1 -P8 -I{} \
    "${FRAMEWORK_DIR}/bin/constructBinFile" "{}" "${params[@]}"
else
  for file in "$@"; do
    file="$(realpath "${file}")"
    "${FRAMEWORK_DIR}/bin/constructBinFile" "${file}" "${params[@]}"
  done
fi
