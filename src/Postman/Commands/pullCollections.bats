#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"
# shellcheck source=src/Postman/Commands/forEachCollection.sh
source "${rootDir}/src/Postman/Commands/forEachCollection.sh"
# shellcheck source=src/Postman/Commands/pullCollections.sh
source "${rootDir}/src/Postman/Commands/pullCollections.sh"

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"
  export HOME="${BATS_TEST_TMPDIR}/home"
  export BASH_FRAMEWORK_DISPLAY_LEVEL="${__LEVEL_DEBUG}"
}

teardown() {
  unstub_all
}

function Postman::Commands::pullCollections::noRefsSpecified { #@test
  run Postman::Commands::pullCollections modelFile 2>&1
  assert_failure 2
  assert_output ""
}

function Postman::Commands::pullCollections::collectionRefNotExisting { #@test
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
  }
  run Postman::Commands::pullCollections modelFile ref1 2>&1
  assert_lines_count 5
  assert_line --index 0 --partial "DEBUG   - Retrieving collections from postman in /tmp"
  assert_line --index 1 "DEBUG   - Retrieving collection file from collection reference ref1"
  assert_line --index 2 "DEBUG   - Retrieving collection name from collection file collectionFile"
  assert_line --index 3 --regexp "DEBUG   - Deducing postman collection id using /tmp/[^ ]+ and collection name 'collectionName"
  assert_line --index 4 "WARN    - Collection 'ref1' - pull skipped as not existing in your postman workspace"
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

function Postman::Commands::pullCollections::collectionRefIsPulled { #@test
  Postman::checkApiKey() {
    echo "$@" >"${BATS_TEST_TMPDIR}/checkApiKey"
  }
  Postman::api() {
    case "$1" in
      getCollections)
        echo "collection"
        ;;
      pullCollection)
        echo "collection pulled"
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
  stub jq \
    '-cre .collection : echo "collection exported from postman"'

  run Postman::Commands::pullCollections modelFile ref1 2>&1
  assert_lines_count 6
  assert_line --index 0 --partial "DEBUG   - Retrieving collections from postman in /tmp"
  assert_line --index 1 "DEBUG   - Retrieving collection file from collection reference ref1"
  assert_line --index 2 --partial "DEBUG   - Retrieving collection name from collection file /tmp"
  assert_line --index 3 --regexp "DEBUG   - Deducing postman collection id using /tmp/[^ ]+ and collection name 'collectionName"
  assert_line --index 4 "INFO    - Pulling collection ref1 with id collectionId from postman"
  assert_line --index 5 --regexp "SUCCESS - Collection 'collectionName' has been pulled successfully to '/tmp/[^']+'"
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
  run cat "${BATS_TEST_TMPDIR}/collectionFile"
  assert_output "collection exported from postman"
}
