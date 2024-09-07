#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)/batsHeaders.sh"

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"

  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}/.bash-tools"
  mkdir -p "${HOME}/bin"
  cp "${rootDir}/conf/.env" "${HOME}/.bash-tools/.env"
  export PATH="${HOME}/bin:${PATH}"
}

teardown() {
  unstub_all
  rm -f "${HOME}/bin/nc" || true
}

function Utils::waitForIt::display_help { #@test
  testCommand "${binDir}/waitForIt" waitForIt.help.txt
}

function Utils::waitForIt::noArgs { #@test
  run "${binDir}/waitForIt" 2>&1

  assert_failure 1
  assert_lines_count 1
  assert_output --partial "ERROR   - Command waitForIt - Argument 'hostOrIp' should be provided at least 1 time(s)"
}

function Utils::waitForIt::missingPort { #@test
  run "${binDir}/waitForIt" localhost 2>&1

  assert_failure 1
  assert_lines_count 1
  assert_output --partial "ERROR   - Command waitForIt - Argument 'port' should be provided at least 1 time(s)"
}

function Utils::waitForIt::missingHost { #@test
  run "${binDir}/waitForIt" 8888 2>&1

  assert_failure 1
  assert_lines_count 1
  assert_output --partial "ERROR   - Command waitForIt - Argument 'port' should be provided at least 1 time(s)"
}

function Utils::waitForIt::invalidTimeout { #@test
  run "${binDir}/waitForIt" localhost 8888 --timeout invalid 2>&1

  assert_failure 1
  assert_lines_count 1
  assert_output --partial "FATAL   - waitForIt - invalid timeout option - must be greater or equal to 0"
}

function Utils::waitForIt::invalidAlgo { #@test
  run "${binDir}/waitForIt" localhost 8888 --algo invalid 2>&1

  assert_failure 1
  assert_lines_count 1
  assert_output --partial "FATAL   - waitForIt - invalid algorithm option 'invalid'"
}

function Utils::waitForIt::algo::timeoutV1WithNc::WithoutCommand { #@test
  stub timeout "-t 1 ${binDir}/waitForIt localhost 8888 --timeout 1 --algo timeoutV1WithNc : ${binDir}/waitForIt localhost 8888 --timeout 1 --algo timeoutV1WithNc"
  stub nc "-z localhost 8888 -w 1 : exit 0"
  run "${binDir}/waitForIt" localhost 8888 --timeout 1 --algo timeoutV1WithNc 2>&1

  assert_success
  assert_line --index 0 --partial "INFO    - waitForIt - using algorithm timeoutV1WithNc"
  assert_line --index 1 --partial "INFO    - waitForIt - waiting "
  assert_line --index 1 --partial " seconds for localhost:8888"
  assert_line --index 2 --partial "INFO    - waitForIt - localhost:8888 is available after "
  assert_lines_count 3
}

function Utils::waitForIt::algo::timeoutV1WithNc::ExecCommand { #@test
  stub timeout "-t 1 ${binDir}/waitForIt localhost 8888 --timeout 1 --algo timeoutV1WithNc echo success : \
    ${binDir}/waitForIt localhost 8888 --timeout 1 --algo timeoutV1WithNc echo success"
  stub nc "-z localhost 8888 -w 1 : exit 0"
  run "${binDir}/waitForIt" localhost 8888 --timeout 1 --algo timeoutV1WithNc echo "success" 2>&1

  assert_success
  assert_line --index 0 --partial "INFO    - waitForIt - using algorithm timeoutV1WithNc"
  assert_line --index 1 --partial "INFO    - waitForIt - waiting "
  assert_line --index 1 --partial " seconds for localhost:8888"
  assert_line --index 2 --partial "INFO    - waitForIt - localhost:8888 is available after "
  assert_line --index 3 "success"
  assert_lines_count 4
}

