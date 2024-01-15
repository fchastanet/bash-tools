#!/bin/bash

# @description retrieve the name of the model json file
# @arg $1 modelFile:String
# @exitcode 1 if error while parsing model file
# @exitcode * jq exit code, 4 for invalid file
# @stdout model property name of model json file
Postman::Model::getName() {
  local modelFile="$1"
  local output
  output="$(jq -cre .name <"${modelFile}")" || return 1
  echo "${output}"
}
