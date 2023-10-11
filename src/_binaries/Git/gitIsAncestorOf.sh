#!/usr/bin/env bash
# BIN_FILE=${FRAMEWORK_ROOT_DIR}/bin/gitIsAncestorOf
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE

.INCLUDE "$(dynamicTemplateDir _binaries/Git/gitIsAncestorOf.options.tpl)"

gitIsAncestorOfCommand parse "${BASH_FRAMEWORK_ARGV[@]}"

# @require Linux::requireExecutedAsUser
run() {

  if ! git cat-file -t "${commitArg}" &>/dev/null; then
    Log::displayError "Commit ${commitArg} does not exists at all"
    exit 1
  fi

  # shellcheck disable=SC2154
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
