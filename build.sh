#!/usr/bin/env bash

ROOT_DIR=$(cd "$(readlink -e "${BASH_SOURCE[0]%/*}")" && pwd -P)
SRC_DIR="$(cd "${ROOT_DIR}/src" && pwd -P)"
FRAMEWORK_DIR="$(cd "${ROOT_DIR}/vendor/bash-tools-framework" && pwd -P)"
BIN_DIR="${ROOT_DIR}/bin"

# shellcheck source=./vendor/bash-tools-framework/src/_includes/_header.sh
source "${FRAMEWORK_DIR}/src/_includes/_header.sh"

# srcFile     : file that needs to be compiled
# templateDir : directory from which bash-tpl templates will be searched
# binDir      : fallback bin directory in case BIN_FILE has not been provided
# rootDir     : directory used to compute src file relative path
# srcDirs     : additional directories where to find the functions
declare -a params=(
  --src-dir "${SRC_DIR}"
  --bin-dir "${BIN_DIR}"
  --root-dir "${ROOT_DIR}"
  --template-dir "${SRC_DIR}/_includes"
)
if [[ "${ARGS_VERBOSE}" = "1" ]]; then
  params+=("--verbose")
fi

(
  if (($# == 0)); then
    find "${SRC_DIR}/_binaries" -name "*.sh" |
      (grep -v -E '/testsData/' || true)
  else
    for file in "$@"; do
      realpath "${file}"
    done
  fi
) | xargs -L1 -P8 -I{} \
  "${FRAMEWORK_DIR}/bin/compile" "{}" "${params[@]}"
