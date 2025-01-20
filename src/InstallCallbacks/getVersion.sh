#!/usr/bin/env bash

# @description Get version of installed software
# @arg $1 newSoftware:String Name of the software
# @arg $2 versionArg:String Command to get version
# @exitcode 0:Success
InstallCallbacks::getVersion() {
  # local newSoftware="$1"
  local versionArg="$2"
  eval "${versionArg}" || {
    Log::displayError "Failed to get version"
    return 1
  }
}
