#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/gitIsBranch
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

showHelp() {
  cat <<EOF
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
git show-ref --verify refs/heads/"${branch}" ||
  git show-ref --verify refs/remotes/"${branch}" ||
  Log::fatal "not a branch name: ${branch}"
