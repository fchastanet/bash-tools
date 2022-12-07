#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/cli
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

Assert::expectNonRootUser

Framework::loadEnv

# ensure that Ctrl-C is trapped by this script
trap 'exit 130' INT

# check dependencies
Assert::commandExists docker "check https://docs.docker.com/engine/install/ubuntu/"

SCRIPT_NAME=${0##*/}
PROFILES_DIR="${ROOT_DIR}/conf/cliProfiles"
HOME_PROFILES_DIR="${HOME}/.bash-tools/cliProfiles"

showHelp() {
  local containers
  containers=$(docker ps --format '{{.Names}}' | sed -E 's/[^-]+-(.*)/\1/' | paste -sd "," -)
  local profilesList=""
  Profiles::loadConf "cliProfiles" "default"

  profilesList="$(Profiles::getConfMergedList "cliProfiles" ".sh" || true)"

  cat <<EOF
${__HELP_TITLE}Description:${__HELP_NORMAL} easy connection to docker container

${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} [-h|--help] prints this help and exits
${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} [<container>] [user] [command]

    <container> : container should be one of these values (provided by 'docker ps'):
        ${containers}
        if not provided, it will load the container specified in default configuration (${finalContainerArg})

${__HELP_TITLE}examples:${__HELP_NORMAL}
    to connect to mysql container in bash mode with user mysql
        ${SCRIPT_NAME} mysql mysql "//bin/bash"
    to connect to web container with user root
        ${SCRIPT_NAME} web root

you can override these mappings by providing your own profile in ${CLI_PROFILE_HOME}

This script will be executed with the variables userArg containerArg commandArg set as specified in command line
and should provide value for the following variables finalUserArg finalContainerArg finalCommandArg

${__HELP_TITLE}List of available profiles (from ${PROFILES_DIR} and can be overridden in ${HOME_PROFILES_DIR}):${__HELP_NORMAL}
${profilesList}
EOF
}

# Internal function that can be used in conf profiles to load the dsn file
loadDsn() {
  local dsn="$1"
  local dsnFile
  dsnFile="$(Profiles::getAbsoluteConfFile "dsn" "${dsn}" "env")"
  Database::checkDsnFile "${dsnFile}"
  # shellcheck source=/conf/dsn/default.local.env
  # shellcheck disable=SC1091
  source "${dsnFile}"
}

# read command parameters
# $@ is all command line parameters passed to the script.
# -o is for short options like -h
# -l is for long options with double dash like --help
# the comma separates different long options
options=$(getopt -l help -o h -- "$@" 2>/dev/null) || {
  showHelp
  Log::fatal "invalid options specified"
}

eval set -- "${options}"
while true; do
  case $1 in
    -h | --help)
      showHelp
      exit 0
      ;;
    --)
      shift || true
      break
      ;;
    *)
      showHelp
      Log::fatal "invalid argument $1"
      ;;
  esac
  shift || true
done

declare containerArg="$1"
declare userArg
declare -a commandArg
if shift; then
  userArg="$1"
fi
if shift; then
  commandArg=("$@")
fi

# load default conf file
Profiles::loadConf "cliProfiles" "default"
# try to load config file associated to container if provided
if [[ -n "${containerArg}" ]]; then
  Profiles::loadConf "cliProfiles" "${containerArg}" || {
    # conf file not existing fallback to provided args or to default ones if not provided
    finalContainerArg="${containerArg}"
    finalUserArg=${userArg:-${finalUserArg}}
    finalCommandArg=${commandArg:-${finalCommandArg}}
  }
fi

declare -a cmd=()
if [[ "$(
  Assert::windows
  echo $?
)" = "1" ]]; then
  # open tty for git bash
  cmd+=(winpty)
fi
INTERACTIVE_MODE="-i"
if ! read -r -t 0; then
  # command is not piped or TTY not available
  INTERACTIVE_MODE+="t"
fi

cmd+=(docker)
cmd+=(exec)
cmd+=("${INTERACTIVE_MODE}")
# ensure column/lines will be updated upon terminal resize
cmd+=(-e)
cmd+=("COLUMNS=$(tput cols)")
cmd+=(-e)
cmd+=("LINES=$(tput lines)")

cmd+=("--user=${finalUserArg}")
cmd+=("${finalContainerArg}")
cmd+=("${finalCommandArg[@]}")
(echo >&2 MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' "${cmd[@]}")
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' "${cmd[@]}"
