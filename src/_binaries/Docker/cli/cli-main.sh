#!/usr/bin/env bash

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
  cmd+=(
    MSYS_NO_PATHCONV=1
    MSYS2_ARG_CONV_EXCL='*'
    winpty
  )
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

(
  if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "0" ]]; then
    set -x
  fi
  "${cmd[@]}"
)
