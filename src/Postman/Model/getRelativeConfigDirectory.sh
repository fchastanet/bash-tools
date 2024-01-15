#!/bin/bash

# @description config directory path relative to current execution directory
# @arg $1 configFile:String the config file
# @stdout the parent directory of config file relative to current execution directory
# @example
#   executionPath=/home/wsl/bash-tools
#   configPath=/home/wsl/bash-tools/conf/postmanCli/openApis.json
#   result=conf/postmanCli
Postman::Model::getRelativeConfigDirectory() {
  local configFile="$1"
  local configDir
  configDir="$(cd -- "$(dirname -- "${configFile}")" &>/dev/null && pwd -P)"
  File::relativeToDir "${configDir}" "$(pwd -P)"
}
