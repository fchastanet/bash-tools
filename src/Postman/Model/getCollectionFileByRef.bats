#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"
# shellcheck source=src/Postman/Model/getCollectionFileByRef.sh
source "${rootDir}/src/Postman/Model/getCollectionFileByRef.sh"

function Postman::Model::getCollectionFileByRef::githubBasic { #@test
  Postman::Model::getRelativeConfigDirectory() {
    echo "dir"
  }
  run Postman::Model::getCollectionFileByRef \
    "${BATS_TEST_DIRNAME}/testsData/getCollectionRefs.json" \
    githubBasic
  assert_output "dir/GithubAPI/githubBasic.json"
  assert_success
}

function Postman::Model::getCollectionFileByRef::unknownRef { #@test
  Postman::Model::getRelativeConfigDirectory() {
    echo "Postman::Model::getRelativeConfigDirectory shouldn't have been called"
    return 1
  }
  run Postman::Model::getCollectionFileByRef \
    "${BATS_TEST_DIRNAME}/testsData/getCollectionRefs.json" \
    unknownRef
  assert_output ""
  assert_failure 1
}
