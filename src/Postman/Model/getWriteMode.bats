#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"
# shellcheck source=src/Postman/Model/getWriteMode.sh
source "${rootDir}/src/Postman/Model/getWriteMode.sh"

function Postman::Model::getWriteMode::single { #@test
  run Postman::Model::getWriteMode \
    "${BATS_TEST_DIRNAME}/testsData/getCollectionRefs.json"
  assert_output "single"
  assert_success
}

function Postman::Model::getWriteMode::error { #@test
  run Postman::Model::getWriteMode \
    "${BATS_TEST_DIRNAME}/testsData/getCollectionError.json"
  assert_output "single"
  assert_success
}

function Postman::Model::getWriteMode::merge { #@test
  run Postman::Model::getWriteMode \
    "${BATS_TEST_DIRNAME}/testsData/getCollectionMerge.json"
  assert_output "merge"
  assert_success
}
