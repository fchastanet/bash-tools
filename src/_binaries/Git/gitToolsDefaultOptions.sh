#!/usr/bin/env bash

beforeParseCallback() {
  Linux::requireExecutedAsUser
  BashTools::Conf::requireLoad
  Env::requireLoad
  UI::requireTheme
  Log::requireLoad
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
