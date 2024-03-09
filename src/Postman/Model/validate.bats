#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"
# shellcheck source=vendor/bash-tools-framework/src/Array/contains.sh
source "${FRAMEWORK_ROOT_DIR}/src/Array/contains.sh"
# shellcheck source=src/Postman/Model/validate.sh
source "${rootDir}/src/Postman/Model/validate.sh"

setup() {
  export BASH_FRAMEWORK_THEME="noColor"
}

teardown() {
  chmod -R u+w "${BATS_TEST_TMPDIR}/pullMode" 2>/dev/null || true
}

function Postman::Model::validate::missingMode { #@test
  run Postman::Model::validate \
    "fileNotFound.json" "invalidMode"
  assert_output "ERROR   - invalid mode invalidMode"
  assert_failure 1
  assert_lines_count 1
}

function Postman::Model::validate::invalidMode { #@test
  run Postman::Model::validate \
    "fileNotFound.json" "invalidMode"
  assert_output "ERROR   - invalid mode invalidMode"
  assert_failure 1
  assert_lines_count 1
}

function Postman::Model::validate::fileNotFound { #@test
  Postman::Model::getRelativeConfigDirectory() {
    echo "$1"
  }
  run Postman::Model::validate \
    "fileNotFound.json" "push"
  assert_output "ERROR   - File fileNotFound.json does not exist"
  assert_failure 1
  assert_lines_count 1
}

function Postman::Model::validate::fileInvalid { #@test
  Postman::Model::getRelativeConfigDirectory() {
    echo "$1"
  }
  run Postman::Model::validate \
    "${BATS_TEST_DIRNAME}/testsData/getCollectionInvalid.json" "push"
  assert_output "ERROR   - File '${BATS_TEST_DIRNAME}/testsData/getCollectionInvalid.json' is not a valid json file"
  assert_failure 1
  assert_lines_count 1
}

function Postman::Model::validate::missingName { #@test
  Postman::Model::getRelativeConfigDirectory() {
    echo "$1"
  }
  run Postman::Model::validate \
    "${BATS_TEST_DIRNAME}/testsData/getCollection-missingName.json" "push"
  assert_output "ERROR   - File '${BATS_TEST_DIRNAME}/testsData/getCollection-missingName.json' - missing name property"
  assert_failure 1
  assert_lines_count 1
}

function Postman::Model::validate::invalidWriteMode { #@test
  Postman::Model::getRelativeConfigDirectory() {
    echo "$1"
  }
  run Postman::Model::validate \
    "${BATS_TEST_DIRNAME}/testsData/getCollection-invalidWriteMode.json" "push"
  assert_output "ERROR   - File '${BATS_TEST_DIRNAME}/testsData/getCollection-invalidWriteMode.json' - writeMode 'invalid' is invalid"
  assert_failure 1
  assert_lines_count 1
}

function Postman::Model::validate::missingCollections { #@test
  Postman::Model::getRelativeConfigDirectory() {
    echo "$1"
  }
  run Postman::Model::validate \
    "${BATS_TEST_DIRNAME}/testsData/getCollection-missingCollections.json" "push"
  assert_output "ERROR   - File '${BATS_TEST_DIRNAME}/testsData/getCollection-missingCollections.json' - collections property is missing or is not an object"
  assert_failure 1
  assert_lines_count 1
}

function Postman::Model::validate::pushModeCollectionsWithErrors { #@test
  Postman::Model::getRelativeConfigDirectory() {
    echo "${BATS_TEST_DIRNAME}/testsData/pushMode"
  }
  local file="${BATS_TEST_DIRNAME}/testsData/pushMode/getCollectionRefs-collectionsWithErrors.json"
  run Postman::Model::validate \
    "${file}" "push"

  assert_failure 1
  assert_line --index 0 "ERROR   - File '${file}' - collection 0 - missing file property"
  assert_line --index 1 "ERROR   - File '${file}' - collection fileMissing - collection file ${BATS_TEST_DIRNAME}/testsData/pushMode/GithubAPI/missingFile.json does not exists"
  assert_line --index 2 "ERROR   - File '${file}' - collection notValidJsonFile - collection file ${BATS_TEST_DIRNAME}/testsData/pushMode/GithubAPI/notValidJsonFile.json is not a valid json file"
  assert_line --index 3 "ERROR   - File '${file}' - collection missingInfoName - collection file ${BATS_TEST_DIRNAME}/testsData/pushMode/GithubAPI/missingInfoName.json does not seem to be a valid collection file"

  assert_lines_count 4
}

