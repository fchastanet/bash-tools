#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/.." && pwd)/batsHeaders.sh"
# shellcheck source=src/BashTools/runVerboseIfNeeded.sh
source "${rootDir}/src/BashTools/runVerboseIfNeeded.sh"

teardown() {
  unset optionInfoVerbose
}

function BashTools::runVerboseIfNeeded::noTrace { #@test
  run BashTools::runVerboseIfNeeded echo "verbose"
  assert_output "verbose"
  assert_success
}

function BashTools::runVerboseIfNeeded::trace { #@test
  cmdTest() {
    BASH_FRAMEWORK_ARGS_VERBOSE=__VERBOSE_LEVEL_INFO BashTools::runVerboseIfNeeded echo "verbose"
  }
  run cmdTest
  assert_lines_count 2
  assert_line --index 0 '+ echo verbose'
  assert_line --index 1 "verbose"
  assert_success
}

function BashTools::runVerboseIfNeeded::redirectCmdOutputs { #@test
  export BASH_FRAMEWORK_ARGS_VERBOSE
  cmdTest() {
    BASH_FRAMEWORK_ARGS_VERBOSE=__VERBOSE_LEVEL_INFO optionRedirectCmdOutputs="/dev/null" BashTools::runVerboseIfNeeded echo "verbose"
  }
  run cmdTest
  assert_output '+ echo verbose'
  assert_success
}
