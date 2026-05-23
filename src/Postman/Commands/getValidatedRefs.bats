#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"
# shellcheck source=src/Postman/Commands/getValidatedRefs.sh
source "${rootDir}/src/Postman/Commands/getValidatedRefs.sh"

# Wrapper that owns the `refs` array so the name ref inside
# getValidatedRefs can be resolved correctly. Passes all arguments
# through as the optional collection-ref list.
_getValidatedRefs_wrapper() {
  local -a refs
  Postman::Commands::getValidatedRefs modelFile pull refs "$@"
}

function Postman::Commands::getValidatedRefs::getCollectionRefsFails { #@test
  Postman::Model::getCollectionRefs() {
    local modelFile="$1"
    local -n getCollectionRefs=$2
    (
      echo "${modelFile}"
      declare -p "${!getCollectionRefs}"
    ) >"${BATS_TEST_TMPDIR}/getCollectionRefs"
    return 11
  }
  run _getValidatedRefs_wrapper 2>&1
  assert_failure 1
  assert_output ""
  run cat "${BATS_TEST_TMPDIR}/getCollectionRefs"
  assert_lines_count 2
  assert_line --index 0 "modelFile"
  assert_line --index 1 "declare -a refs"
}

function Postman::Commands::getValidatedRefs::checkIfValidCollectionRefsFails { #@test
  Postman::Model::getCollectionRefs() {
    local -n getCollectionRefs=$2
    (
      echo "$1"
      declare -p "${!getCollectionRefs}"
    ) >"${BATS_TEST_TMPDIR}/getCollectionRefs"
  }
  Postman::Model::checkIfValidCollectionRefs() {
    local modelFile="$1"
    local -n checkRefs=$2
    shift 2 || true
    (
      echo "${modelFile}"
      declare -p "${!checkRefs}"
      echo "$@"
    ) >"${BATS_TEST_TMPDIR}/checkIfValidCollectionRefs"
    return 10
  }
  run _getValidatedRefs_wrapper ref1 ref2 2>&1
  assert_failure 1
  assert_output ""
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

function Postman::Commands::getValidatedRefs::refsEmpty { #@test
  Postman::Model::getCollectionRefs() {
    local -n getCollectionRefs=$2
    (
      echo "$1"
      declare -p "${!getCollectionRefs}"
    ) >"${BATS_TEST_TMPDIR}/getCollectionRefs"
  }
  run _getValidatedRefs_wrapper 2>&1
  assert_failure 1
  assert_output "ERROR   - No collection refs to pull"
  run cat "${BATS_TEST_TMPDIR}/getCollectionRefs"
  assert_lines_count 2
  assert_line --index 0 "modelFile"
  assert_line --index 1 "declare -a refs"
}

function Postman::Commands::getValidatedRefs::refsFromModel { #@test
  Postman::Model::getCollectionRefs() {
    local -n getCollectionRefs=$2
    (
      echo "$1"
      declare -p "${!getCollectionRefs}"
    ) >"${BATS_TEST_TMPDIR}/getCollectionRefs"
    getCollectionRefs=(ref1 ref2)
  }
  export BASH_FRAMEWORK_DISPLAY_LEVEL="${__LEVEL_DEBUG}"
  run _getValidatedRefs_wrapper 2>&1
  assert_success
  assert_output "DEBUG   - Collection refs to pull ref1 ref2"
  run cat "${BATS_TEST_TMPDIR}/getCollectionRefs"
  assert_lines_count 2
  assert_line --index 0 "modelFile"
  assert_line --index 1 "declare -a refs"
}

function Postman::Commands::getValidatedRefs::refsExplicit { #@test
  Postman::Model::getCollectionRefs() {
    local -n getCollectionRefs=$2
    (
      echo "$1"
      declare -p "${!getCollectionRefs}"
    ) >"${BATS_TEST_TMPDIR}/getCollectionRefs"
    # intentionally not populated: explicit refs override the model refs
  }
  Postman::Model::checkIfValidCollectionRefs() {
    local modelFile="$1"
    local -n checkRefs=$2
    shift 2 || true
    (
      echo "${modelFile}"
      declare -p "${!checkRefs}"
      echo "$@"
    ) >"${BATS_TEST_TMPDIR}/checkIfValidCollectionRefs"
  }
  export BASH_FRAMEWORK_DISPLAY_LEVEL="${__LEVEL_DEBUG}"
  run _getValidatedRefs_wrapper ref1 ref2 2>&1
  assert_success
  assert_output "DEBUG   - Collection refs to pull ref1 ref2"
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
