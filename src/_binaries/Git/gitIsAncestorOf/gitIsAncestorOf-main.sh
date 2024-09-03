#!/usr/bin/env bash

runVerboseIfNeeded() {
  (
    # shellcheck disable=SC2154
    if [[ "${optionTraceVerbose}" = "1" ]]; then
      set -x
    fi
    "$@"
  )
}
# shellcheck disable=SC2154
if ! runVerboseIfNeeded git cat-file -t "${refArg}" &>/dev/null; then
  Log::displayError "Ref ${refArg} does not exists at all"
  exit 1
fi
# shellcheck disable=SC2154
if ! runVerboseIfNeeded git cat-file -t "${claimedBranchArg}" &>/dev/null; then
  Log::displayError "Ref ${claimedBranchArg} does not exists at all"
  exit 1
fi

declare refCommit claimedBranchCommit
refCommit="$(git rev-parse "${refArg}")" || {
  Log::displayError "Ref ${refArg} is not convertible to commit sha"
  exit 1
}

claimedBranchCommit="$(git rev-parse "${claimedBranchArg}")" || {
  Log::displayError "Ref ${claimedBranchArg} is not convertible to commit sha"
  exit 1
}

declare revParse mergeBase
# shellcheck disable=SC2154
mergeBase="$(runVerboseIfNeeded git merge-base "${refCommit}" "${claimedBranchCommit}")"
revParse="$(runVerboseIfNeeded git rev-parse --verify "${refCommit}")"

if [[ -z "${mergeBase}" || "${mergeBase}" != "${revParse}" ]]; then
  Log::displayError "Commit ${refArg} is not an ancestor of branch ${claimedBranchArg}"
  exit 2
fi
