#!/usr/bin/env bash

# shellcheck disable=SC2034
declare optionBashFrameworkConfig="${BASH_TOOLS_ROOT_DIR}/.framework-config"

optionHelpCallback() {
  docCommandHelp
  exit 0
}
