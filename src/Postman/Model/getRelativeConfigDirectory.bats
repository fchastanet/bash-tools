#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"
# shellcheck source=vendor/bash-tools-framework/src/File/relativeToDir.sh
source "${FRAMEWORK_ROOT_DIR}/src/File/relativeToDir.sh"
# shellcheck source=src/Postman/Model/getRelativeConfigDirectory.sh
source "${rootDir}/src/Postman/Model/getRelativeConfigDirectory.sh"

function Postman::Model::getRelativeConfigDirectory::githubBasic { #@test
  run Postman::Model::getRelativeConfigDirectory \
    "${BATS_TEST_DIRNAME}/testsData/getCollectionRefs.json"
  assert_output "src/Postman/Model/testsData"
  assert_success
}
