#!/usr/bin/env bash

# option values
declare containerArg="default"
declare finalUserArg="${defaultUserArg}"
declare finalCommandArg=("${defaultCommandArg[@]}")

declare defaultUserArg="root"
declare -a defaultCommandArg=("//bin/sh")
declare PROFILES_DIR
declare HOME_PROFILES_DIR

beforeParseCallback() {
  BashTools::Conf::requireLoad
  Env::requireLoad
  UI::requireTheme
  Log::requireLoad
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
  Conf::load "cliProfiles" "default"
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
  echo -e "        ${SCRIPT_NAME} mysql mysql '/bin/bash'"
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
  Conf::load "cliProfiles" "default"
  echo "    Container should be the name of a profile from profile list,"
  echo "    check containers list below."
  echo "    If not provided, it will load the container specified in default configuration."
  # shellcheck disable=SC2154
  echo -e "    Default configuration: ${__HELP_OPTION_COLOR}${containerArg}${__HELP_NORMAL}"
  # shellcheck disable=SC2154
  echo -e "    Default container: ${__HELP_OPTION_COLOR}${finalContainerArg}${__HELP_NORMAL}"
}

userArgHelpFunction() {
  Conf::load "cliProfiles" "default"
  echo "    user to connect on this container" $'\n'
  # shellcheck disable=SC2154
  echo -e "    Default user: ${__HELP_OPTION_COLOR}${finalUserArg}${__HELP_NORMAL}"
  echo "      loaded from profile selected as first arg"
  echo "      or deduced from default configuration." $'\n'
  echo -e "    Default configuration: ${__HELP_OPTION_COLOR}${containerArg}${__HELP_NORMAL}" $'\n'
  echo "      if first arg is not a profile"
}

commandArgHelpFunction() {
  Conf::load "cliProfiles" "default"
  echo "The command to execute" $'\n'
  # shellcheck disable=SC2154
  echo -e "Default command: ${__HELP_OPTION_COLOR}${finalCommandArg[*]}${__HELP_NORMAL}"
  echo "  loaded from profile selected as first arg"
  echo "  or deduced from default configuration."
  echo -e "Default configuration: ${__HELP_OPTION_COLOR}${containerArg}${__HELP_NORMAL}" $'\n'
  echo "if first arg is not a profile"
}

# shellcheck disable=SC2317 # if function is overridden
unknownOption() {
  commandArg+=("$1")
}
