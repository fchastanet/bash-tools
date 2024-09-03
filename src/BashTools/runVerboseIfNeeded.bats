#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/.." && pwd)/batsHeaders.sh"
# shellcheck source=src/BashTools/runVerboseIfNeeded.sh
source "${rootDir}/src/BashTools/runVerboseIfNeeded.sh"

teardown() {
  unset optionTraceVerbose
}

function BashTools::runVerboseIfNeeded::noTrace { #@test
  run BashTools::runVerboseIfNeeded echo "coucou"
  assert_output "coucou"
  assert_success
}

function BashTools::runVerboseIfNeeded::trace { #@test
  export optionTraceVerbose="1"
  cmdTest() {
    optionTraceVerbose="1" BashTools::runVerboseIfNeeded echo "coucou"
  }
  run cmdTest
  assert_lines_count 2
  assert_line --index 0 '+ echo coucou'
  assert_line --index 1 "coucou"
  assert_success
}

function BashTools::runVerboseIfNeeded::redirectCmdOutputs { #@test
  export
  cmdTest() {
    optionTraceVerbose="1" optionRedirectCmdOutputs="/dev/null" BashTools::runVerboseIfNeeded echo "coucou"
  }
  run cmdTest
  assert_output '+ echo coucou'
  assert_success
}