function Utils::waitForIt::algo::timeoutV1WithNc::NoCommandExecutedIfFailed { #@test
  (
    echo "#!/usr/bin/env bash"
    echo 'exit 1'
  ) >"${HOME}/bin/nc"
  chmod +x "${HOME}/bin/nc"

  stub timeout \
    "-t 1 ${binDir}/waitForIt localhost 8888 --timeout 1 --algo timeoutV1WithNc echo success : ${binDir}/waitForIt localhost 8888 --timeout 1 --algo timeoutV1WithNc echo success"
  run "${binDir}/waitForIt" localhost 8888 --timeout 1 --algo timeoutV1WithNc echo "success" 2>&1

  assert_failure 2
  assert_line --index 0 --partial "INFO    - waitForIt - using algorithm timeoutV1WithNc"
  assert_line --index 1 --partial "INFO    - waitForIt - waiting "
  assert_line --index 1 --partial " seconds for localhost:8888"
  assert_line --index 2 --partial "ERROR   - waitForIt - timeout for localhost:8888 occurred after "
  assert_line --index 3 --partial "ERROR   - waitForIt - failed to connect - strict mode - command not executed"
  assert_lines_count 4
}

function Utils::waitForIt::algo::timeoutV2WithNc::WithoutCommand { #@test
  stub timeout "1 ${binDir}/waitForIt localhost 8888 --timeout 1 --lax --algo timeoutV2WithNc : ${binDir}/waitForIt localhost 8888 --timeout 1 --algo timeoutV2WithNc"
  stub nc "-z localhost 8888 -w 1 : exit 0"
  run "${binDir}/waitForIt" localhost 8888 --timeout 1 --lax --algo timeoutV2WithNc 2>&1

  assert_success
  assert_line --index 0 --partial "INFO    - waitForIt - using algorithm timeoutV2WithNc"
  assert_line --index 1 --partial "INFO    - waitForIt - waiting 1 seconds for localhost:8888"
  assert_line --index 2 --partial "INFO    - waitForIt - localhost:8888 is available after "
  assert_lines_count 3
}

function Utils::waitForIt::algo::timeoutV2WithNc::ExecCommand { #@test
  stub timeout "1 ${binDir}/waitForIt localhost 8888 --timeout 1 --lax --algo timeoutV2WithNc echo success : \
    ${binDir}/waitForIt localhost 8888 --timeout 1 --algo timeoutV2WithNc echo success"
  stub nc "-z localhost 8888 -w 1 : exit 0"
  run "${binDir}/waitForIt" localhost 8888 --timeout 1 --lax --algo timeoutV2WithNc echo "success" 2>&1

  assert_success
  assert_line --index 0 --partial "INFO    - waitForIt - using algorithm timeoutV2WithNc"
  assert_line --index 1 --partial "INFO    - waitForIt - waiting 1 seconds for localhost:8888"
  assert_line --index 2 --partial "INFO    - waitForIt - localhost:8888 is available after "
  assert_line --index 3 "success"
  assert_lines_count 4
}

function Utils::waitForIt::algo::timeoutV2WithNc::NoCommandExecutedIfFailed { #@test
  (
    echo "#!/usr/bin/env bash"
    echo 'exit 1'
  ) >"${HOME}/bin/nc"
  chmod +x "${HOME}/bin/nc"

  stub timeout \
    "1 ${binDir}/waitForIt localhost 8888 --timeout 1 --algo timeoutV2WithNc echo success : ${binDir}/waitForIt localhost 8888 --timeout 1 --algo timeoutV2WithNc echo success"
  run "${binDir}/waitForIt" localhost 8888 --timeout 1 --algo timeoutV2WithNc echo "success" 2>&1

  assert_failure 2
  assert_line --index 0 --partial "INFO    - waitForIt - using algorithm timeoutV2WithNc"
  assert_line --index 1 --partial "INFO    - waitForIt - waiting 1 seconds for localhost:8888"
  assert_line --index 2 --partial "ERROR   - waitForIt - timeout for localhost:8888 occurred after "
  assert_line --index 3 --partial "ERROR   - waitForIt - failed to connect - strict mode - command not executed"
  assert_lines_count 4
}

# ----------------- TCP ------------------------------------------------------------

