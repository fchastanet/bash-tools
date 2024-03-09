#!/bin/bash

# @description pull collections specified by modelFile in write merge mode
# @arg $1 modelFile:String model file containing the collections to be pulled
# @arg $@ list of collection references to pull (all if not provided)
# @stderr diagnostic logs
# @exitcode 2 if no refs specified
# @exitcode * if one of sub commands fails
Postman::Commands::pullCollectionsMerge() {
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
  postmanCollectionId="$(Postman::Collection::getCollectionIdByName \
    "${postmanCollectionsFile}" "${modelName}")" || postmanCollectionIdStatus="$?"

  case "${postmanCollectionIdStatus}" in
    0) ;; # success, next statement will pull the collection
    2)
      Log::displayError "Cannot find collection with name '${modelName}'"
      return 2
      ;;
    3)
      Log::displayError "More than one collection with name '${modelName}'"
      return 2
      ;;
    *)
      Log::displayError "Error parsing collections file from postman"
      return 1
      ;;
  esac

  Log::displayInfo "Pulling collection ${modelName} with id ${postmanCollectionId} from postman"
  local statusCode=0
  local response
  response="$(Postman::api pullCollection "${postmanCollectionId}" | jq -cre '.collection')" || statusCode=$?
  if [[ "${statusCode}" != "0" ]]; then
    Log::displayError "Collection '${modelName}' an error occurred pulling the collection from postman"
    return 1
  fi

  local ref
  for ref in "${refs[@]}"; do
    local collectionFile postmanCollectionId
    Log::displayDebug "Retrieving collection file from collection reference ${ref}"
    collectionFile="$(Postman::Model::getCollectionFileByRef "${modelFile}" "${ref}")"

    # TODO push before
    # TODO retrieve sub collection in response based on ref

  done
}
