#!/usr/bin/env bash
# BIN_FILE=${FRAMEWORK_ROOT_DIR}/bin/gitIsBranch
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE

.INCLUDE "$(dynamicTemplateDir _binaries/Git/gitIsBranch.options.tpl)"

gitIsBranchCommand parse "${BASH_FRAMEWORK_ARGV[@]}"

# @require Linux::requireExecutedAsUser
run() {
  # check various branch hierarchies, adjust as needed
  # shellcheck disable=SC2154
  git show-ref --verify refs/heads/"${branchNameArg}" ||
    git show-ref --verify refs/remotes/"${branchNameArg}" ||
    Log::fatal "not a branch name: ${branchNameArg}"
}

if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "1" ]]; then
  run &>/dev/null
else
  run
fi
