#!/usr/bin/env bash

# shellcheck disable=SC2034
.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/_headerNoRootDir.tpl"

BASH_FRAMEWORK_ENV_FILEPATH=${HOME}/.bash-tools/.env
FRAMEWORK_DIR="$(cd "${CURRENT_DIR}/vendor/bash-tools-framework" && pwd -P)"
export FRAMEWORK_DIR
