#!/bin/bash

read -r -d '\0' bashToolsDefaultConfigTemplate <<-EOM || true
#{{ include ".env" .Data . -}}
EOM

# @description loads ~/.bash-tools/.env if available
# if not creates it from a default template
# else check if new options need to be added
BashTools::Conf::requireLoad() {
  BASH_TOOLS_ROOT_DIR="$(cd "${CURRENT_DIR}/${RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR}" && pwd -P)"
  if [[ -d "${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework/" ]]; then
    FRAMEWORK_ROOT_DIR="$(cd "${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework" && pwd -P)"
  else
    # if the directory does not exist yet, give a value to FRAMEWORK_ROOT_DIR
    FRAMEWORK_ROOT_DIR="${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework"
  fi
  # shellcheck disable=SC2034
  FRAMEWORK_SRC_DIR="${FRAMEWORK_ROOT_DIR}/src"
  # shellcheck disable=SC2034
  FRAMEWORK_BIN_DIR="${FRAMEWORK_ROOT_DIR}/bin"
  # shellcheck disable=SC2034
  FRAMEWORK_VENDOR_DIR="${FRAMEWORK_ROOT_DIR}/vendor"
  # shellcheck disable=SC2034
  FRAMEWORK_VENDOR_BIN_DIR="${FRAMEWORK_ROOT_DIR}/vendor/bin"

  if [[ -f "${HOME}/.bash-tools/.env" ]]; then
    # shellcheck disable=SC2034
    BASH_FRAMEWORK_ENV_FILES=("${HOME}/.bash-tools/.env")
  fi

  local envFile="${HOME}/.bash-tools/.env"
  if [[ ! -f "${envFile}" ]]; then
    mkdir -p "${HOME}/.bash-tools"
    (
      echo "#!/usr/bin/env bash"
      # shellcheck disable=SC2154
      echo "${bashToolsDefaultConfigTemplate}"
    ) >"${envFile}"
    Log::displayInfo "Configuration file '${envFile}' created"
  else
    if ! grep -q '^POSTMAN_API_KEY=' "${envFile}"; then
      (
        echo '# -----------------------------------------------------'
        echo '# Postman Parameters'
        echo '# -----------------------------------------------------'
        echo 'POSTMAN_API_KEY='
      ) >>"${envFile}"
    fi
  fi
  # shellcheck source=/conf/defaultEnv/.env
  source "${envFile}" || {
    Log::displayError "impossible to load '${envFile}'"
    exit 1
  }
}
