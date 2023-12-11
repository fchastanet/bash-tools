#!/usr/bin/env bash
# BIN_FILE=${BASH_TOOLS_ROOT_DIR}/bin/installRequirements
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE
# shellcheck disable=SC2034,SC2154

declare copyrightBeginYear="2020"
declare optionBashFrameworkConfig="${BASH_TOOLS_ROOT_DIR}/.framework-config"

.INCLUDE "$(dynamicTemplateDir _binaries/build/installRequirements.options.tpl)"

# @require Linux::requireExecutedAsUser
run() {
  mkdir -p "${BASH_TOOLS_ROOT_DIR}/vendor" || true
  Git::cloneOrPullIfNoChanges \
    "${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework" \
    "https://github.com/fchastanet/bash-tools-framework.git"
}

if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "1" ]]; then
  run &>/dev/null
else
  run
fi
