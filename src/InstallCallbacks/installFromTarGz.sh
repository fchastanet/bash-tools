#!/usr/bin/env bash

# @description Install tar.gz file
# @arg $1 newSoftware:String Name of the software
# @arg $2 targetFileArg:String Target file
# @exitcode 0:Success
InstallCallbacks::installFromTarGz() {
  local newSoftware="$1"
  local targetFileArg="$2"
  Log::displayInfo "Installing ${newSoftware} to ${targetFileArg}"
  sudo tar xzvf "${newSoftware}" -C "${targetFileArg%/*}" "${targetFileArg##*/}"
  sudo chmod +x "${targetFileArg}"
  hash -r
  sudo rm -f "${newSoftware}"
}
