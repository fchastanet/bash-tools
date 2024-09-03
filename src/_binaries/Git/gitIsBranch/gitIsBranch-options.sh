#!/usr/bin/env bash

longDescriptionFunction() {
  echo -e "  ${__HELP_TITLE}EXIT CODES:${__HELP_NORMAL}"
  echo -e "    ${__HELP_OPTION_COLOR}1${__HELP_NORMAL}: if commit does not exists"
  echo -e "    ${__HELP_OPTION_COLOR}2${__HELP_NORMAL}: if ref is not convertible to commit oid"
  echo -e "    ${__HELP_OPTION_COLOR}3${__HELP_NORMAL}: if commit is not included in given branch"
}

optionHelpCallback() {
  gitIsBranchCommandHelp
  exit 0
}
