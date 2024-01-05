#!/bin/bash

# @description call postman REST api
# @arg $1 action:String action to call
# @arg $@ args:String[] rest of arguments
# @exitcode 1 if invalid action
# @exitcode * curl error
# @env BASH_FRAMEWORK_ARGS_VERBOSE display curl response if verbose level is different than 0
Postman::api() {
  local action="$1"
  shift || true

  getCollections() {
    curl \
      -X GET https://api.getpostman.com/collections \
      --fail --silent --show-error \
      -H "X-Api-Key: ${POSTMAN_API_KEY}"
  }

  getCollectionDataFromFile() {
    local collectionFile="$1"
    jq -cre -n \
      --slurpfile collection "${collectionFile}" \
      '{"collection": $collection[0]}'
  }

  createCollectionFromFile() {
    local collectionFile="$1"
    local responseFile
    responseFile="$(Framework::createTempFile)"

    local status=0
    getCollectionDataFromFile "${collectionFile}" |
      curl \
        --request POST https://api.getpostman.com/collections \
        -o "${responseFile}" \
        --header 'Content-Type: application/json' \
        --header 'Accept: application/json' \
        --header "X-Api-Key: ${POSTMAN_API_KEY}" \
        --data @- \
        --fail --silent --show-error || status=$?

    Postman::displayResponse "createCollectionFromFile" "${responseFile}"

    return "${status}"
  }

  updateCollectionFromFile() {
    local collectionFile="$1"
    local collectionId="$2"
    local responseFile
    responseFile="$(Framework::createTempFile)"

    local status=0
    getCollectionDataFromFile "${collectionFile}" |
      curl \
        --request PUT "https://api.getpostman.com/collections/${collectionId}" \
        -o "${responseFile}" \
        --header 'Content-Type: application/json' \
        --header 'Accept: application/json' \
        --header "X-Api-Key: ${POSTMAN_API_KEY}" \
        --data @- \
        --fail --silent --show-error || status=$?

    Postman::displayResponse "updateCollectionFromFile" "${responseFile}"

    return "${status}"
  }

  pullCollection() {
    local collectionId="$1"
    curl \
      -X GET "https://api.getpostman.com/collections/${collectionId}" \
      --fail --silent --show-error \
      -H "X-Api-Key: ${POSTMAN_API_KEY}"
  }

  case "${action}" in
    getCollections)
      getCollections "$@"
      ;;
    createCollectionFromFile)
      createCollectionFromFile "$@"
      ;;
    updateCollectionFromFile)
      updateCollectionFromFile "$@"
      ;;
    pullCollection)
      pullCollection "$@"
      ;;
    *)
      Log::displayError "Unknown api action '${action}'"
      return 1
      ;;
  esac
}
