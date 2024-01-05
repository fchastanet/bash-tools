#!/bin/bash

# @description retrieve the collection id
# associated to the given collection name
# from the postman collection file
# @arg $1 collectionFile:String
# @arg $2 collectionName:String
# @exitcode 1 if error while parsing the collection file
# @exitcode 2 if name not found
# @exitcode 3 if more than one collection matches that name
# @stderr details, on failure
# @stdout the collection id associated to a unique collection name
Postman::Collection::getCollectionIdByName() {
  local collectionFile="$1"
  local collectionName="$2"
  local result
  local errorCode="0"
  result="$(
    jq -cre --arg name "${collectionName}" \
      '.collections[] | select( .name == $name) | .id' 2>&1 <"${collectionFile}"
  )" || errorCode="$?"
  if [[ "${errorCode}" = "4" ]]; then
    Log::displayWarning "collection name '${collectionName}' not found in '${collectionFile}'"
    return 2
  elif [[ "${errorCode}" != "0" ]]; then
    Log::displayError "Error while parsing '${collectionFile}' - error code ${errorCode} - ${result}"
    return 1
  fi
  if (($(wc -l <<<"${result}") > 1)); then
    Log::displayError "More than one collection match the collection name '${collectionName}', please clean up your postman workspace"
    return 3
  fi
  echo "${result}"
}
