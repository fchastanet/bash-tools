#!/usr/bin/env bash

# option values
# shellcheck disable=SC2034
declare containerArg="default"
declare finalUserArg="${defaultUserArg}"
declare finalCommandArg=("${defaultCommandArg[@]}")

declare defaultConfiguration="default"
declare defaultUserArg="root"
declare -a defaultCommandArg=("//bin/sh")
declare PROFILES_DIR
declare HOME_PROFILES_DIR

beforeParseCallback() {
  defaultBeforeParseCallback
  Linux::requireRealpathCommand
  Assert::commandExists docker "check https://docs.docker.com/engine/install/ubuntu/"
}

# Internal function that can be used in conf profiles to load the dsn file
loadDsn() {
  local dsn="$1"
  local dsnFile
  dsnFile="$(Conf::getAbsoluteFile "dsn" "${dsn}" "env")"
  Database::checkDsnFile "${dsnFile}"
  # shellcheck source=/conf/dsn/default.local.env
  # shellcheck disable=SC1091
  source "${dsnFile}"
}
export -f loadDsn

initConf() {
  PROFILES_DIR="${BASH_TOOLS_ROOT_DIR}/conf/cliProfiles"
  HOME_PROFILES_DIR="${HOME}/.bash-tools/cliProfiles"
  # load default conf file
  Conf::load "cliProfiles" "${defaultConfiguration}"
}

optionHelpCallback() {
  cliCommandHelp
  exit 0
}

longDescriptionFunction() {
  echo -e "${__HELP_TITLE}AVAILABLE PROFILES (from ${PROFILES_DIR})${__HELP_NORMAL}"
  echo -e "This list can be overridden in ${HOME_PROFILES_DIR}"
  echo
  Conf::getMergedList "cliProfiles" ".sh" "  - " || true
  echo
  echo -e "${__HELP_TITLE}AVAILABLE CONTAINERS:${__HELP_NORMAL}"
  Array::wrap2 ", " 80 0 "$(docker ps --format '{{"{{"}}.Names{{"}}"}}')"
  echo
  echo -e "${__HELP_TITLE}EXAMPLES:${__HELP_EXAMPLE}"
  echo -e "    to connect to mysql container in bash mode with user mysql"
  echo -e "        ${SCRIPT_NAME} mysql-container-name mysql '/bin/bash'"
  echo -e "    to connect to web container with user root"
  echo -e "        ${SCRIPT_NAME} web root"
  echo -e "${__HELP_NORMAL}"
  echo
  echo -e "${__HELP_TITLE}CREATE NEW PROFILE:${__HELP_NORMAL}"
  echo -e "You can create new profiles in ${HOME_PROFILES_DIR}."
  echo -e "This script will be called with the"
  echo -e "arguments ${__HELP_OPTION_COLOR}userArg${__HELP_NORMAL}, ${__HELP_OPTION_COLOR}containerArg${__HELP_NORMAL}, ${__HELP_OPTION_COLOR}commandArg${__HELP_NORMAL}"
  echo -e "The script has to compute the following"
  echo -e "variables ${__HELP_OPTION_COLOR}finalUserArg${__HELP_NORMAL}, ${__HELP_OPTION_COLOR}finalContainerArg${__HELP_NORMAL}, ${__HELP_OPTION_COLOR}finalCommandArg${__HELP_NORMAL}"
}

containerArgHelpFunction() {
  Conf::load "cliProfiles" "${defaultConfiguration}"
  echo -e "    Container should be the name of a profile from profile list,"
  echo -e "    check containers list below."
  echo
  echo -e "    If no value provided, it will load the container"
  echo -e "    specified in ${__HELP_OPTION_COLOR}${defaultConfiguration}${__HELP_NORMAL} configuration."
  # shellcheck disable=SC2154
  echo -e "    Default: ${__HELP_OPTION_COLOR}${finalContainerArg}${__HELP_NORMAL}"
  echo
}

userArgHelpFunction() {
  Conf::load "cliProfiles" "${defaultConfiguration}"
  echo -e "    user to connect on this container"
  echo
  echo -e "    If no value provided, it will load the user"
  echo -e "    specified in ${__HELP_OPTION_COLOR}${defaultConfiguration}${__HELP_NORMAL} configuration."
  # shellcheck disable=SC2154
  echo -e "    Default: ${__HELP_OPTION_COLOR}${finalUserArg}${__HELP_NORMAL}"
  echo
}

commandArgHelpFunction() {
  Conf::load "cliProfiles" "${defaultConfiguration}"
  echo -e "    The command to execute"
  echo
  echo -e "    If no value provided, it will load the command"
  echo -e "    specified in ${__HELP_OPTION_COLOR}${defaultConfiguration}${__HELP_NORMAL} configuration."
  # shellcheck disable=SC2154
  echo -e "    Default: ${__HELP_OPTION_COLOR}${finalCommandArg[*]}${__HELP_NORMAL}"
  echo
}

# shellcheck disable=SC2317 # if function is overridden
unknownOption() {
  commandArg+=("$1")
}
