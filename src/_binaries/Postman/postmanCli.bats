#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"

  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}"
  cp -R "${rootDir}/conf" "${HOME}/.bash-tools"
}

function PostmanCli::display_help { #@test
  testCommand "${binDir}/postmanCli" postmanCli.help.txt
}

function PostmanCli::config { #@test
  export COLUMNS=2
  run "${binDir}/postmanCli" --config -m "${rootDir}/conf/postmanCli/openApis.json"
  assert_line --index 0 "Config"
  assert_line --index 1 --regexp '^[-]+$'
  assert_line --index 2 "BASH_FRAMEWORK_ARGV                      = ([0]=\"--config\" [1]=\"-m\" [2]=\"${rootDir}/conf/postmanCli/openApis.json\")"
  assert_line --index 3 "BASH_FRAMEWORK_ARGV_FILTERED             = ()"
  assert_line --index 4 'BASH_FRAMEWORK_DISPLAY_LEVEL             = "3"'
  assert_line --index 5 "BASH_FRAMEWORK_ENV_FILES                 = ([0]=\"${HOME}/.bash-tools/.env\")"
  assert_line --index 6 "BASH_FRAMEWORK_LOG_FILE                  = \"${TMPDIR}/logFile\""
  assert_line --index 7 'BASH_FRAMEWORK_LOG_FILE_MAX_ROTATION     = "5"'
  assert_line --index 8 'BASH_FRAMEWORK_LOG_LEVEL                 = "0"'
  assert_line --index 9 'BASH_FRAMEWORK_THEME                     = "noColor"'
  assert_line --index 10 --regexp '^[-]+$'
  assert_line --index 11 'POSTMAN_API_KEY                          = ...(truncated)'
  assert_lines_count 12

}
