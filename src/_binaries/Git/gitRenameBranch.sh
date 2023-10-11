#!/usr/bin/env bash
# BIN_FILE=${FRAMEWORK_ROOT_DIR}/bin/gitRenameBranch
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE
# shellcheck disable=SC2154

.INCLUDE "$(dynamicTemplateDir _binaries/Git/gitRenameBranch.options.tpl)"

gitRenameBranchCommand parse "${BASH_FRAMEWORK_ARGV[@]}"

# @require Linux::requireExecutedAsUser
run() {
  local -a cmd=()
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    Log::displayError "not a git repository (or any of the parent directories)"
    exit 1
  fi

  if [[ -z "${oldBranchNameArg}" ]]; then
    oldBranchNameArg="$(git branch --show-current)"
    if [[ -z "${oldBranchNameArg}" ]]; then
      Log::displayError "Impossible to compute current branch name"
      exit 2
    fi
  fi

  if [[ "${oldBranchNameArg}" =~ ^(master|main)$ || "${newBranchNameArg}" =~ ^(master|main)$ ]]; then
    Log::displayError "master/main branch not supported by this command, please do it manually"
    exit 3
  fi

  if [[ -z "${newBranchNameArg}" ]]; then
    Log::displayError "new branch name not provided"
    exit 4
  fi

  if [[ "${oldBranchNameArg}" = "${newBranchNameArg}" ]]; then
    Log::displayError "New and old branch names are the same"
    exit 5
  fi

  Log::displayInfo "Renaming branch locally from ${oldBranchNameArg} to ${newBranchNameArg}"
  declare -a cmd=()
  cmd=(git branch -m "${oldBranchNameArg}" "${newBranchNameArg}")
  Log::displayDebug "Running '${cmd[*]}'"
  if ! "${cmd[@]}"; then
    Log::displayError "Failed to rename local branch ${oldBranchNameArg} to ${newBranchNameArg}"
    exit 7
  fi

  if [[ "${optionDelete}" = "1" ]]; then
    if [[ "${optionAssumeYes}" = "1" ]] || UI::askYesNo "Remove eventual old remote branch ${oldBranchNameArg}"; then
      Log::displayInfo "Removing eventual old remote branch ${oldBranchNameArg}"
      cmd=(git push origin ":${oldBranchNameArg}")
      Log::displayDebug "Running '${cmd[*]}'"
      if ! "${cmd[@]}"; then
        Log::displayError "Failed to delete remote branch ${oldBranchNameArg}"
        exit 8
      fi
    fi
  fi

  if [[ "${optionPush}" = "1" ]]; then
    if [[ "${optionAssumeYes}" = "1" ]] || UI::askYesNo "Push new branch name ${newBranchNameArg}"; then
      Log::displayInfo "Pushing new branch name ${newBranchNameArg}"
      cmd=(git push --set-upstream origin "${newBranchNameArg}")
      Log::displayDebug "Running '${cmd[*]}'"
      if ! "${cmd[@]}"; then
        Log::displayError "Failed to push the new branch ${newBranchNameArg}"
        exit 9
      fi
    fi
  fi
}

if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "1" ]]; then
  run &>/dev/null
else
  run
fi

