#!/usr/bin/env bash
# BIN_FILE=${BASH_TOOLS_ROOT_DIR}/bin/cli
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE
# shellcheck disable=SC2034

# constants
declare defaultUserArg="root"
declare -a defaultCommandArg=("//bin/sh")
declare PROFILES_DIR="${BASH_TOOLS_ROOT_DIR}/conf/cliProfiles"
declare HOME_PROFILES_DIR="${HOME}/.bash-tools/cliProfiles"

# option values
declare containerArg="default"
declare finalUserArg="${defaultUserArg}"
declare finalCommandArg=("${defaultCommandArg[@]}")

# other values
declare copyrightBeginYear="2020"

.INCLUDE "$(dynamicTemplateDir _binaries/Docker/cli.options.tpl)"

run() {
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

  # check dependencies
  Assert::commandExists docker "check https://docs.docker.com/engine/install/ubuntu/"

  # load default conf file
  Conf::load "cliProfiles" "default"

  # try to load config file associated to container if provided
  if [[ -n "${containerArg}" ]]; then
    Conf::load "cliProfiles" "${containerArg}" || {
      # conf file not existing fallback to provided args or to default ones if not provided
      finalContainerArg="${containerArg}"
      finalUserArg=${userArg:-${finalUserArg}}
      finalCommandArg=("${commandArg[@]:-${finalCommandArg[@]}}")
    }
  fi

  declare -a cmd=()
  if Assert::windows; then
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
  if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "0" ]]; then
    (echo >&2 MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' "${cmd[@]}")
  fi
  MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' "${cmd[@]}"
}

if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "1" ]]; then
  run &>/dev/null
else
  run
fi
