#!/bin/bash

# @description retrieve the file associated to the collection ref
# @arg $1 configFile:String the config file to parse
# @arg $2 ref:String the collection reference to get
# @stdout the file relative to current execution directory
# @exitcode 1 - if jq parsing error, file not found or any other error
Postman::Model::getCollectionFileByRef() {
  local configFile="$1"
  local ref="$2"
  local file
  file="$(jq -cre ".collections.${ref}.file" <"${configFile}")" || return 1
  echo "$(Postman::Model::getRelativeConfigDirectory "${configFile}")/${file}"
}
