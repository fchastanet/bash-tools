#!/usr/bin/env bash

.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/_header.tpl"

BASH_TOOLS_ROOT_DIR="$(cd "${CURRENT_DIR}/.." && pwd -P)"
if [[ -d "${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework/" ]]; then
  FRAMEWORK_ROOT_DIR="$(cd "${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework" && pwd -P)"
else
  # if the directory does not exist yet, give a value to FRAMEWORK_ROOT_DIR
  FRAMEWORK_ROOT_DIR="${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework"
fi
export BASH_TOOLS_ROOT_DIR FRAMEWORK_ROOT_DIR

if [[ -f "${HOME}/.bash-tools/.env" ]]; then
  export BASH_FRAMEWORK_ENV_FILEPATH="${HOME}/.bash-tools/.env"
fi
