#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"
# shellcheck source=src/Postman/Commands/forEachCollection.sh
source "${rootDir}/src/Postman/Commands/forEachCollection.sh"

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"
  export HOME="${BATS_TEST_TMPDIR}/home"
  export BASH_FRAMEWORK_DISPLAY_LEVEL="${__LEVEL_DEBUG}"
}

teardown() {
  unstub_all
}

function Postman::Commands::forEachCollection::noRefsSpecified { #@test
  callback() {
    echo "$@"
  }
  run Postman::Commands::forEachCollection modelFile callback 2>&1
  assert_failure 2
  assert_output ""
}

function Postman::Commands::forEachCollection::collectionRefNotExisting { #@test
  callback() {
    echo "$@"
  }
  Postman::checkApiKey() {
    echo "$@" >"${BATS_TEST_TMPDIR}/checkApiKey"
  }
  Postman::api() {
    case "$1" in
      getCollections)
        echo "collection"
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
  Postman::Collection::getCollectionIdByName() {
    (
      echo "$1"
      echo "${@:2}"
    ) >"${BATS_TEST_TMPDIR}/getCollectionIdByName"
    echo postmanCollectionId
  }
  run Postman::Commands::forEachCollection modelFile callback ref1 2>&1
  assert_lines_count 5
  assert_line --index 0 --partial "DEBUG   - Retrieving collections from postman in /tmp"
  assert_line --index 1 "DEBUG   - Retrieving collection file from collection reference ref1"
  assert_line --index 2 "DEBUG   - Retrieving collection name from collection file collectionFile"
  assert_line --index 3 --regexp "DEBUG   - Deducing postman collection id using /tmp/[^ ]+ and collection name 'collectionName"
  assert_line --index 4 --regexp "modelFile /tmp/[^ ]+ ref1 collectionFile collectionName postmanCollectionId 0"
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

function Postman::Commands::forEachCollection::collectionRefIsPulled { #@test
  callback() {
    echo "$@"
  }
  Postman::checkApiKey() {
    echo "$@" >"${BATS_TEST_TMPDIR}/checkApiKey"
  }
  Postman::api() {
    case "$1" in
      getCollections)
        echo "collection"
        ;;
      *)
        echo "error"
        ;;
    esac
  }
  Postman::Model::getCollectionFileByRef() {
    echo "$@" >"${BATS_TEST_TMPDIR}/getCollectionFileByRef"
    echo "${BATS_TEST_TMPDIR}/collectionFile"
  }
  Postman::Collection::getName() {
    echo "$@" >"${BATS_TEST_TMPDIR}/getName"
    echo "collectionName"
  }
  Postman::Collection::getCollectionIdByName() {
    (
      echo "$1"
      echo "${@:2}"
    ) >"${BATS_TEST_TMPDIR}/getCollectionIdByName"
    echo "collectionId"
  }

  run Postman::Commands::forEachCollection modelFile callback ref1 2>&1
  assert_lines_count 5
  assert_line --index 0 --partial "DEBUG   - Retrieving collections from postman in /tmp"
  assert_line --index 1 "DEBUG   - Retrieving collection file from collection reference ref1"
  assert_line --index 2 --partial "DEBUG   - Retrieving collection name from collection file /tmp"
  assert_line --index 3 --regexp "DEBUG   - Deducing postman collection id using /tmp/[^ ]+ and collection name 'collectionName"
  assert_line --index 4 --regexp "modelFile /tmp/[^ ]+ ref1 /tmp/.+/collectionFile collectionName collectionId 0"
  assert_success
  run cat "${BATS_TEST_TMPDIR}/checkApiKey"
  assert_output "${HOME}/.bash-tools/.env"
  run cat "${BATS_TEST_TMPDIR}/getCollectionFileByRef"
  assert_output "modelFile ref1"
  run cat "${BATS_TEST_TMPDIR}/getName"
  assert_output "${BATS_TEST_TMPDIR}/collectionFile"
  run cat "${BATS_TEST_TMPDIR}/getCollectionIdByName"
  assert_lines_count 2
  assert_line --index 0 --regexp "^/tmp/"
  assert_line --index 1 "collectionName"
}

function Postman::Commands::forEachCollection::errorOnFirstRef { #@test
  callback() {
    echo "$@"
    return 1
  }
  Postman::checkApiKey() {
    echo "$@" >"${BATS_TEST_TMPDIR}/checkApiKey"
  }
  Postman::api() {
    case "$1" in
      getCollections)
        echo "collection1"
        echo "collection2"
        ;;
      *)
        echo "error"
        ;;
    esac
  }
  Postman::Model::getCollectionFileByRef() {
    echo "$@" >"${BATS_TEST_TMPDIR}/getCollectionFileByRef"
    echo "${BATS_TEST_TMPDIR}/collectionFile"
  }
  Postman::Collection::getName() {
    echo "$@" >"${BATS_TEST_TMPDIR}/getName"
    echo "collectionName"
  }
  Postman::Collection::getCollectionIdByName() {
    (
      echo "$1"
      echo "${@:2}"
    ) >"${BATS_TEST_TMPDIR}/getCollectionIdByName"
    echo "collectionId"
  }

  run Postman::Commands::forEachCollection modelFile callback ref1 2>&1
  assert_lines_count 5
  assert_line --index 0 --partial "DEBUG   - Retrieving collections from postman in /tmp"
  assert_line --index 1 "DEBUG   - Retrieving collection file from collection reference ref1"
  assert_line --index 2 --partial "DEBUG   - Retrieving collection name from collection file /tmp"
  assert_line --index 3 --regexp "DEBUG   - Deducing postman collection id using /tmp/[^ ]+ and collection name 'collectionName"
  assert_line --index 4 --regexp "modelFile /tmp/[^ ]+ ref1 /tmp/.+/collectionFile collectionName collectionId 0"
  assert_failure 1
  run cat "${BATS_TEST_TMPDIR}/checkApiKey"
  assert_output "${HOME}/.bash-tools/.env"
  run cat "${BATS_TEST_TMPDIR}/getCollectionFileByRef"
  assert_output "modelFile ref1"
  run cat "${BATS_TEST_TMPDIR}/getName"
  assert_output "${BATS_TEST_TMPDIR}/collectionFile"
  run cat "${BATS_TEST_TMPDIR}/getCollectionIdByName"
  assert_lines_count 2
  assert_line --index 0 --regexp "^/tmp/"
  assert_line --index 1 "collectionName"
}
