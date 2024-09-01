#!/usr/bin/env bash

# shellcheck disable=SC2034
declare optionBashFrameworkConfig="${BASH_TOOLS_ROOT_DIR}/.framework-config"

optionHelpCallback() {
  installRequirementsCommandHelp
  exit 0
}
