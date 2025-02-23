#!/usr/bin/env bash

# @description Install Debian package (with .deb extension)
# @arg $1 debFile:String
InstallCallbacks::installDeb() {
  local newSoftware="$1"
  Log::displayInfo "Installing Debian package ${newSoftware}"
  sudo dpkg -i "${newSoftware}"
  sudo rm -f "${newSoftware}"
}
