#!/usr/bin/env bash

rootDir="$(cd "$(readlink -e "${BASH_SOURCE[0]%/*}")/.." && pwd -P)"
# shellcheck disable=SC2034
binDir="${rootDir}/bin"
vendorDir="${rootDir}/vendor"
FRAMEWORK_ROOT_DIR="$(cd "$(readlink -e "${vendorDir}/bash-tools-framework")" && pwd -P)"
export FRAMEWORK_ROOT_DIR

# shellcheck source=vendor/bash-tools-framework/src/batsHeaders.sh
source "${FRAMEWORK_ROOT_DIR}/src/batsHeaders.sh"

export DISPLAY_DURATION=0
export BASH_FRAMEWORK_LOG_FILE="/tmp/logFile"
export BASH_FRAMEWORK_DISPLAY_LEVEL="${__LEVEL_INFO}"
export BASH_FRAMEWORK_LOG_LEVEL=${__LEVEL_OFF}
export SKIP_REQUIREMENTS_CHECKS=1

Env::requireLoad "${rootDir}/conf/defaultEnv/.env"
Log::requireLoad

# @description test command help
# @env BATS_FIX_TEST int 1 to fix testsData expected files
# @arg $1 command:String command to test
# @arg $2 expectedOutputFile:String expected output file
# @env ERROR_CODE int 0
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
  if [[ "${ERROR_CODE:-0}" == "0" ]]; then
    assert_success
  else
    assert_failure "${ERROR_CODE}"
  fi
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
