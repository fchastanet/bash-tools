#!/bin/bash

# @description retrieve the write mode of the model json file
# @arg $1 modelFile:String
# @exitcode 1 if error while parsing model file
# @exitcode * jq exit code, 4 for invalid file
# @stdout model property writeMode of model json file (default to single if property not set)
Postman::Model::getWriteMode() {
  local modelFile="$1"
  jq -cre '.writeMode // "single"' 2>/dev/null <"${modelFile}" || echo "single"
}
