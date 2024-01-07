#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/.." && pwd)/batsHeaders.sh"
# shellcheck source=src/Postman/api.sh
source "${rootDir}/src/Postman/api.sh"
# shellcheck source=vendor/bash-tools-framework/src/Bash/handlePipelineFailure.sh
source "${FRAMEWORK_ROOT_DIR}/src/Bash/handlePipelineFailure.sh"

setup() {
  export BASH_FRAMEWORK_THEME="noColor"
  export POSTMAN_API_KEY='fake'
}

teardown() {
  unstub_all
}

function Postman::api::noAction { #@test
  run Postman::api
  assert_output "ERROR   - Unknown api action ''"
  assert_failure 1
}

function Postman::api::invalidAction { #@test
  run Postman::api invalidAction
  assert_output "ERROR   - Unknown api action 'invalidAction'"
  assert_failure 1
}

function Postman::api::getCollections { #@test
  stub curl \
    "-X GET https://api.getpostman.com/collections --fail --silent --show-error -H 'X-Api-Key: fake' : echo '{}'"
  run Postman::api getCollections
  assert_output "{}"
  assert_success
}

function Postman::api::createCollectionFromFile { #@test
  Postman::displayResponse() {
    cat "$2"
  }
  stub jq \
    '-cre -n --slurpfile collection collectionFilePath * : echo "{}"'
  stub curl \
    "--request POST https://api.getpostman.com/collections -o * --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'X-Api-Key: fake' --data @- --fail --silent --show-error : echo 'result OK'"
  run Postman::api createCollectionFromFile "collectionFilePath"
  assert_output "result OK"
  assert_success
}

function Postman::api::updateCollectionFromFile { #@test
  Postman::displayResponse() {
    cat "$2"
  }
  stub jq \
    '-cre -n --slurpfile collection collectionFilePath * : echo "{}"'
  stub curl \
    "--request PUT https://api.getpostman.com/collections/2 -o * --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'X-Api-Key: fake' --data @- --fail --silent --show-error : echo 'result OK'"
  run Postman::api updateCollectionFromFile "collectionFilePath" 2
  assert_output "result OK"
  assert_success
}

function Postman::api::pullCollection { #@test
  stub curl \
    "-X GET https://api.getpostman.com/collections/ --fail --silent --show-error -H 'X-Api-Key: fake' : echo '{}'"
  run Postman::api pullCollection
  assert_output "{}"
  assert_success
}
