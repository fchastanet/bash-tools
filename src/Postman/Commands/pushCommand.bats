#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"
# shellcheck source=src/Postman/Commands/pushCommand.sh
source "${rootDir}/src/Postman/Commands/pushCommand.sh"

function Postman::Commands::pushCommand::modelFileDoesNotExists { #@test
  Postman::Model::validate() {
    echo "$@" >"${BATS_TEST_TMPDIR}/output"
    return 12
  }
  run Postman::Commands::pushCommand modelFile 2>&1
  assert_failure 1
  assert_output ""
  run cat "${BATS_TEST_TMPDIR}/output"
  assert_output "modelFile push"
}

function Postman::Commands::pushCommand::getCollectionRefsFails { #@test
  Postman::Model::validate() {
    echo "$1" >"${BATS_TEST_TMPDIR}/validate"
    return 0
  }
  Postman::Model::getCollectionRefs() {
    local modelFile="$1"
    local -n getCollectionRefs=$2
    (
      echo "${modelFile}"
      declare -p "${!getCollectionRefs}"
    ) >"${BATS_TEST_TMPDIR}/getCollectionRefs"
    return 11
  }
  run Postman::Commands::pushCommand modelFile 2>&1
  assert_failure 1
  assert_output ""
  run cat "${BATS_TEST_TMPDIR}/validate"
  assert_output "modelFile"
  run cat "${BATS_TEST_TMPDIR}/getCollectionRefs"
  assert_lines_count 2
  assert_line --index 0 "modelFile"
  assert_line --index 1 "declare -a refs"
}

function Postman::Commands::pushCommand::checkIfValidCollectionRefsFails { #@test
  Postman::Model::validate() {
    echo "$1" >"${BATS_TEST_TMPDIR}/validate"
    return 0
  }
  Postman::Model::getCollectionRefs() {
    local modelFile="$1"
    local -n getCollectionRefs=$2
    (
      echo "${modelFile}"
      declare -p "${!getCollectionRefs}"
    ) >"${BATS_TEST_TMPDIR}/getCollectionRefs"
  }
  Postman::Model::checkIfValidCollectionRefs() {
    local modelFile="$1"
    local -n getCollectionRefs=$2
    shift 2 || true
    (
      echo "${modelFile}"
      declare -p "${!getCollectionRefs}"
      echo "$@"
    ) >"${BATS_TEST_TMPDIR}/checkIfValidCollectionRefs"
    return 10
  }
  run Postman::Commands::pushCommand modelFile ref1 ref2 2>&1
  assert_failure 1
  assert_output ""
  run cat "${BATS_TEST_TMPDIR}/validate"
  assert_output "modelFile"
  run cat "${BATS_TEST_TMPDIR}/getCollectionRefs"
  assert_lines_count 2
  assert_line --index 0 "modelFile"
  assert_line --index 1 "declare -a refs"
  run cat "${BATS_TEST_TMPDIR}/checkIfValidCollectionRefs"
  assert_lines_count 3
  assert_line --index 0 "modelFile"
  assert_line --index 1 "declare -a refs"
  assert_line --index 2 "ref1 ref2"
}

function Postman::Commands::pushCommand::getCollectionRefsEmpty { #@test
  Postman::Model::validate() {
    echo "$1" >"${BATS_TEST_TMPDIR}/validate"
    return 0
  }
  Postman::Model::getCollectionRefs() {
    local modelFile="$1"
    local -n getCollectionRefs=$2
    (
      echo "${modelFile}"
      declare -p "${!getCollectionRefs}"
    ) >"${BATS_TEST_TMPDIR}/getCollectionRefs"
  }
  run Postman::Commands::pushCommand modelFile 2>&1
  assert_failure 1
  assert_output "ERROR   - No collection refs to push"
  run cat "${BATS_TEST_TMPDIR}/validate"
  assert_output "modelFile"
  run cat "${BATS_TEST_TMPDIR}/getCollectionRefs"
  assert_lines_count 2
  assert_line --index 0 "modelFile"
  assert_line --index 1 "declare -a refs"
}

function Postman::Commands::pushCommand::pushCollections { #@test
  Postman::Model::validate() {
    echo "$1" >"${BATS_TEST_TMPDIR}/validate"
    return 0
  }
  Postman::Model::getCollectionRefs() {
    local modelFile="$1"
    local -n getCollectionRefs=$2
    (
      echo "${modelFile}"
      declare -p "${!getCollectionRefs}"
    ) >"${BATS_TEST_TMPDIR}/getCollectionRefs"
    getCollectionRefs=(ref1 ref2)
  }
  Postman::Commands::pushCollections() {
    echo "$@" >"${BATS_TEST_TMPDIR}/pushCollections"
  }
  export BASH_FRAMEWORK_DISPLAY_LEVEL="${__LEVEL_DEBUG}"
  run Postman::Commands::pushCommand modelFile 2>&1
  assert_success
  assert_output "DEBUG   - Collection refs to push ref1 ref2"
  run cat "${BATS_TEST_TMPDIR}/validate"
  assert_output "modelFile"
  run cat "${BATS_TEST_TMPDIR}/getCollectionRefs"
  assert_lines_count 2
  assert_line --index 0 "modelFile"
  assert_line --index 1 "declare -a refs"
  run cat "${BATS_TEST_TMPDIR}/pushCollections"
  assert_output "modelFile ref1 ref2"
}
