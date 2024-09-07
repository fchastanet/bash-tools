#!/usr/bin/env bash

longDescriptionFunction() {
  echo -e "  ${__HELP_TITLE}EXIT STATUS CODES:${__HELP_NORMAL}"
  echo -e "    ${__HELP_OPTION_COLOR}0${__HELP_NORMAL}: mysql is available"
  echo -e "    ${__HELP_OPTION_COLOR}1${__HELP_NORMAL}: indicates mysql is not available or argument error"
  echo -e "    ${__HELP_OPTION_COLOR}2${__HELP_NORMAL}: timeout reached"
}

optionHelpCallback() {
  waitForMysqlCommandHelp
  exit 0
}

mysqlPortArgCallback() {
  # shellcheck disable=SC2154
  if [[ ! "${mysqlPortArg}" =~ ^[0-9]+$ ]] || ((mysqlPortArg == 0)); then
    Log::fatal "${SCRIPT_NAME} - invalid port option - must be greater than to 0"
  fi
}

# shellcheck disable=SC2317 # if function is overridden
unknownOption() {
  commandArgs+=("$1")
}
