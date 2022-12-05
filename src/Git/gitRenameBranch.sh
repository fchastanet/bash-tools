#!/usr/bin/env bash

# load bash-framework
CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# shellcheck source=/bash-framework/_bootstrap.sh
source "$( cd "${CURRENT_DIR}/.." && pwd )/bash-framework/_bootstrap.sh"

import bash-framework/UI

#default values
SCRIPT_NAME=${0##*/}
PUSH="0"
DELETE="0"
INTERACTIVE="1"

# Usage info
showHelp() {
cat << EOF
${__HELP_TITLE}Description:${__HELP_NORMAL} rename git local branch, use options to push new branch and delete old branch

${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} [-h|--help] prints this help and exits
${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} <newBranchName> [<oldBranchName>] [--push|-p] [--delete|-d] [--assume-yes|-yes|-y]
    --help,-h prints this help and exits
     -y, --yes, --assume-yes do not ask for confirmation (use with caution)
        Automatic yes to prompts; assume "y" as answer to all prompts
        and run non-interactively.
    --push,-p push new branch
    --delete,-d delete old remote branch
    <newBranchName> the new branch name to give to current branch
    <oldBranchName> (optional) the name of the old branch if not current one
EOF
}

# read command parameters
# $@ is all command line parameters passed to the script.
# -o is for short options like -h
# -l is for long options with double dash like --help
# the comma separates different long options
options=$(getopt -l help,push,delete,yes,assume-yes -o hpdy -- "$@" 2>/dev/null) || {
    showHelp
    Log::fatal "invalid options specified"
}

eval set -- "${options}"
while true
do
case $1 in
-h|--help)
    showHelp
    exit 0
    ;;
--push|-p)
    PUSH="1"
    ;;
--delete|-d)
    DELETE="1"
    ;;
--assume-yes|-yes|-y)
    INTERACTIVE="0"
    ;;
--)
    shift || true
    break;;
*)
    showHelp
    Log::fatal "invalid argument $1"
esac
shift || true
done
shift $(( OPTIND - 1 )) || true

newName="$1"
shift || true
oldName="${1:-}"
shift || true
if [ $# -gt 0 ]; then
  showHelp
  Log::fatal "too much arguments provided"
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  Log::fatal "not a git repository (or any of the parent directories)"
fi

if [ -z "${oldName}" ]; then
  oldName="$(git branch --show-current)"
  [ -z "${oldName}" ] && Log::fatal "Impossible to calculate current branch name"
fi
[[ "${oldName}" =~ ^(master|main)$ ]] &&
  Log::fatal "master/main branch not supported by this command, please do it manually"
[[ "${newName}" =~ ^(master|main)$ ]] &&
  Log::fatal "master/main branch not supported by this command, please do it manually"
[ -z "${newName}" ] && Log::fatal "new branch name not provided"
[ "${oldName}" = "${newName}" ] && Log::fatal "Branch name has not changed"

Log::displayInfo "Renaming branch locally from ${oldName} to ${newName}"
CMD="git branch -m \"${oldName}\" \"${newName}\""
Log::displayDebug "Running '${CMD}'"
eval "${CMD}"

if [ "${DELETE}" = "1" ]; then
  deleteBranch() {
    Log::displayInfo "Removing eventual old remote branch ${oldName}"
    CMD="git push origin \":${oldName}\""
    Log::displayDebug "Running '${CMD}'"
    eval "${CMD}" || true
  }
  if [[ "${INTERACTIVE}" = "0" ]] || UI::askYesNo "remove eventual old remote branch ${oldName}" ; then
    deleteBranch
  fi
fi
if [ "${PUSH}" = "1" ]; then
  push() {
    Log::displayInfo "Pushing new branch name ${newName}"
    CMD="git push --set-upstream origin \"${newName}\""
    Log::displayDebug "Running '${CMD}'"
    eval "${CMD}" || true
  }
  if [[ "${INTERACTIVE}" = "0" ]] || UI::askYesNo "Push new branch name ${newName}"; then
    push
  fi
fi