function Utils::waitForIt::algo::timeoutV1WithTcp::WithoutCommand { #@test
  export WAIT_FOR_IT_MOCKED_TCP=mockedTcp
  # shellcheck disable=SC2317
  function mockedTcp() {
    echo "mocked $*"
  }
  export -f mockedTcp
  stub timeout "-t 1 ${binDir}/waitForIt localhost 8888 --timeout 1 --lax --algo timeoutV1WithTcp : ${binDir}/waitForIt localhost 8888 --timeout 1 --algo timeoutV1WithTcp"
  run "${binDir}/waitForIt" localhost 8888 --timeout 1 --lax --algo timeoutV1WithTcp 2>&1

  assert_success
  assert_line --index 0 --partial "INFO    - waitForIt - using algorithm timeoutV1WithTcp"
  assert_line --index 1 --partial "INFO    - waitForIt - waiting 1 seconds for localhost:8888"
  assert_line --index 2 "mocked /dev/tcp/localhost/8888"
  assert_line --index 3 --partial "INFO    - waitForIt - localhost:8888 is available after "
  assert_lines_count 4
}

function Utils::waitForIt::algo::timeoutV1WithTcp::ExecCommand { #@test
  export WAIT_FOR_IT_MOCKED_TCP=mockedTcp
  # shellcheck disable=SC2317
  function mockedTcp() {
    echo "mocked $*"
  }
  export -f mockedTcp
  stub timeout "-t 1 ${binDir}/waitForIt localhost 8888 --timeout 1 --lax --algo timeoutV1WithTcp echo success : \
    ${binDir}/waitForIt localhost 8888 --timeout 1 --lax --algo timeoutV1WithTcp echo success"
  run "${binDir}/waitForIt" localhost 8888 --timeout 1 --lax --algo timeoutV1WithTcp echo "success" 2>&1

  assert_success
  assert_line --index 0 --partial "INFO    - waitForIt - using algorithm timeoutV1WithTcp"
  assert_line --index 1 --partial "INFO    - waitForIt - waiting 1 seconds for localhost:8888"
  assert_line --index 2 "mocked /dev/tcp/localhost/8888"
  assert_line --index 3 --partial "INFO    - waitForIt - localhost:8888 is available after "
  assert_line --index 4 "success"
  assert_lines_count 5
}

function Utils::waitForIt::algo::timeoutV1WithTcp::NoCommandExecutedIfFailed { #@test
  export WAIT_FOR_IT_MOCKED_TCP=mockedTcp
  # shellcheck disable=SC2317
  function mockedTcp() {
    return 1
  }
  export -f mockedTcp
  stub timeout \
    "-t 1 ${binDir}/waitForIt localhost 8888 --timeout 1 --algo timeoutV1WithTcp echo success : ${binDir}/waitForIt localhost 8888 --timeout 1 --algo timeoutV1WithTcp echo success"
  run "${binDir}/waitForIt" localhost 8888 --timeout 1 --algo timeoutV1WithTcp echo "success" 2>&1

  assert_failure 2
  assert_line --index 0 --partial "INFO    - waitForIt - using algorithm timeoutV1WithTcp"
  assert_line --index 1 --partial "INFO    - waitForIt - waiting 1 seconds"
  assert_line --index 2 --partial "ERROR   - waitForIt - timeout for localhost:8888 occurred after "
  assert_line --index 3 --partial "ERROR   - waitForIt - failed to connect - strict mode - command not executed"
  assert_lines_count 4
}

function Utils::waitForIt::algo::timeoutV2WithTcp::WithoutCommand { #@test
  export WAIT_FOR_IT_MOCKED_TCP=mockedTcp
  # shellcheck disable=SC2317
  function mockedTcp() {
    return 0
  }
  export -f mockedTcp
  stub timeout "1 ${binDir}/waitForIt localhost 8888 --timeout 1 --lax --algo timeoutV2WithTcp : ${binDir}/waitForIt localhost 8888 --timeout 1 --algo timeoutV2WithTcp"
  run "${binDir}/waitForIt" localhost 8888 --timeout 1 --lax --algo timeoutV2WithTcp 2>&1

  assert_success
  assert_line --index 0 --partial "INFO    - waitForIt - using algorithm timeoutV2WithTcp"
  assert_line --index 1 --partial "INFO    - waitForIt - waiting 1 seconds for localhost:8888"
  assert_line --index 2 --partial "INFO    - waitForIt - localhost:8888 is available after "
  assert_lines_count 3
}

