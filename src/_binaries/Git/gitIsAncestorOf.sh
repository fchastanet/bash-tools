#!/usr/bin/env bash
# BIN_FILE=${BASH_TOOLS_ROOT_DIR}/bin/gitIsAncestorOf
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE
# shellcheck disable=SC2034

declare copyrightBeginYear="2020"
declare claimedBranchArg=""
declare commitArg=""

.INCLUDE "$(dynamicTemplateDir _binaries/Git/gitIsAncestorOf.options.tpl)"

# @require Linux::requireExecutedAsUser
run() {

  if ! git cat-file -t "${commitArg}" &>/dev/null; then
    Log::displayError "Commit ${commitArg} does not exists at all"
    exit 1
  fi

  merge_base="$(git merge-base "${commitArg}" "${claimedBranchArg}")"
  if [[ -z "${merge_base}" || "${merge_base}" != "$(git rev-parse --verify "${commitArg}")" ]]; then
    Log::displayError "Commit ${commitArg} is not an ancestor of branch ${claimedBranchArg}"
    exit 2
  fi
}

if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "1" ]]; then
  run &>/dev/null
else
  run
fi
