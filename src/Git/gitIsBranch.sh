#!/usr/bin/env bash

SCRIPT_NAME=${0##*/}

CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# load bash-framework
# shellcheck source=bash-framework/_bootstrap.sh
source "$( cd "${CURRENT_DIR}/.." && pwd )/bash-framework/_bootstrap.sh"

showHelp() {
cat << EOF
${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} <branchName>
show an error if branchName is not a known branch
EOF
}

if [[ "$1" == '--help' || "$1" == '-h' ]]; then
  showHelp
  exit 0
fi

if [[ "$#" != "1" ]]; then
    showHelp
    Log::fatal "$0: invalid arguments"
fi
branch="$1"

# check various branch hierarchies, adjust as needed
git show-ref --verify refs/heads/"$branch" ||
git show-ref --verify refs/remotes/"$branch" ||
    Log::fatal "not a branch name: $branch"
