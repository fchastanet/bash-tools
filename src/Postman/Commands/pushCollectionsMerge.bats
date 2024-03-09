#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"
# shellcheck source=src/Postman/Commands/forEachCollection.sh
source "${rootDir}/src/Postman/Commands/forEachCollection.sh"
# shellcheck source=src/Postman/Commands/pushCollectionsMerge.sh
source "${rootDir}/src/Postman/Commands/pushCollectionsMerge.sh"

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"
  export HOME="${BATS_TEST_TMPDIR}/home"
  export BASH_FRAMEWORK_DISPLAY_LEVEL="${__LEVEL_DEBUG}"
}

teardown() {
  unstub_all
}

function Postman::Commands::pushCollectionsMerge::noRefsSpecified { #@test
  run Postman::Commands::pushCollectionsMerge modelFile 2>&1
  assert_failure 2
  assert_output ""
}

function Postman::Commands::pushCollectionsMerge::collectionRefCreate { #@test
  skip "Merge mode not finalized"
  Postman::checkApiKey() {
    echo "$@" >"${BATS_TEST_TMPDIR}/checkApiKey"
  }
  Postman::api() {
    case "$1" in
      getCollections)
        echo "collection"
        ;;
      createCollectionFromFile)
        echo "createCollectionFromFile"
        ;;
      *)
        echo "error"
        ;;
    esac
  }
  Postman::Model::getCollectionFileByRef() {
    echo "$@" >"${BATS_TEST_TMPDIR}/getCollectionFileByRef"
    echo "collectionFile"
  }
  Postman::Collection::getName() {
    echo "$@" >"${BATS_TEST_TMPDIR}/getName"
    echo "collectionName"
  }
  Postman::Model::getName() {
    echo "PostmanCliExample"
  }
  Postman::Collection::getCollectionIdByName() {
    (
      echo "$1"
      echo "${@:2}"
    ) >"${BATS_TEST_TMPDIR}/getCollectionIdByName"
  }
  run Postman::Commands::pushCollectionsMerge modelFile ref1 2>&1
  assert_output ""
  assert_line --index 0 --partial "DEBUG   - Retrieving collections from postman in /tmp"
  assert_line --index 1 "DEBUG   - Retrieving collection file from collection reference ref1"
  assert_line --index 2 "DEBUG   - Retrieving collection name from collection file collectionFile"
  assert_line --index 3 --regexp "DEBUG   - Deducing postman collection id using /tmp/[^ ]+ and collection name 'collectionName"
  assert_line --index 4 "INFO    - Creating collection 'ref1'"
  assert_line --index 5 "createCollectionFromFile"
  assert_line --index 6 "SUCCESS - collection 'ref1' has been created successfully"
  assert_lines_count 7
  assert_success
}

function Postman::Commands::pushCollectionsMerge::collectionRefUpdate { #@test
  skip "Merge mode not finalized"
  Postman::checkApiKey() {
    echo "$@" >"${BATS_TEST_TMPDIR}/checkApiKey"
  }
  Postman::api() {
    case "$1" in
      getCollections)
        echo "collection"
        ;;
      updateCollectionFromFile)
        echo "updateCollectionFromFile"
        ;;
      *)
        echo "error"
        ;;
    esac
  }
  Postman::Model::getCollectionFileByRef() {
    echo "$@" >"${BATS_TEST_TMPDIR}/getCollectionFileByRef"
    echo "collectionFile"
  }
  Postman::Collection::getName() {
    echo "$@" >"${BATS_TEST_TMPDIR}/getName"
    echo "collectionName"
  }
  Postman::Model::getName() {
    echo "PostmanCliExample"
  }
  Postman::Collection::getCollectionIdByName() {
    (
      echo "$1"
      echo "${@:2}"
    ) >"${BATS_TEST_TMPDIR}/getCollectionIdByName"
    echo "collectionId"
  }

  run Postman::Commands::pushCollectionsMerge modelFile ref1 2>&1
  assert_output ""
  assert_line --index 0 --partial "DEBUG   - Retrieving collections from postman in /tmp"
  assert_line --index 1 "DEBUG   - Retrieving collection file from collection reference ref1"
  assert_line --index 2 "DEBUG   - Retrieving collection name from collection file collectionFile"
  assert_line --index 3 --regexp "DEBUG   - Deducing postman collection id using /tmp/[^ ]+ and collection name 'collectionName"
  assert_line --index 4 "INFO    - Updating collection 'ref1' with id 'collectionId'"
  assert_line --index 5 "updateCollectionFromFile"
  assert_line --index 6 "SUCCESS - collection 'ref1' has been updated successfully"
  assert_lines_count 7
  assert_success
  run cat "${BATS_TEST_TMPDIR}/checkApiKey"
  assert_output "${HOME}/.bash-tools/.env"
  run cat "${BATS_TEST_TMPDIR}/getCollectionFileByRef"
  assert_output "modelFile ref1"
  run cat "${BATS_TEST_TMPDIR}/getName"
  assert_output "collectionFile"
  run cat "${BATS_TEST_TMPDIR}/getCollectionIdByName"
  assert_lines_count 2
  assert_line --index 0 --regexp "^/tmp/"
  assert_line --index 1 "collectionName"
}
