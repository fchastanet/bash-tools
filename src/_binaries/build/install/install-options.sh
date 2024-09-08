#!/usr/bin/env bash

# shellcheck disable=SC2034
declare optionBashFrameworkConfig="${BASH_TOOLS_ROOT_DIR}/.framework-config"

optionHelpCallback() {
  installCommandHelp
  exit 0
}

beforeParseCallback() {
  defaultBeforeParseCallback
  Linux::requireExecutedAsUser
  Linux::requireTarCommand
}
