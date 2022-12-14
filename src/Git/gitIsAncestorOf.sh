#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/gitIsAncestorOf
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

showHelp() {
  cat <<EOF
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

merge_base="$(git merge-base "${commit}" "${claimedBranch}")"
if [[ -z "${merge_base}" || "${merge_base}" != "$(git rev-parse --verify "${commit}")" ]]; then
  Log::fatal "${commit} is not an ancestor of ${claimedBranch}"
fi
