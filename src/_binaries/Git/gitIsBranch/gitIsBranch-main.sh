#!/usr/bin/env bash
# shellcheck disable=SC2154

declare optionRedirectCmdOutputs=""
if [[ "${optionTraceVerbose}" != "1" ]]; then
  # shellcheck disable=SC2034 # used by BashTools::runVerboseIfNeeded
  optionRedirectCmdOutputs="/dev/null"
fi
BashTools::runVerboseIfNeeded git show-ref --verify refs/heads/"${branchNameArg}" ||
  BashTools::runVerboseIfNeeded git show-ref --verify refs/remotes/"${branchNameArg}" ||
  Log::fatal "not a branch name: ${branchNameArg}"
