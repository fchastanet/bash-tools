#!/usr/bin/env bash

# @description Install tar.xz file
# @arg $1 newSoftware:String Name of the software
# @arg $2 targetFileArg:String Target file
# @exitcode 0:Success
InstallCallbacks::installFromTarXz() {
  local newSoftware="$1"
  local targetFileArg="$2"

  Log::displayInfo "Installing ${newSoftware} to ${targetFileArg}"
  # Create temp directory
  local tempDir
  tempDir="$(mktemp -d)"

  # Extract to temp directory
  tar xvf "${newSoftware}" -C "${tempDir}"

  # Find and move file, ignoring directory structure
  sudo find "${tempDir}" -type f -name "${targetFileArg##*/}" -exec mv {} "${targetFileArg}" \;

  # Set permissions
  sudo chmod +x "${targetFileArg}"
  hash -r

  # Cleanup
  sudo rm -rf "${tempDir}" "${newSoftware}"
}
