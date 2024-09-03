#!/usr/bin/env bash

# shellcheck disable=SC2154
if ! optionRedirectCmdOutputs=/dev/null BashTools::runVerboseIfNeeded git cat-file -t "${refArg}"; then
  Log::displayError "Ref ${refArg} does not exists at all"
  exit 1
fi
# shellcheck disable=SC2154
if ! optionRedirectCmdOutputs=/dev/null BashTools::runVerboseIfNeeded git cat-file -t "${claimedBranchArg}"; then
  Log::displayError "Ref ${claimedBranchArg} does not exists at all"
  exit 1
fi

declare refCommit claimedBranchCommit
refCommit="$(BashTools::runVerboseIfNeeded git rev-parse "${refArg}")" || {
  Log::displayError "Ref ${refArg} is not convertible to commit sha"
  exit 1
}

claimedBranchCommit="$(BashTools::runVerboseIfNeeded git rev-parse "${claimedBranchArg}")" || {
  Log::displayError "Ref ${claimedBranchArg} is not convertible to commit sha"
  exit 1
}

declare revParse mergeBase
# shellcheck disable=SC2154
mergeBase="$(BashTools::runVerboseIfNeeded git merge-base "${refCommit}" "${claimedBranchCommit}")"
revParse="$(BashTools::runVerboseIfNeeded git rev-parse --verify "${refCommit}")"

if [[ -z "${mergeBase}" || "${mergeBase}" != "${revParse}" ]]; then
  Log::displayError "Commit ${refArg} is not an ancestor of branch ${claimedBranchArg}"
  exit 2
fi
