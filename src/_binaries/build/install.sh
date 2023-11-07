#!/usr/bin/env bash
# BIN_FILE=${FRAMEWORK_ROOT_DIR}/install
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=.
# FACADE
# shellcheck disable=SC2034

declare copyrightBeginYear="2020"
declare optionBashFrameworkConfig="${BASH_TOOLS_ROOT_DIR}/.framework-config"

.INCLUDE "$(dynamicTemplateDir _binaries/build/install.options.tpl)"

# @require Linux::requireExecutedAsUser
run() {
  if ! command -v parallel &>/dev/null; then
    Log::displayInfo "We will install GNU parallel software, please enter you sudo password"
    sudo apt update || true
    if sudo apt install -y parallel; then
      # remove parallel nagware
      mkdir -p ~/.parallel
      touch ~/.parallel/will-cite
    else
      Log::displayWarning "Impossible to install GNU parallel, please install it manually"
    fi
  else
    Log::displaySkipped "parallel is already installed"
  fi

  if [[ -d "${HOME}/.bash-tools" ]]; then
    Log::displayInfo "Updating configuration"
    cp -R --no-clobber "${BASH_TOOLS_ROOT_DIR}/conf/." "${HOME}/.bash-tools"
    if [[ "${BASE_DIR}/conf/.env" -nt "${HOME}/.bash-tools/.env" ]]; then
      Log::displayWarning "${BASE_DIR}/conf/.env is newer than ${HOME}/.bash-tools/.env, compare the files to check if some updates need to be applied"
    else
      Log::displaySkipped "${HOME}/.bash-tools/.env is up to date"
    fi
  else
    Log::displayInfo "Installing configuration in ~/.bash-tools"
    mkdir -p ~/.bash-tools
    cp -R conf/. ~/.bash-tools
  fi
}

if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "1" ]]; then
  run &>/dev/null
else
  run
fi
