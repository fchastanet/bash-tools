#!/bin/bash

# @description push collections specified by modelFile
# @arg $1 modelFile:String model file containing the collections to be pushed
# @arg $@ list of collection references to push (all if not provided)
# @stderr diagnostic logs
# @exitcode 2 if no refs specified
# @exitcode * if one of sub commands fails
Postman::Commands::pushCollections() {
  local modelFile="$1"
  shift || true

  # shellcheck disable=SC2317
  pushCollectionsCallback() {
    local modelFile="$1"
    # local postmanCollectionsFile="$2"
    local collectionRef="$3"
    local collectionFile="$4"
    #local collectionName="$5"
    local postmanCollectionId="$6"
    local postmanCollectionIdStatus="$7"
    case "${postmanCollectionIdStatus}" in
      0) ;;          # success, next statement will update the collection
      2) ;;          # name not found, next statement will create the collection
      3) return 2 ;; # more than one collection
      *) return 1 ;; # error parsing collection file from postman, stop
    esac

    if [[ -z "${postmanCollectionId}" ]]; then
      Log::displayInfo "Creating collection '${collectionRef}'"
      Postman::api createCollectionFromFile "${collectionFile}"
      Log::displaySuccess "collection '${collectionRef}' has been created successfully"
    else
      Log::displayInfo "Updating collection '${collectionRef}' with id '${postmanCollectionId}'"
      Postman::api updateCollectionFromFile "${collectionFile}" "${postmanCollectionId}"
      Log::displaySuccess "collection '${collectionRef}' has been updated successfully"
    fi
  }

  Postman::Commands::forEachCollection "${modelFile}" pushCollectionsCallback "$@"
}
