#!/usr/bin/env bash

beforeParseCallback() {
  defaultBeforeParseCallback
  Linux::requireExecutedAsUser
}

declare optionRedirectCmdOutputs=""
optionRedirectCmdOutputs() {
  export optionTraceVerbose
  # shellcheck disable=SC2154
  if [[ "${optionTraceVerbose}" != "1" ]]; then
    # shellcheck disable=SC2034 # used by BashTools::runVerboseIfNeeded
    optionRedirectCmdOutputs="/dev/null"
  fi
}
