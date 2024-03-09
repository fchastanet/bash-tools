#!/bin/bash

# @description push collections specified by modelFile in write merge mode
# @arg $1 modelFile:String model file containing the collections to be pushed
# @arg $@ list of collection references to push (all if not provided)
# @stderr diagnostic logs
# @exitcode 2 if no refs specified
# @exitcode * if one of sub commands fails
Postman::Commands::pushCollectionsMerge() {
  local modelFile="$1"
  shift || true
  local -a refs=("$@")

  if ((${#refs[@]} == 0)); then
    return 2
  fi
  Postman::checkApiKey "${HOME}/.bash-tools/.env" || return 1

  local postmanCollectionsFile
  postmanCollectionsFile="$(Framework::createTempFile "postmanCollections")"

  # shellcheck disable=SC2154
  Log::displayDebug "Retrieving collections from postman in ${postmanCollectionsFile}"
  Postman::api getCollections >"${postmanCollectionsFile}" || return 1

  local modelName
  modelName="$(Postman::Model::getName "${modelFile}")"
  Log::displayDebug "Deducing postman collection id using ${postmanCollectionsFile} and model name '${modelName}'"

  local postmanCollectionId
  local postmanCollectionIdStatus
  # shellcheck disable=SC2034 # TODO remove when dev OK
  postmanCollectionId="$(Postman::Collection::getCollectionIdByName \
    "${postmanCollectionsFile}" "${modelName}")" || postmanCollectionIdStatus="$?"

  case "${postmanCollectionIdStatus}" in
    0) ;; # success, next statement will pull the collection
    2) ;; # collection not found, we will have to create it
    3)
      Log::displayError "More than one collection with name '${modelName}'"
      return 2
      ;;
    *)
      Log::displayError "Error parsing collections file from postman"
      return 1
      ;;
  esac

  local ref
  for ref in "${refs[@]}"; do
    local collectionFile
    Log::displayDebug "Retrieving collection file from collection reference ${ref}"
    # shellcheck disable=SC2034 # TODO remove when dev OK
    collectionFile="$(Postman::Model::getCollectionFileByRef "${modelFile}" "${ref}")"

    # TODO push before
    # TODO retrieve sub collection in response based on ref

  done
}
