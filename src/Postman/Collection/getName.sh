#!/bin/bash

# @description retrieve the name of the collection file
# from the postman collection file
# @arg $1 collectionFile:String
# @exitcode 1 if error while parsing the collection file
# @exitcode * jq exit code, 4 for invalid file
# @stdout the collection name of the collection file
Postman::Collection::getName() {
  local collectionFile="$1"
  jq -cre '.info.name' <"${collectionFile}"
}
