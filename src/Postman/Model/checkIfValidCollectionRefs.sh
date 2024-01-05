#!/bin/bash

# @description check that each collection references passed as parameter
#   exists in the model file
# @arg $1 modelFile:String model file in which availableRefs have been retrieved
# @arg $2 availableRefs:&String[] list of known collection references
# @arg $3 modelCollectionRefs:&String[] list ofcollection references to check
Postman::Model::checkIfValidCollectionRefs() {
  local modelFile="$1"
  local -n availableRefs=$2
  shift 2 || true
  local -a modelCollectionRefs=("$@")

  # shellcheck disable=SC2154
  Log::displayDebug "Checking collection refs using config ${modelFile}"

  local ref
  for ref in "${modelCollectionRefs[@]}"; do
    if ! Array::contains "${ref}" "${availableRefs[@]}"; then
      Log::displayError "Collection ref '${ref}' is not known in '${modelFile}'"
      return 1
    fi
  done
}