function Utils::waitForIt::algo::timeoutV2WithTcp::ExecCommand { #@test
  export WAIT_FOR_IT_MOCKED_TCP=mockedTcp
  # shellcheck disable=SC2317
  function mockedTcp() {
    return 0
  }
  export -f mockedTcp
  stub timeout "1 ${binDir}/waitForIt localhost 8888 --timeout 1 --lax --algo timeoutV2WithTcp echo success : \
    ${binDir}/waitForIt localhost 8888 --timeout 1 --lax --algo timeoutV2WithTcp echo success"
  run "${binDir}/waitForIt" localhost 8888 --timeout 1 --lax --algo timeoutV2WithTcp echo "success" 2>&1

  assert_success
  assert_line --index 0 --partial "INFO    - waitForIt - using algorithm timeoutV2WithTcp"
  assert_line --index 1 --partial "INFO    - waitForIt - waiting 1 seconds for localhost:8888"
  assert_line --index 2 --partial "INFO    - waitForIt - localhost:8888 is available after "
  assert_line --index 3 "success"
  assert_lines_count 4
}

function Utils::waitForIt::algo::timeoutV2WithTcp::NoCommandExecutedIfFailed { #@test
  export WAIT_FOR_IT_MOCKED_TCP=mockedTcp
  # shellcheck disable=SC2317
  function mockedTcp() {
    return 1
  }
  export -f mockedTcp
  stub timeout \
    "1 ${binDir}/waitForIt localhost 8888 --timeout 1 --algo timeoutV2WithTcp echo success : ${binDir}/waitForIt localhost 8888 --timeout 1 --algo timeoutV2WithTcp echo success"
  run "${binDir}/waitForIt" localhost 8888 --timeout 1 --algo timeoutV2WithTcp echo "success" 2>&1
  assert_failure 2
  assert_line --index 0 --partial "INFO    - waitForIt - using algorithm timeoutV2WithTcp"
  assert_line --index 1 --partial "INFO    - waitForIt - waiting 1 seconds for localhost:8888"
  assert_line --index 2 --partial "ERROR   - waitForIt - timeout for localhost:8888 occurred after "
  assert_line --index 3 --partial "ERROR   - waitForIt - failed to connect - strict mode - command not executed"
  assert_lines_count 4
}

# ----------------- whileLoop ------------------------------------------------------------

function Utils::waitForIt::algo::whileLoopWithTcp::WithoutCommand { #@test
  export WAIT_FOR_IT_MOCKED_TCP=mockedTcp
  # shellcheck disable=SC2317
  function mockedTcp() {
    echo "mocked $*"
  }
  export -f mockedTcp
  stub timeout "-t 1 ${binDir}/waitForIt localhost 8888 --timeout 1 --lax --algo whileLoopWithTcp : ${binDir}/waitForIt localhost 8888 --timeout 1 --algo whileLoopWithTcp"
  run "${binDir}/waitForIt" localhost 8888 --timeout 1 --lax --algo whileLoopWithTcp 2>&1

  assert_success
  assert_line --index 0 --partial "INFO    - waitForIt - using algorithm whileLoopWithTcp"
  assert_line --index 1 --partial "INFO    - waitForIt - waiting 1 seconds for localhost:8888"
  assert_line --index 2 "mocked /dev/tcp/localhost/8888"
  assert_line --index 3 --partial "INFO    - waitForIt - localhost:8888 is available after "
  assert_lines_count 4
}

