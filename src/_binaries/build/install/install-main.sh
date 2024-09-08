#!/usr/bin/env bash

if ! command -v parallel &>/dev/null; then
  Log::displayInfo "We will install GNU parallel software, please enter you sudo password"
  sudo apt-get update || true
  if sudo apt-get install -y parallel; then
    # remove parallel nagware
    mkdir -p "${HOME}/.parallel"
    touch "${HOME}/.parallel/will-cite"
  else
    Log::displayWarning "Impossible to install GNU parallel, please install it manually"
  fi
else
  Log::displaySkipped "parallel is already installed"
fi

if [[ -d "${HOME}/.bash-tools" ]]; then
  # shellcheck disable=SC2154
  if [[ "${optionSkipBackup}" = "1" ]]; then
    Log::displayInfo "Backup of ~/.bash-tools is set to be skipped"
  else
    BACKUP_DIR="${FRAMEWORK_ROOT_DIR}/logs" \
      Backup::dir "${HOME}" ".bash-tools"
  fi

  Log::displayInfo "Updating configuration"
  cp -R --no-clobber "${BASH_TOOLS_ROOT_DIR}/conf/." "${HOME}/.bash-tools"
  cp "${BASH_TOOLS_ROOT_DIR}/conf/defaultEnv/.env" "${HOME}/.bash-tools"
  if [[ "${FRAMEWORK_ROOT_DIR}/conf/.env" -nt "${HOME}/.bash-tools/.env" ]]; then
    Log::displayWarning "${FRAMEWORK_ROOT_DIR}/conf/.env is newer than ${HOME}/.bash-tools/.env, compare the files to check if some updates need to be applied"
  else
    Log::displaySkipped "${HOME}/.bash-tools/.env is up to date"
  fi
else
  Log::displayInfo "Installing configuration in ~/.bash-tools"
  mkdir -p "${HOME}/.bash-tools"
  cp -R "${BASH_TOOLS_ROOT_DIR}/conf/." "${HOME}/.bash-tools"
  cp "${BASH_TOOLS_ROOT_DIR}/conf/defaultEnv/.env" "${HOME}/.bash-tools"
fi
