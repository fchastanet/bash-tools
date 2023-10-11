.DELIMS stmt="%"
% if [[ -n "${RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR}" ]]; then
BASH_TOOLS_ROOT_DIR="$(cd "${CURRENT_DIR}/<% ${RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR} %>" && pwd -P)"
if [[ -d "${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework/" ]]; then
  FRAMEWORK_ROOT_DIR="$(cd "${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework" && pwd -P)"
else
  # if the directory does not exist yet, give a value to FRAMEWORK_ROOT_DIR
  FRAMEWORK_ROOT_DIR="${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework"
fi
FRAMEWORK_SRC_DIR="${FRAMEWORK_ROOT_DIR}/src"
FRAMEWORK_BIN_DIR="${FRAMEWORK_ROOT_DIR}/bin"
FRAMEWORK_VENDOR_DIR="${FRAMEWORK_ROOT_DIR}/vendor"
FRAMEWORK_VENDOR_BIN_DIR="${FRAMEWORK_ROOT_DIR}/vendor/bin"

if [[ -f "${HOME}/.bash-tools/.env" ]]; then
  export BASH_FRAMEWORK_ENV_FILES=("${HOME}/.bash-tools/.env")
fi
% fi
.RESET-DELIMS
