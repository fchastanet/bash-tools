#!/bin/bash

# @description apply callback on each collection specified by modelFile
# #### callback arguments
#    - modelFile
#    - postmanCollectionsFile
#    - collectionRef
#    - collectionFile
#    - collectionName
#    - postmanCollectionId
#    - postmanCollectionIdStatus
# @arg $1 modelFile:String model file containing the collections to be processed
# @arg $2 callback:Function callback to apply on each collection selected
# @arg $@ list of collection references to process (all if not provided)
# @stderr diagnostic logs
# @exitcode 2 if no refs specified
# @exitcode * if one of sub commands fails
Postman::Commands::forEachCollection() {
  local modelFile="$1"
  local callback="$2"
  shift 2 || true
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

  local collectionRef
  for collectionRef in "${refs[@]}"; do
    local collectionFile collectionName postmanCollectionId
    Log::displayDebug "Retrieving collection file from collection reference ${collectionRef}"
    collectionFile="$(Postman::Model::getCollectionFileByRef "${modelFile}" "${collectionRef}")"
    Log::displayDebug "Retrieving collection name from collection file ${collectionFile}"
    collectionName="$(Postman::Collection::getName "${collectionFile}")"
    Log::displayDebug "Deducing postman collection id using ${postmanCollectionsFile} and collection name '${collectionName}'"
    local postmanCollectionIdStatus="0"
    postmanCollectionId="$(Postman::Collection::getCollectionIdByName \
      "${postmanCollectionsFile}" "${collectionName}")" || postmanCollectionIdStatus=$?
    local status=0
    "${callback}" \
      "${modelFile}" "${postmanCollectionsFile}" \
      "${collectionRef}" "${collectionFile}" "${collectionName}" \
      "${postmanCollectionId}" "${postmanCollectionIdStatus}" || status=$?
    case "${status}" in
      2 | 0) continue ;;
      *) return 1 ;;
    esac
  done
}