function Utils::waitForIt::algo::whileLoopWithTcp::ExecCommand { #@test
  export WAIT_FOR_IT_MOCKED_TCP=mockedTcp
  # shellcheck disable=SC2317
  function mockedTcp() {
    echo "mocked $*"
  }
  export -f mockedTcp
  stub timeout "-t 1 ${binDir}/waitForIt localhost 8888 --timeout 1 --lax --algo whileLoopWithTcp echo success : \
    ${binDir}/waitForIt localhost 8888 --timeout 1 --lax --algo whileLoopWithTcp echo success"
  run "${binDir}/waitForIt" localhost 8888 --timeout 1 --lax --algo whileLoopWithTcp echo "success" 2>&1

  assert_success
  assert_line --index 0 --partial "INFO    - waitForIt - using algorithm whileLoopWithTcp"
  assert_line --index 1 --partial "INFO    - waitForIt - waiting 1 seconds for localhost:8888"
  assert_line --index 2 "mocked /dev/tcp/localhost/8888"
  assert_line --index 3 --partial "INFO    - waitForIt - localhost:8888 is available after "
  assert_line --index 4 "success"
  assert_lines_count 5
}

function Utils::waitForIt::algo::whileLoopWithTcp::NoCommandExecutedIfFailed { #@test
  export WAIT_FOR_IT_MOCKED_TCP=mockedTcp
  # shellcheck disable=SC2317
  function mockedTcp() {
    return 1
  }
  export -f mockedTcp
  run "${binDir}/waitForIt" localhost 8888 --timeout 1 --algo whileLoopWithTcp echo "success" 2>&1

  assert_failure 2
  assert_line --index 0 --partial "INFO    - waitForIt - using algorithm whileLoopWithTcp"
  assert_line --index 1 --partial "INFO    - waitForIt - waiting 1 seconds for localhost:8888"
  assert_line --index 2 --partial "ERROR   - waitForIt - timeout for localhost:8888 occurred after "
  assert_line --index 3 --partial "ERROR   - waitForIt - failed to connect - strict mode - command not executed"
  assert_lines_count 4
}

function Utils::waitForIt::algo::whileLoopWithNc::WithoutCommand { #@test
  (
    echo "#!/usr/bin/env bash"
    echo 'exit 0'
  ) >"${HOME}/bin/nc"
  chmod +x "${HOME}/bin/nc"
  run "${binDir}/waitForIt" localhost 8888 --timeout 1 --lax --algo whileLoopWithNc 2>&1

  assert_success
  assert_line --index 0 --partial "INFO    - waitForIt - using algorithm whileLoopWithNc"
  assert_line --index 1 --partial "INFO    - waitForIt - waiting 1 seconds for localhost:8888"
  assert_line --index 2 --partial "INFO    - waitForIt - localhost:8888 is available after "
  assert_lines_count 3
}

function Utils::waitForIt::algo::whileLoopWithNc::ExecCommand { #@test
  (
    echo "#!/usr/bin/env bash"
    echo 'exit 0'
  ) >"${HOME}/bin/nc"
  chmod +x "${HOME}/bin/nc"
  run "${binDir}/waitForIt" localhost 8888 --timeout 1 --lax --algo whileLoopWithNc echo "success" 2>&1

  assert_success
  assert_line --index 0 --partial "INFO    - waitForIt - using algorithm whileLoopWithNc"
  assert_line --index 1 --partial "INFO    - waitForIt - waiting 1 seconds for localhost:8888"
  assert_line --index 2 --partial "INFO    - waitForIt - localhost:8888 is available after "
  assert_line --index 3 "success"
  assert_lines_count 4
}

function Utils::waitForIt::algo::whileLoopWithNc::NoCommandExecutedIfFailed { #@test
  (
    echo "#!/usr/bin/env bash"
    echo 'exit 1'
  ) >"${HOME}/bin/nc"
  chmod +x "${HOME}/bin/nc"
  run "${binDir}/waitForIt" localhost 8888 --timeout 1 --algo whileLoopWithNc echo "success" 2>&1

  assert_failure 2
  assert_line --index 0 --partial "INFO    - waitForIt - using algorithm whileLoopWithNc"
  assert_line --index 1 --partial "INFO    - waitForIt - waiting 1 seconds for localhost:8888"
  assert_line --index 2 --partial "ERROR   - waitForIt - timeout for localhost:8888 occurred after "
  assert_line --index 3 --partial "ERROR   - waitForIt - failed to connect - strict mode - command not executed"
  assert_lines_count 4
}
