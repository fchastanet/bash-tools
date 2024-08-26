#!/usr/bin/env bash

# shellcheck disable=SC2034
declare copyrightBeginYear="2020"
# shellcheck disable=SC2034
declare versionNumber="1.1"

declare optionBashFrameworkConfig="${BASH_TOOLS_ROOT_DIR}/.framework-config"

optionHelpCallback() {
  installCommandHelp
  exit 0
}
