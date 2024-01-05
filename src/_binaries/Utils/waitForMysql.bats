#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"

  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}/.bash-tools"
  mkdir -p "${HOME}/bin"
  export PATH="${HOME}/bin:${PATH}"
  cp "${rootDir}/conf/.env" "${HOME}/.bash-tools/.env"
}

teardown() {
  unstub_all
  rm -f "${HOME}/bin/nc" || true
}

function Utils::waitForMysql::display_help { #@test
  testCommand "${binDir}/waitForMysql" waitForMysql.help.txt
}

function Utils::waitForMysql::missingHost { #@test
  run "${binDir}/waitForMysql" 2>&1

  assert_failure 1
  assert_lines_count 1
  assert_output --partial "ERROR   - Command waitForMysql - Argument 'mysqlHost' should be provided at least 1 time(s)"
}

function Utils::waitForMysql::missingPort { #@test
  run "${binDir}/waitForMysql" localhost 2>&1

  assert_failure 1
  assert_lines_count 1
  assert_output --partial "ERROR   - Command waitForMysql - Argument 'mysqlPort' should be provided at least 1 time(s)"
}

function Utils::waitForMysql::missingUser { #@test
  run "${binDir}/waitForMysql" localhost 3306 2>&1

  assert_failure 1
  assert_lines_count 1
  assert_output --partial "ERROR   - Command waitForMysql - Argument 'mysqlUserArg' should be provided at least 1 time(s)"
}

function Utils::waitForMysql::missingPassword { #@test
  run "${binDir}/waitForMysql" localhost 3306 user 2>&1

  assert_failure 1
  assert_lines_count 1
  assert_output --partial "ERROR   - Command waitForMysql - Argument 'mysqlPasswordArg' should be provided at least 1 time(s)"
}

function Utils::waitForMysql::invalidTimeout { #@test
  run "${binDir}/waitForMysql" localhost 3306 user password --timeout invalid 2>&1

  assert_failure 1
  assert_lines_count 1
  assert_output --partial "FATAL   - waitForMysql - invalid timeout option - must be greater or equal to 0"
}

function Utils::waitForMysql::mysqlCommandNotFound { #@test
  stub commandNotFound '-v mysql : exit 1'
  export BASH_FRAMEWORK_COMMAND=commandNotFound
  run "${binDir}/waitForMysql" localhost 3306 user password --timeout 1 2>&1

  assert_failure 1
  assert_lines_count 1
  assert_output --partial "ERROR   - mysql is not installed, please install it"
}

function Utils::waitForMysql::mysqlAvailable { #@test
  stub commandExists '-v mysql : exit 0'
  export BASH_FRAMEWORK_COMMAND=commandExists
  stub mysql '-hlocalhost -P3306 -uuser -ppassword : exit 0'
  run "${binDir}/waitForMysql" localhost 3306 user password --timeout 1 2>&1

  assert_success
  assert_line --index 0 --partial "INFO    - Waiting for mysql"
  assert_line --index 1 --partial "."
  assert_line --index 2 --partial "INFO    - mysql ready"
  assert_lines_count 3
}

function Utils::waitForMysql::mysqlNotAvailableAfter1SecondTimeout { #@test
  stub commandExists '-v mysql : exit 0'
  export BASH_FRAMEWORK_COMMAND=commandExists
  stub mysql '-hlocalhost -P3306 -uuser -ppassword : exit 1'
  run "${binDir}/waitForMysql" localhost 3306 user password --timeout 1 2>&1

  assert_failure 2
  assert_line --index 0 --partial "INFO    - Waiting for mysql"
  assert_line --index 1 --partial "."
  assert_line --index 2 --partial "ERROR   - waitForMysql - timeout for localhost:3306 occurred after"
  assert_lines_count 3
}
