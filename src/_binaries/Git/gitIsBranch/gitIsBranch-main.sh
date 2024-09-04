#!/usr/bin/env bash
# shellcheck disable=SC2154

BashTools::runVerboseIfNeeded git show-ref --verify refs/heads/"${branchNameArg}" ||
  BashTools::runVerboseIfNeeded git show-ref --verify refs/remotes/"${branchNameArg}" ||
  Log::fatal "not a branch name: ${branchNameArg}"
