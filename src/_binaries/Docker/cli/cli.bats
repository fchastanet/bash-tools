#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)/batsHeaders.sh"

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"

  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}"
  mkdir -p "${HOME}/bin"
  touch "${HOME}/bin/docker"
  chmod +x "${HOME}/bin/"*
  cp -R "${rootDir}/conf" "${HOME}/.bash-tools"
  cp "${rootDir}/conf/defaultEnv/.env" "${HOME}/.bash-tools"

  export PATH="${PATH}:${HOME}/bin"
}

stub_tput() {
  stub tput \
    'cols : echo "80"' \
    'lines : echo "23"'
}

teardown() {
  unstub_all
}

function Docker::cli::display_help { #@test
  testCommand "${binDir}/cli" cli.help.txt
}

function Docker::cli::without_any_parameter_connects_to_default_container { #@test
  stub_tput
  if read -r -t 0; then
    stub docker 'exec -i -e COLUMNS=80 -e LINES=23 --user=www-data project-apache2 /bin/bash : echo "connected to container"'
  else
    stub docker 'exec -it -e COLUMNS=80 -e LINES=23 --user=www-data project-apache2 /bin/bash : echo "connected to container"'
  fi
  run "${binDir}/cli" 2>&1

  assert_success
  assert_line --index 1 "connected to container"
}

function Docker::cli::to_existing_container { #@test
  stub_tput
  if read -r -t 0; then
    stub docker 'exec -i -e COLUMNS=80 -e LINES=23 --user=mysql project-mysql8 //bin/bash -c mysql\ -h127.0.0.1\ -uroot\ -proot\ -P3306 : echo "connected to container"'
  else
    stub docker 'exec -it -e COLUMNS=80 -e LINES=23 --user=mysql project-mysql8 //bin/bash -c mysql\ -h127.0.0.1\ -uroot\ -proot\ -P3306 : echo "connected to container"'
  fi
  run "${binDir}/cli" mysql 2>&1
  assert_success
  assert_line --index 1 "connected to container"
}

function Docker::cli::to_existing_container_override_user { #@test
  stub_tput
  if read -r -t 0; then
    stub docker 'exec -i -e COLUMNS=80 -e LINES=23 --user=user2 project-apache2 //bin/bash : echo "connected to container"'
  else
    stub docker 'exec -it -e COLUMNS=80 -e LINES=23 --user=user2 project-apache2 //bin/bash : echo "connected to container"'
  fi
  run "${binDir}/cli" web user2 2>&1
  assert_success
  assert_line --index 1 "connected to container"
}

function Docker::cli::to_existing_container_override_user_and_command { #@test
  stub_tput
  if read -r -t 0; then
    stub docker 'exec -i -e COLUMNS=80 -e LINES=23 --user=user2 project-apache2 gulp : echo "gulp running"'
  else
    stub docker 'exec -it -e COLUMNS=80 -e LINES=23 --user=user2 project-apache2 gulp : echo "gulp running"'
  fi
  run "${binDir}/cli" web user2 gulp 2>&1
  assert_success
  assert_line --index 1 "gulp running"
}

function Docker::cli::add_a_custom_profile_and_use_this_profile { #@test
  stub_tput
  cp "${BATS_TEST_DIRNAME}/testsData/my-container.sh" "${HOME}/.bash-tools/cliProfiles"
  if read -r -t 0; then
    stub docker 'exec -i -e COLUMNS=80 -e LINES=23 --user=superuser my-container myCommand : echo "connected to container"'
  else
    stub docker 'exec -it -e COLUMNS=80 -e LINES=23 --user=superuser my-container myCommand : echo "connected to container"'
  fi
  run "${binDir}/cli" my-container 2>&1

  assert_success
  assert_line --index 1 "connected to container"
}

function Docker::cli::to_a_container_without_a_matching_profile { #@test
  stub_tput
  if read -r -t 0; then
    stub docker 'exec -i -e COLUMNS=80 -e LINES=23 --user=www-data my-container /bin/bash : echo "connected to container"'
  else
    stub docker 'exec -it -e COLUMNS=80 -e LINES=23 --user=www-data my-container /bin/bash : echo "connected to container"'
  fi
  run "${binDir}/cli" my-container 2>&1

  assert_success
  assert_line --index 1 "connected to container"
}
