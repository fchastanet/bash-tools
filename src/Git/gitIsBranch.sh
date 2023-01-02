#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/gitIsBranch
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

HELP="$(
  cat <<EOF
${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} <branchName>
show an error if branchName is not a known branch

.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/author.tpl"
EOF
)"
Args::defaultHelp "${HELP}" "$@"

if [[ "$#" != "1" ]]; then
  Log::fatal "$0: invalid arguments"
fi
branch="$1"

# check various branch hierarchies, adjust as needed
git show-ref --verify refs/heads/"${branch}" ||
  git show-ref --verify refs/remotes/"${branch}" ||
  Log::fatal "not a branch name: ${branch}"
