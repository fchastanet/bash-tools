#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"
# shellcheck source=src/Postman/Collection/getCollectionIdByName.sh
source "${rootDir}/src/Postman/Collection/getCollectionIdByName.sh"

setup() {
  export BASH_FRAMEWORK_THEME="noColor"
}

function Postman::Collection::getCollectionIdByName::githubBasic { #@test
  run Postman::Collection::getCollectionIdByName \
    "${BATS_TEST_DIRNAME}/testsData/postmanCollections.json" \
    "GitHub API - 1. Basic (no Auth)"
  assert_output "b47cdd04-f4ea-4a96-8735-90efa20fee2d"
  assert_lines_count 1
  assert_success
}

function Postman::Collection::getCollectionIdByName::unknownName { #@test
  run Postman::Collection::getCollectionIdByName \
    "${BATS_TEST_DIRNAME}/testsData/postmanCollections.json" \
    "Unknown API"
  assert_output "WARN    - collection name 'Unknown API' not found in '${BATS_TEST_DIRNAME}/testsData/postmanCollections.json'"
  assert_lines_count 1
  assert_failure 2
}

function Postman::Collection::getCollectionIdByName::duplicatedName { #@test
  run Postman::Collection::getCollectionIdByName \
    "${BATS_TEST_DIRNAME}/testsData/postmanCollections.json" \
    "GitHub API - 2. Advanced (with Auth)"
  assert_output "ERROR   - More than one collection match the collection name 'GitHub API - 2. Advanced (with Auth)', please clean up your postman workspace"
  assert_lines_count 1
  assert_failure 3
}

function Postman::Collection::getCollectionIdByName::fileNotFound { #@test
  run Postman::Collection::getCollectionIdByName \
    "${BATS_TEST_DIRNAME}/testsData/fileNotFound.json" \
    "GitHub API - 1. Basic (no Auth)"
  assert_output --partial "ERROR   - Error while parsing '${BATS_TEST_DIRNAME}/testsData/fileNotFound.json' - error code 1"
  assert_lines_count 1
  assert_failure 1
}

function Postman::Collection::getCollectionIdByName::invalidCollectionsFile { #@test
  run Postman::Collection::getCollectionIdByName \
    "${BATS_TEST_DIRNAME}/testsData/postmanCollections_invalidFile.json" \
    "GitHub API - 1. Basic (no Auth)"
  assert_output --partial "ERROR   - Error while parsing '${BATS_TEST_DIRNAME}/testsData/postmanCollections_invalidFile.json' - error code 5 - jq: error (at <stdin>"
  assert_lines_count 1
  assert_failure 1
}
