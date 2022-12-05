#!/usr/bin/env bash

SCRIPT_NAME=${0##*/}

CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# load bash-framework
# shellcheck source=bash-framework/_bootstrap.sh
source "$( cd "${CURRENT_DIR}/.." && pwd )/bash-framework/_bootstrap.sh"

showHelp() {
cat << EOF
${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} <branch> <commit>
show an error if commit is not an ancestor of branch
EOF
}

if [[ "$1" == '--help' || "$1" == '-h' ]]; then
  showHelp
  exit 0
fi

if [[ "$#" != "2" ]]; then
    showHelp
    Log::fatal "${SCRIPT_NAME}: invalid arguments"
fi

claimedBranch="$1"
commit="$2"

merge_base="$(git merge-base "${commit}" "${claimedBranch}")" &&
  test -n "$merge_base" &&
  test "$merge_base" = "$(git rev-parse --verify "${commit}")" &&
  exit 0

Log::fatal "${commit} is not an ancestor of ${claimedBranch}"
