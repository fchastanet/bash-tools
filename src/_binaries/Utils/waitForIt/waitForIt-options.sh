#!/usr/bin/env bash

declare -a availableAlgos=(
  "timeoutV1WithNc"
  "timeoutV2WithNc"
  "whileLoopWithNc"
  "timeoutV1WithTcp"
  "timeoutV2WithTcp"
  "whileLoopWithTcp"
)

longDescriptionFunction() {
  echo -e "  ${__HELP_TITLE}EXIT STATUS CODES:${__HELP_NORMAL}"
  echo -e "    ${__HELP_OPTION_COLOR}0${__HELP_NORMAL}: the host/port is available"
  echo -e "    ${__HELP_OPTION_COLOR}1${__HELP_NORMAL}: indicates host/port is not available or argument error"
  echo -e "    ${__HELP_OPTION_COLOR}2${__HELP_NORMAL}: timeout reached"
  echo
  echo -e "  ${__HELP_TITLE}AVAILABLE ALGORITHMS:${__HELP_NORMAL}"
  echo -e "    ${__HELP_OPTION_COLOR}timeoutV1WithNc${__HELP_NORMAL}: previous version of timeout command with --timeout option, base command nc"
  echo -e "    ${__HELP_OPTION_COLOR}timeoutV2WithNc${__HELP_NORMAL}: newer version of timeout command using timeout as argument, base command nc"
  echo -e "    ${__HELP_OPTION_COLOR}whileLoopWithNc${__HELP_NORMAL}: timeout command simulated using while loop, base command nc"
  echo -e "    ${__HELP_OPTION_COLOR}timeoutV1WithTcp${__HELP_NORMAL}: previous version of timeout command with --timeout option"
  echo -e "    ${__HELP_OPTION_COLOR}timeoutV2WithTcp${__HELP_NORMAL}: newer version of timeout command using timeout as argument"
  echo -e "    ${__HELP_OPTION_COLOR}whileLoopWithTcp${__HELP_NORMAL}: timeout command simulated using while loop, base command tcp"
}

algorithmHelpFunction() {
  echo "    Algorithm to use Check algorithms list below."
  echo "    Default: automatic selection based on commands availability and timeout option value."
}

optionHelpCallback() {
  waitForItCommandHelp
  exit 0
}

# shellcheck disable=SC2317 # if function is overridden
unknownOption() {
  commandArgs+=("$1")
}

portArgCallback() {
  # shellcheck disable=SC2154
  if [[ ! "${portArg}" =~ ^[0-9]+$ ]] || ((portArg == 0)); then
    Log::fatal "${SCRIPT_NAME} - invalid port argument - must be greater than to 0"
  fi
}

optionAlgoCallback() {
  # shellcheck disable=SC2154
  if ! Array::contains "${optionAlgo}" "${availableAlgos[@]}"; then
    Log::fatal "${SCRIPT_NAME} - invalid algorithm option '${optionAlgo}'"
  fi
}

commandCallback() {
  # shellcheck disable=SC2154
  if [[ "${hostOrIpArg}" = "" || "${portArg}" = "" ]]; then
    Log::fatal "${SCRIPT_NAME} - you need to provide a host and port to test."
  fi
}
