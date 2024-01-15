#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"
# shellcheck source=src/Postman/Model/getName.sh
source "${rootDir}/src/Postman/Model/getName.sh"

function Postman::Model::getName::simple { #@test
  run Postman::Model::getName \
    "${BATS_TEST_DIRNAME}/testsData/getCollectionRefs.json"
  assert_output "Open Apis"
  assert_success
}

function Postman::Model::getName::error { #@test
  run Postman::Model::getName \
    "${BATS_TEST_DIRNAME}/testsData/getCollectionError.json"
  assert_output ""
  assert_failure 1
}
