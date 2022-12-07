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

# exitCode will be > 0 if at least one file has been updated or created
((exitCode = 0)) || true
compileFile() {
  local srcFile="$1"
  local srcRelativeFile BIN_FILE ROOT_DIR_RELATIVE_TO_BIN_DIR
  srcRelativeFile="$(realpath -m --relative-to="${ROOT_DIR}" "${srcFile}")"

  BIN_FILE="$(grep -E '# BIN_FILE=' "${srcFile}" | sed -r 's/^#[^=]+=[ \t]*(.*)[ \t]*$/\1/' || :)"
  BIN_FILE="$(echo "${BIN_FILE}" | envsubst)"
  ROOT_DIR_RELATIVE_TO_BIN_DIR="$(grep -E '# ROOT_DIR_RELATIVE_TO_BIN_DIR=' "${srcFile}" | sed -r 's/^#[^=]+=[ \t]*(.*)[ \t]*$/\1/' || :)"
  if [[ -z "${BIN_FILE}" ]]; then
    BIN_FILE="$(echo "${srcFile}" | sed -E "s#^${ROOT_DIR}/src/#${BIN_DIR}/#" | sed -E 's#.sh$##')"
  else
    mkdir -p "$(realpath -m "$(dirname "${BIN_FILE}")")" || true
    if ! realpath "${BIN_FILE}" &>/dev/null; then
      Log::displayError "${srcFile} does not define a valid BIN_FILE value"
      return 1
    fi
  fi

  Log::displayInfo "Writing file ${BIN_FILE} from ${srcFile}"
  mkdir -p "$(dirname "${BIN_FILE}")"
  local oldMd5
  oldMd5="$(md5sum "${BIN_FILE}" 2>/dev/null | awk '{print $1}' || echo "new")"
  "${FRAMEWORK_DIR}/bin/compile" "${srcFile}" "${srcRelativeFile}" "${ROOT_DIR_RELATIVE_TO_BIN_DIR}" |
    sed -r '/^# (BIN_FILE|ROOT_DIR_RELATIVE_TO_BIN_DIR)=.*$/d' >"${BIN_FILE}"
  chmod +x "${BIN_FILE}"

  # return exit code != 0 if a bin file has been updated
  if [[ "${oldMd5}" != "$(md5sum "${BIN_FILE}" | awk '{print $1}' || "new")" ]]; then
    ((++exitCode))
  fi
}

if (($# == 0)); then
  while IFS= read -r file; do
    compileFile "${file}"
  done < <(find "${SRC_DIR}" -name "*.sh")
else
  for file in "$@"; do
    compileFile "${file}"
  done
fi

if [[ "${exitCode}" != "0" ]]; then
  Log::displayError "${exitCode} file(s) have been updated by this build"
  exit "${exitCode}"
fi
