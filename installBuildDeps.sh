#!/usr/bin/env bash
set -x
CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# load bash-framework
# shellcheck source=bash-framework/_bootstrap.sh
source "$( cd "${CURRENT_DIR}" && pwd )/bash-framework/_bootstrap.sh"

installGitVendor() {
  REPO="$1"
  INSTALL_DIR="$2"
  REVISION="$3"
  if [[ -d "${INSTALL_DIR}/.git" ]]; then
    (
      Log::displayInfo "Repository ${INSTALL_DIR} already installed"
      cd "${INSTALL_DIR}" || exit 1	
      git -c advice.detachedHead=false fetch --depth 1 origin "${REVISION}"
      git reset --hard FETCH_HEAD
    )
  else 
    (	
      Log::displayInfo "Installing ${INSTALL_DIR} ..."
      rm -Rf "${INSTALL_DIR}"	
      mkdir -p "${INSTALL_DIR}"
      cd "${INSTALL_DIR}" || exit 1	
      git init
      git remote add origin "${REPO}"
      git -c advice.detachedHead=false fetch origin "${REVISION}"
      git reset --hard FETCH_HEAD
    )
  fi
}

installGitVendor \
  "https://github.com/fchastanet/tomdoc.sh.git" \
  "${CURRENT_DIR}/vendor/fchastanet.tomdoc.sh" \
  "master"

installGitVendor \
  "https://github.com/bats-core/bats-core.git" \
  "${CURRENT_DIR}/vendor/bats" \
  "v1.2.1"

installGitVendor \
  "https://github.com/bats-core/bats-support.git" \
  "${CURRENT_DIR}/vendor/bats-support" \
  "d140a65044b2d6810381935ae7f0c94c7023c8c3"

installGitVendor \
  "https://github.com/bats-core/bats-assert.git" \
  "${CURRENT_DIR}/vendor/bats-assert" \
  "0a8dd57e2cc6d4cc064b1ed6b4e79b9f7fee096f"

installGitVendor \
  "https://github.com/Flamefire/bats-mock.git" \
  "${CURRENT_DIR}/vendor/bats-mock-Flamefire" \
  "1838e83473b14c79014d56f08f4c9e75d885d6b2"