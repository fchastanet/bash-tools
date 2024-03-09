#!/bin/bash

# @description pull collections specified by modelFile in write mode single file
# @arg $1 modelFile:String model file containing the collections to be pulled
# @arg $@ list of collection references to pull (all if not provided)
# @stderr diagnostic logs
# @exitcode 2 if no refs specified
# @exitcode * if one of sub commands fails
Postman::Commands::pullCollectionsSingle() {
  local modelFile="$1"
  shift || true

  # shellcheck disable=SC2317
  pullCollectionsSingleCallback() {
    local modelFile="$1"
    # local postmanCollectionsFile="$2"
    local collectionRef="$3"
    local collectionFile="$4"
    local collectionName="$5"
    local postmanCollectionId="$6"
    local postmanCollectionIdStatus="$7"
    case "${postmanCollectionIdStatus}" in
      0) ;;          # success, next statement will pull the collection
      2) return 2 ;; # name not found
      3) return 2 ;; # more than one collection
      *) return 1 ;; # error parsing collection file from postman, stop
    esac
    if [[ -z "${postmanCollectionId}" ]]; then
      Log::displayWarning "Collection '${collectionRef}' - pull skipped as not existing in your postman workspace"
    else
      local response
      local statusCode="0"
      Log::displayInfo "Pulling collection ${collectionRef} with id ${postmanCollectionId} from postman"
      response="$(Postman::api pullCollection "${postmanCollectionId}" | jq -cre '.collection')" || statusCode=$?
      if [[ "${statusCode}" = "0" ]]; then
        echo "${response}" >"${collectionFile}"
        Log::displaySuccess "Collection '${collectionName}' has been pulled successfully to '${collectionFile}'"
      else
        Log::displayError "Collection '${collectionName}' an error occurred pulling the collection from postman"
      fi
    fi
  }
  Postman::Commands::forEachCollection "${modelFile}" pullCollectionsSingleCallback "$@"
}
