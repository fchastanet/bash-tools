#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"
# shellcheck source=src/Postman/Commands/pushCommand.sh
source "${rootDir}/src/Postman/Commands/pushCommand.sh"

setup() {
  export BASH_FRAMEWORK_THEME="noColor"
}

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

function Postman::Commands::pushCommand::invalidWriteMode { #@test
  Postman::Model::validate() {
    echo "Postman::Model::validate $*"
    echo "invalid Mode"
    return 2
  }
  run Postman::Commands::pushCommand modelFile "invalidWriteMode" 2>&1
  assert_failure 1
  assert_line --index 0 "Postman::Model::validate modelFile push"
  assert_line --index 1 "invalid Mode"
  assert_lines_count 2
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
  run Postman::Commands::pushCommand modelFile "single" ref1 ref2 2>&1
  assert_failure 1
  assert_line --index 0 "Postman::Model::validate modelFile push"
  assert_line --index 1 "Postman::Model::getCollectionRefs modelFile refs"
  assert_line --index 2 "Postman::Model::checkIfValidCollectionRefs single ref1 ref2 refs"
  assert_lines_count 3
}

function Postman::Commands::pushCommand::getCollectionRefsEmpty { #@test
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
  run Postman::Commands::pushCommand modelFile 2>&1
  assert_failure 1
  assert_line --index 0 "Postman::Model::validate modelFile push"
  assert_line --index 1 "Postman::Model::getCollectionRefs modelFile refs"
  assert_line --index 2 "ERROR   - No collection refs to push"
  assert_lines_count 3
}

function Postman::Commands::pushCommand::pushCollections { #@test
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
  Postman::Commands::pushCollectionsSingle() {
    echo "Postman::Commands::pushCollectionsSingle $*"
  }
  Postman::Commands::pushCollectionsMerge() {
    echo "ERROR Postman::Commands::pushCollectionsMerge $*"
    return 1
  }
  export BASH_FRAMEWORK_DISPLAY_LEVEL="${__LEVEL_DEBUG}"
  run Postman::Commands::pushCommand modelFile 2>&1
  assert_success

  assert_lines_count 4
  assert_line --index 0 "Postman::Model::validate modelFile push"
  assert_line --index 1 "Postman::Model::getCollectionRefs modelFile refs"
  assert_line --index 2 "DEBUG   - Collection refs to push ref1 ref2 - write mode single"
  assert_line --index 3 "Postman::Commands::pushCollectionsSingle modelFile ref1 ref2"
}

function Postman::Commands::pushCommand::pushCollectionsMerge { #@test
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
  Postman::Commands::pushCollectionsSingle() {
    echo "ERROR Postman::Commands::pushCollectionsSingle $*"
    return 1
  }
  Postman::Commands::pushCollectionsMerge() {
    echo "Postman::Commands::pushCollectionsMerge $*"
  }
  export BASH_FRAMEWORK_DISPLAY_LEVEL="${__LEVEL_DEBUG}"
  run Postman::Commands::pushCommand modelFile 2>&1
  assert_success
  assert_lines_count 4
  assert_line --index 0 "Postman::Model::validate modelFile push"
  assert_line --index 1 "Postman::Model::getCollectionRefs modelFile refs"
  assert_line --index 2 "DEBUG   - Collection refs to push ref1 ref2 - write mode merge"
  assert_line --index 3 "Postman::Commands::pushCollectionsMerge modelFile ref1 ref2"
}
