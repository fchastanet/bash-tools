#!/usr/bin/env bash
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
      git fetch >/dev/null
      git -c advice.detachedHead=false checkout "${REVISION}"
    )
  else 
    (	
      Log::displayInfo "Installing ${INSTALL_DIR} ..."
      rm -Rf "${INSTALL_DIR}"	
      git clone "${REPO}" "${INSTALL_DIR}"	
      cd "${INSTALL_DIR}" || exit 1	
      git -c advice.detachedHead=false checkout "${REVISION}"
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
  "d140a65"

installGitVendor \
  "https://github.com/bats-core/bats-assert.git" \
  "${CURRENT_DIR}/vendor/bats-assert" \
  "0a8dd57"

installGitVendor \
  "https://github.com/Flamefire/bats-mock.git" \
  "${CURRENT_DIR}/vendor/bats-mock-Flamefire" \
  "1838e83"