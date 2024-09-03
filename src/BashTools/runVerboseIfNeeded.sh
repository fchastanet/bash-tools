#!/bin/bash

# @description run command specified
# @arg $@ array:String[] the command to run
# @env optionTraceVerbose int - if 1 displays the command specified before running it
# @env optionRedirectCmdOutputs String - if set redirect command outputs to file specified
# @exitcode command's exit code
BashTools::runVerboseIfNeeded() {
  # shellcheck disable=SC2154
  if [[ "${optionTraceVerbose}" = "1" ]]; then
    echo >&2 "+ $*"
  fi
  (
    # shellcheck disable=SC2154
    if [[ -n "${optionRedirectCmdOutputs:-}" ]]; then
      exec >"${optionRedirectCmdOutputs:-}"
      exec 2>"${optionRedirectCmdOutputs:-}"
    fi
    "$@"
  )
}
