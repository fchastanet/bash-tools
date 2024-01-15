#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/.." && pwd)/batsHeaders.sh"
# shellcheck source=src/Postman/displayResponse.sh
source "${rootDir}/src/Postman/displayResponse.sh"

function Postman::displayResponse::nonVerbose { #@test
  export BASH_FRAMEWORK_ARGS_VERBOSE=0
  run Postman::displayResponse "type" "${BATS_TEST_DIRNAME}/testsData/responseFile" 2>&1
  assert_output ""
  assert_success
}

function Postman::displayResponse::verbose { #@test
  export BASH_FRAMEWORK_ARGS_VERBOSE=1
  UI::drawLine() {
    echo >&2 '----'
  }
  run Postman::displayResponse "type" "${BATS_TEST_DIRNAME}/testsData/responseFile" 2>&1
  assert_output "$(cat "${BATS_TEST_DIRNAME}/testsData/expectedResponseFile")"
  assert_success
}
