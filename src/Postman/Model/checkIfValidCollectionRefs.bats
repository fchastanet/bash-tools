#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"
# shellcheck source=vendor/bash-tools-framework/src/Array/contains.sh
source "${FRAMEWORK_ROOT_DIR}/src/Array/contains.sh"
# shellcheck source=src/Postman/Model/checkIfValidCollectionRefs.sh
source "${rootDir}/src/Postman/Model/checkIfValidCollectionRefs.sh"

setup() {
  export BASH_FRAMEWORK_THEME="noColor"
}

function Postman::Model::checkIfValidCollectionRefs::noArgs { #@test
  local -a myRefs=(ref1 ref2)
  run Postman::Model::checkIfValidCollectionRefs \
    "${BATS_TEST_DIRNAME}/testsData/getCollectionRefs.json" \
    myRefs
  assert_output ""
  assert_success
}

function Postman::Model::checkIfValidCollectionRefs::firstRefInvalid { #@test
  local -a myRefs=(ref1 ref2)
  run Postman::Model::checkIfValidCollectionRefs \
    "${BATS_TEST_DIRNAME}/testsData/getCollectionRefs.json" \
    myRefs invalidRef ref2
  assert_output "ERROR   - Collection ref 'invalidRef' is not known in '${BATS_TEST_DIRNAME}/testsData/getCollectionRefs.json'"
  assert_lines_count 1
  assert_failure 1
}

function Postman::Model::checkIfValidCollectionRefs::secondRefInvalid { #@test
  local -a myRefs=(ref1 ref2)
  run Postman::Model::checkIfValidCollectionRefs \
    "${BATS_TEST_DIRNAME}/testsData/getCollectionRefs.json" \
    myRefs ref1 invalidRef
  assert_output "ERROR   - Collection ref 'invalidRef' is not known in '${BATS_TEST_DIRNAME}/testsData/getCollectionRefs.json'"
  assert_lines_count 1
  assert_failure 1
}