function Postman::Model::validate::pullModeCollectionsWithErrors { #@test
  cp -R "${BATS_TEST_DIRNAME}/testsData/pullMode" "${BATS_TEST_TMPDIR}"
  chmod -w "${BATS_TEST_TMPDIR}/pullMode/GithubAPI/notWritableFile.json"
  chmod -w "${BATS_TEST_TMPDIR}/pullMode"
  Postman::Model::getRelativeConfigDirectory() {
    echo "${BATS_TEST_TMPDIR}/pullMode"
  }
  local file="${BATS_TEST_TMPDIR}/pullMode/getCollectionRefs-collectionsWithErrors.json"
  run Postman::Model::validate \
    "${file}" "pull"

  assert_failure 1
  assert_line --index 0 "ERROR   - File '${file}' - collection 0 - missing file property"
  assert_line --index 1 "ERROR   - File '${file}' - collection fileNotWritable - collection file ${BATS_TEST_TMPDIR}/pullMode/GithubAPI/notWritableFile.json is not writable"
  assert_line --index 2 "ERROR   - File '${file}' - collection dirNotWritable - config directory ${BATS_TEST_TMPDIR}/pullMode is not writable"

  assert_lines_count 3
}

function Postman::Model::validate::configMode::collectionsNotObject { #@test
  Postman::Model::getRelativeConfigDirectory() {
    echo "${BATS_TEST_DIRNAME}/testsData/configMode"
  }
  local file="${BATS_TEST_DIRNAME}/testsData/configMode/getCollectionRefs-collectionsNotObject.json"
  run Postman::Model::validate \
    "${file}" "config"

  assert_failure 1
  assert_line --index 0 "ERROR   - File '${file}' - collections property is missing or is not an object"
  assert_lines_count 1
}

function Postman::Model::validate::configMode::missingCollections { #@test
  Postman::Model::getRelativeConfigDirectory() {
    echo "${BATS_TEST_DIRNAME}/testsData/configMode"
  }
  local file="${BATS_TEST_DIRNAME}/testsData/configMode/getCollectionRefs-missingCollections.json"
  run Postman::Model::validate \
    "${file}" "config"

  assert_failure 1
  assert_line --index 0 "ERROR   - File '${file}' - collections property is missing or is not an object"
  assert_lines_count 1
}

function Postman::Model::validate::configMode::missingFileProperty { #@test
  Postman::Model::getRelativeConfigDirectory() {
    echo "${BATS_TEST_DIRNAME}/testsData/configMode"
  }
  local file="${BATS_TEST_DIRNAME}/testsData/configMode/getCollectionRefs-missingFileProperty.json"
  run Postman::Model::validate \
    "${file}" "config"

  assert_failure 1
  assert_line --index 0 "ERROR   - File '${file}' - collection 0 - missing file property"
  assert_lines_count 1
}

function Postman::Model::validate::configMode::missingName { #@test
  Postman::Model::getRelativeConfigDirectory() {
    echo "${BATS_TEST_DIRNAME}/testsData/configMode"
  }
  local file="${BATS_TEST_DIRNAME}/testsData/configMode/getCollectionRefs-missingName.json"
  run Postman::Model::validate \
    "${file}" "config"

  assert_failure 1
  assert_line --index 0 "ERROR   - File '${file}' - missing name property"
  assert_lines_count 1
}
