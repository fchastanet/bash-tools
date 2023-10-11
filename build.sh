#!/usr/bin/env bash

BASH_TOOLS_ROOT_DIR=$(cd "$(readlink -e "${BASH_SOURCE[0]%/*}")" && pwd -P)
BASH_TOOLS_SRC_DIR="${BASH_TOOLS_ROOT_DIR}/src"
FRAMEWORK_ROOT_DIR="${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework"
FRAMEWORK_BIN_DIR="${FRAMEWORK_ROOT_DIR}/bin"
COMMAND_BIN_DIR="${BASH_TOOLS_ROOT_DIR}/bin"

# shellcheck source=./vendor/bash-tools-framework/src/_includes/_header.sh
source "${FRAMEWORK_ROOT_DIR}/src/_includes/_header.sh"

# srcFile     : file that needs to be compiled
# templateDir : directory from which bash-tpl templates will be searched
# binDir      : fallback bin directory in case BIN_FILE has not been provided
# rootDir     : directory used to compute src file relative path
# srcDirs     : additional directories where to find the functions
declare -a params=(
  --src-dir "${BASH_TOOLS_SRC_DIR}"
  --bin-dir "${COMMAND_BIN_DIR}"
  --root-dir "${BASH_TOOLS_ROOT_DIR}"
  --template-dir "${BASH_TOOLS_SRC_DIR}"
)
if [[ "${ARGS_VERBOSE}" = "1" ]]; then
  params+=("-vvv")
fi

(
  if (($# == 0)); then
    find "${BASH_TOOLS_SRC_DIR}/_binaries" -name "*.sh" |
      (grep -v -E '/testsData/' || true)
  else
    for file in "$@"; do
      realpath "${file}"
    done
  fi
) | xargs -L1 -P8 -I{} \
  "${FRAMEWORK_BIN_DIR}/compile" "{}" "${params[@]}"
