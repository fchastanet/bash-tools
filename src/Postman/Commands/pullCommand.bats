#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"
# shellcheck source=src/Postman/Commands/pullCommand.sh
source "${rootDir}/src/Postman/Commands/pullCommand.sh"

setup() {
  export BASH_FRAMEWORK_THEME="noColor"
}

function Postman::Commands::pullCommand::modelFileDoesNotExists { #@test
  Postman::Model::validate() {
    echo "$@" >"${BATS_TEST_TMPDIR}/output"
    return 12
  }
  run Postman::Commands::pullCommand modelFile "single" 2>&1
  assert_failure 1
  assert_output ""
  run cat "${BATS_TEST_TMPDIR}/output"
  assert_output "modelFile pull"
}

function Postman::Commands::pullCommand::invalidWriteMode { #@test
  Postman::Model::validate() {
    echo "Postman::Model::validate $*"
    echo "invalid Mode"
    return 2
  }
  run Postman::Commands::pullCommand modelFile "invalidWriteMode" 2>&1
  assert_failure 1
  assert_line --index 0 "Postman::Model::validate modelFile pull"
  assert_line --index 1 "invalid Mode"
  assert_lines_count 2
}

function Postman::Commands::pullCommand::getCollectionRefsFails { #@test
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
  run Postman::Commands::pullCommand modelFile "single" 2>&1
  assert_failure 1
  assert_output ""
  run cat "${BATS_TEST_TMPDIR}/validate"
  assert_output "modelFile"
  run cat "${BATS_TEST_TMPDIR}/getCollectionRefs"
  assert_lines_count 2
  assert_line --index 0 "modelFile"
  assert_line --index 1 "declare -a refs"
}

function Postman::Commands::pullCommand::checkIfValidCollectionRefsFails { #@test
  Postman::Model::validate() {
    echo "Postman::Model::validate $*"
  }
  Postman::Model::getCollectionRefs() {
    local -n getCollectionRefs=$2
    echo "Postman::Model::getCollectionRefs $*"
    getCollectionRefs=(ref1 ref2)
  }
  Postman::Model::checkIfValidCollectionRefs() {
    local modelFile="$1"
    local -n getCollectionRefs=$2
    shift 2 || true
    echo "Postman::Model::checkIfValidCollectionRefs $* ${!getCollectionRefs}"
    return 10
  }
  run Postman::Commands::pullCommand modelFile "single" ref1 ref2 2>&1
  assert_failure 1
  assert_line --index 0 "Postman::Model::validate modelFile pull"
  assert_line --index 1 "Postman::Model::getCollectionRefs modelFile refs"
  assert_line --index 2 "Postman::Model::checkIfValidCollectionRefs single ref1 ref2 refs"
  assert_lines_count 3
}

function Postman::Commands::pullCommand::getCollectionRefsEmpty { #@test
  Postman::Model::validate() {
    echo "Postman::Model::validate $*"
  }
  Postman::Model::getCollectionRefs() {
    echo >&2 "Postman::Model::getCollectionRefs $*"
  }
  Postman::Model::checkIfValidCollectionRefs() {
    local modelFile="$1"
    local -n availableRefs=$2
    shift 2 || true
    echo "Postman::Model::checkIfValidCollectionRefs $* ${!availableRefs}"
    echo "${availableRefs[@]}"
  }
  run Postman::Commands::pullCommand modelFile ref1 ref2 2>&1
  assert_failure 1
  assert_line --index 0 "Postman::Model::validate modelFile pull"
  assert_line --index 1 "Postman::Model::getCollectionRefs modelFile refs"
  assert_line --index 2 "ERROR   - No collection refs to pull"
  assert_lines_count 3
}

function Postman::Commands::pullCommand::pullCollectionsSingle { #@test
  Postman::Model::validate() {
    echo "Postman::Model::validate $*"
  }
  Postman::Model::getCollectionRefs() {
    local modelFile="$1"
    local -n getCollectionRefs=$2
    echo "Postman::Model::getCollectionRefs $*"
    getCollectionRefs=(ref1 ref2)
  }
  Postman::Model::checkIfValidCollectionRefs() {
    echo "ERROR Postman::Commands::checkIfValidCollectionRefs $*"
    return 1
  }
  Postman::Model::getWriteMode() {
    echo "single"
  }
  Postman::Commands::pullCollectionsSingle() {
    echo "Postman::Commands::pullCollectionsSingle $*"
  }
  Postman::Commands::pullCollectionsMerge() {
    echo "ERROR Postman::Commands::pullCollectionsMerge $*"
    return 1
  }
  export BASH_FRAMEWORK_DISPLAY_LEVEL="${__LEVEL_DEBUG}"
  run Postman::Commands::pullCommand modelFile 2>&1
  assert_success

  assert_lines_count 4
  assert_line --index 0 "Postman::Model::validate modelFile pull"
  assert_line --index 1 "Postman::Model::getCollectionRefs modelFile refs"
  assert_line --index 2 "DEBUG   - Collection refs to pull ref1 ref2 - write mode single"
  assert_line --index 3 "Postman::Commands::pullCollectionsSingle modelFile ref1 ref2"
}

function Postman::Commands::pullCommand::pullCollectionsMerge { #@test
  Postman::Model::validate() {
    echo "Postman::Model::validate $*"
  }
  Postman::Model::getCollectionRefs() {
    local modelFile="$1"
    local -n getCollectionRefs=$2
    echo "Postman::Model::getCollectionRefs $*"
    getCollectionRefs=(ref1 ref2)
  }
  Postman::Model::checkIfValidCollectionRefs() {
    echo "ERROR Postman::Commands::checkIfValidCollectionRefs $*"
    return 1
  }
  Postman::Model::getWriteMode() {
    echo "merge"
  }
  Postman::Commands::pullCollectionsSingle() {
    echo "ERROR Postman::Commands::pullCollectionsSingle $*"
    return 1
  }
  Postman::Commands::pullCollectionsMerge() {
    echo "Postman::Commands::pullCollectionsMerge $*"
  }
  export BASH_FRAMEWORK_DISPLAY_LEVEL="${__LEVEL_DEBUG}"
  run Postman::Commands::pullCommand modelFile 2>&1
  assert_success
  assert_lines_count 4
  assert_line --index 0 "Postman::Model::validate modelFile pull"
  assert_line --index 1 "Postman::Model::getCollectionRefs modelFile refs"
  assert_line --index 2 "DEBUG   - Collection refs to pull ref1 ref2 - write mode merge"
  assert_line --index 3 "Postman::Commands::pullCollectionsMerge modelFile ref1 ref2"
}
