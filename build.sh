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

getBinFileFromSrcFile() {
  local srcFile="$1"
  local rootDir="$2"
  local binDir="$3"
  local BIN_FILE

  BIN_FILE="$(grep -E '# BIN_FILE=' "${srcFile}" | sed -r 's/^#[^=]+=[ \t]*(.*)[ \t]*$/\1/' || :)"
  BIN_FILE="$(echo "${BIN_FILE}" | envsubst)"
  if [[ -z "${BIN_FILE}" ]]; then
    BIN_FILE="$(echo "${srcFile}" | sed -E "s#^${rootDir}/src/#${binDir}/#" | sed -E 's#.sh$##')"
  fi
  if ! realpath "${BIN_FILE}" &>/dev/null; then
    Log::displayError >&2 "${srcFile} does not define a valid BIN_FILE value"
    return 1
  fi
  echo "${BIN_FILE}"
}

getRootDirRelativeToBinDirFromSrcFile() {
  local srcFile="$1"
  grep -E '# ROOT_DIR_RELATIVE_TO_BIN_DIR=' "${srcFile}" | sed -r 's/^#[^=]+=[ \t]*(.*)[ \t]*$/\1/' || :
}

removeMetaDataFilter() {
  sed -r '/^# (BIN_FILE|ROOT_DIR_RELATIVE_TO_BIN_DIR)=.*$/d'
}

getFileRelativeToDir() {
  local srcFile="$1"
  local relativeTo="$2"

  realpath -m --relative-to="${relativeTo}" "${srcFile}"
}

constructBinFile() {
  local srcFile="$1"

  BIN_FILE=$(getBinFileFromSrcFile "${srcFile}" "${ROOT_DIR}" "${BIN_DIR}")
  mkdir -p "$(realpath -m "$(dirname "${BIN_FILE}")")" || true

  ROOT_DIR_RELATIVE_TO_BIN_DIR="$(getRootDirRelativeToBinDirFromSrcFile "${srcFile}")"

  Log::displayInfo "Writing file ${BIN_FILE} from ${srcFile}"
  "${FRAMEWORK_DIR}/bin/compile" \
    "${srcFile}" \
    "$(getFileRelativeToDir "${srcFile}" "${ROOT_DIR}")" \
    "${ROOT_DIR_RELATIVE_TO_BIN_DIR}" \
    --template-dir "${SRC_DIR}" |
    removeMetaDataFilter >"${BIN_FILE}"
}

if (($# == 0)); then
  while IFS= read -r file; do
    constructBinFile "${file}"
  done < <(find "${SRC_DIR}" -name "*.sh")
else
  for file in "$@"; do
    constructBinFile "${file}"
  done
fi

if [[ "${exitCode}" != "0" ]]; then
  Log::displayError "${exitCode} file(s) have been updated by this build"
  exit "${exitCode}"
fi
