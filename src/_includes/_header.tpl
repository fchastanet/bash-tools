#!/usr/bin/env bash

# shellcheck disable=SC2034
.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/_header.tpl"
BASH_FRAMEWORK_ENV_FILEPATH=${HOME}/.bash-tools/.env
if [[ -d "${ROOT_DIR}/vendor/bash-tools-framework" ]]; then
  FRAMEWORK_DIR="$(cd "${ROOT_DIR}/vendor/bash-tools-framework" && pwd -P)"
else
  FRAMEWORK_DIR="${ROOT_DIR}/vendor/bash-tools-framework"
fi
export FRAMEWORK_DIR
