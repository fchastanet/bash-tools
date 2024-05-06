#!/usr/bin/env bash

rootDir="$(cd "$(readlink -e "${BASH_SOURCE[0]%/*}")/.." && pwd -P)"
# shellcheck disable=SC2034
binDir="${rootDir}/bin"
vendorDir="${rootDir}/vendor"
FRAMEWORK_ROOT_DIR="$(cd "$(readlink -e "${vendorDir}/bash-tools-framework")" && pwd -P)"
export FRAMEWORK_ROOT_DIR

load "${FRAMEWORK_ROOT_DIR}/vendor/bats-support/load.bash"
load "${FRAMEWORK_ROOT_DIR}/vendor/bats-assert/load.bash"
load "${FRAMEWORK_ROOT_DIR}/vendor/bats-mock-Flamefire/load.bash"

# shellcheck source=vendor/bash-tools-framework/src/_includes/_mandatoryHeader.sh
source "${FRAMEWORK_ROOT_DIR}/src/_includes/_mandatoryHeader.sh"

# shellcheck source=vendor/bash-tools-framework/src/_standalone/Bats/assert_lines_count.sh
source "${FRAMEWORK_ROOT_DIR}/src/_standalone/Bats/assert_lines_count.sh"
# shellcheck source=vendor/bash-tools-framework/src/Env/__all.sh
source "${FRAMEWORK_ROOT_DIR}/src/Env/__all.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/__all.sh
source "${FRAMEWORK_ROOT_DIR}/src/Log/__all.sh"
# shellcheck source=vendor/bash-tools-framework/src/UI/theme.sh
source "${FRAMEWORK_ROOT_DIR}/src/UI/theme.sh"
# shellcheck source=vendor/bash-tools-framework/src/Assert/tty.sh
source "${FRAMEWORK_ROOT_DIR}/src/Assert/tty.sh"

export DISPLAY_DURATION=0
export BASH_FRAMEWORK_LOG_FILE="${BATS_TEST_TMPDIR}/logFile"
export BASH_FRAMEWORK_DISPLAY_LEVEL="${__LEVEL_INFO}"
export BASH_FRAMEWORK_LOG_LEVEL=${__LEVEL_OFF}
export SKIP_REQUIREMENTS_CHECKS=1

Env::requireLoad "${rootDir}/conf/.env"
Log::requireLoad

# @description test command help
# @env BATS_FIX_TEST int 1 to fix testsData expected files
# @arg $1 command:String command to test
# @arg $2 expectedOutputFile:String expected output file
testCommand() {
  local command="$1"
  local expectedOutputFile="$2"
  shift 2 || true
  local -a args=("$@")
  if ((${#args} == 0)); then
    args=(--help)
  fi
  export INTERACTIVE=1
  UI::theme default
  run "${command}" "${args[@]}"
  assert_success
  if [[ "${BATS_FIX_TEST}" = "1" && ! -f "${BATS_TEST_DIRNAME}/testsData/${expectedOutputFile}" ]]; then
    mkdir -p "${BATS_TEST_DIRNAME}/testsData" || true
    touch "${BATS_TEST_DIRNAME}/testsData/${expectedOutputFile}"
  fi

  output=$(echo -e "${output}" | sed -E "s#${HOME}#home#g")
  # shellcheck disable=SC2154
  diff <(echo -e "${output}") "${BATS_TEST_DIRNAME}/testsData/${expectedOutputFile}" || {
    if [[ "${BATS_FIX_TEST}" = "1" ]]; then
      echo -e "${output}" >"${BATS_TEST_DIRNAME}/testsData/${expectedOutputFile}"
    fi
    return 1
  }
}
