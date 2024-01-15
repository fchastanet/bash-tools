#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"
# shellcheck source=src/Postman/Model/getCollectionRefs.sh
source "${rootDir}/src/Postman/Model/getCollectionRefs.sh"

function Postman::Model::getCollectionRefs::get { #@test
  local -a result
  local status=0
  Postman::Model::getCollectionRefs \
    "${BATS_TEST_DIRNAME}/testsData/getCollectionRefs.json" \
    result || status=$?
  [[ "${result[*]}" = "githubAdvanced githubBasic microsoftGraph" ]]
  [[ "${status}" = "0" ]]
}

function Postman::Model::getCollectionRefs::error { #@test
  local -a result
  local status=0
  Postman::Model::getCollectionRefs \
    "${BATS_TEST_DIRNAME}/testsData/getCollectionError.json" \
    result || status=$?
  [[ "${result[*]}" = "" ]]
  [[ "${status}" = "4" ]]
}
