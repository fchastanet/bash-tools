#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"
# shellcheck source=src/Postman/Collection/getName.sh
source "${rootDir}/src/Postman/Collection/getName.sh"

function Postman::Collection::getName::simple { #@test
  run Postman::Collection::getName \
    "${BATS_TEST_DIRNAME}/testsData/githubBasic_collection.json"
  assert_output "GitHub API - 1. Basic (no Auth)"
  assert_lines_count 1
  assert_success
}

function Postman::Collection::getName::invalidJsonFile { #@test
  run Postman::Collection::getName \
    "${BATS_TEST_DIRNAME}/testsData/postmanCollections_invalidJsonFile.json" 2>&1
  assert_lines_count 2
  assert_line --index 0 'jq: error (at <stdin>:2): Cannot index string with string "info"'
  assert_line --index 1 "parse error: Expected string key before ':' at line 2, column 16"
  assert_failure 4
}

function Postman::Collection::getName::invalidFile { #@test
  run Postman::Collection::getName \
    "${BATS_TEST_DIRNAME}/testsData/postmanCollections_invalidFile.json"
  assert_output "null"
  assert_failure 1
}
