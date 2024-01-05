#!/bin/bash

# @description get the list of collection references id from given config file
# @arg $1 configFile:String the config file to parse
# @arg $2 getCollectionRefs:&String[] (passed by reference) list of collection
#   references
# @exitcode 1 - if jq parsing error, file not found or any other error
# @stderr jq error messages on failure
Postman::Model::getCollectionRefs() {
  local configFile="$1"
  local -n getCollectionRefs=$2
  # shellcheck disable=SC2034
  jq -cre '.collections | try keys[]' <"${configFile}" | readarray -t getCollectionRefs
}
