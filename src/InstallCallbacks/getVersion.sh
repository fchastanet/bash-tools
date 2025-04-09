#!/usr/bin/env bash

# @description Get version of installed software
# @arg $1 newSoftware:String Name of the software
# @arg $2 versionArg:String Command to get version
# @exitcode 0:Success
InstallCallbacks::getVersion() {
  # local newSoftware="$1"
  local versionArg="$2"
  local tmpFile
  tmpFile="$(Framework::createTempFile)"
  (
    echo "#!/bin/bash"
    echo "set -e -o errexit -o pipefail"
    # shellcheck disable=SC2086
    echo ${versionArg}
  ) >"${tmpFile}"
  # shellcheck disable=SC1090
  source "${tmpFile}" | Version::parse || {
    Log::displayError "Failed to get version"
    return 1
  }
}
