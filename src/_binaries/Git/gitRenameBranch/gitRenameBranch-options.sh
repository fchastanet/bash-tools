#!/usr/bin/env bash

longDescriptionFunction() {
  echo -e "  ${__HELP_TITLE}EXIT CODES:${__HELP_NORMAL}"
  echo -e "  ${__HELP_OPTION_COLOR}1${__HELP_NORMAL} : if current directory is not a git repository"
  echo -e "      or if invalid or missing arguments"
  echo -e "  ${__HELP_OPTION_COLOR}2${__HELP_NORMAL} : if impossible to compute current branch name"
  echo -e "  ${__HELP_OPTION_COLOR}3${__HELP_NORMAL} : master/main branch not supported by this command,"
  echo -e "      please do it manually"
  echo -e "  ${__HELP_OPTION_COLOR}5${__HELP_NORMAL} : New and old branch names are the same"
  echo -e "  ${__HELP_OPTION_COLOR}6${__HELP_NORMAL} : You can use this tool in non interactive mode only"
  echo -e "      if --assume-yes option is provided"
  echo -e "  ${__HELP_OPTION_COLOR}7${__HELP_NORMAL} : if failed to rename local branch"
  echo -e "  ${__HELP_OPTION_COLOR}8${__HELP_NORMAL} : if remote branch deletion failed"
  echo -e "  ${__HELP_OPTION_COLOR}9${__HELP_NORMAL} : if failed to push the new branch"
  echo
}

optionHelpCallback() {
  gitRenameBranchCommandHelp
  exit 0
}

assumeYesHelpFunction() {
  echo "    Do not ask for confirmation (use with caution)."
  echo '    Automatic yes to prompts; assume "y" as answer to all prompts'
  echo '    and run non-interactively.'
}

commandCallback() {
  # shellcheck disable=SC2154
  if ! Assert::tty && [[ "${optionAssumeYes}" != "1" ]]; then
    Log::displayError "You can use this tool in non interactive mode only if --assume-yes option is provided"
    exit 6
  fi
}
