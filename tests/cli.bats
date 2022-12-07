#!/usr/bin/env bash

rootDir="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
toolsDir="${rootDir}/bin"
vendorDir="${rootDir}/vendor"

# shellcheck source=bash-framework/Constants.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/Constants.sh" || exit 1

load "${vendorDir}/bats-mock-Flamefire/load.bash"

setup() {
  export HOME="/tmp/home"
  (
    mkdir -p "${HOME}"
    cd "${HOME}" || exit 1
    mkdir -p bin
    touch bin/docker
    chmod +x bin/*
    cp -R "${rootDir}/conf" .bash-tools
  )
  export PATH="${PATH}:/tmp/home/bin"
}

stub_tput() {
  stub tput \
    'cols : echo "80"' \
    'lines : echo "23"'
}

teardown() {
  rm -Rf /tmp/home || true
  unstub_all
}

function display_help { #@test
  run "${toolsDir}/cli" --help 2>&1
  # shellcheck disable=SC2154
  [[ "${status}" -eq 0 ]]
  # shellcheck disable=SC2154
  [[ "${lines[0]}" == "${__HELP_TITLE}Description:${__HELP_NORMAL} easy connection to docker container" ]]
}

function without_any_parameter_connects_to_default_container { #@test
  stub_tput
  if read -r -t 0; then
    stub docker 'exec -i -e COLUMNS=80 -e LINES=23 --user=www-data project-apache2 //bin/bash : echo "connected to container"'
  else
    stub docker 'exec -it -e COLUMNS=80 -e LINES=23 --user=www-data project-apache2 //bin/bash : echo "connected to container"'
  fi
  run "${toolsDir}/cli" 2>&1

  [[ "${status}" -eq 0 ]]
  [[ "${lines[1]}" = "connected to container" ]]
}

function to_existing_container { #@test
  stub_tput
  if read -r -t 0; then
    stub docker 'exec -i -e COLUMNS=80 -e LINES=23 --user=mysql project-mysql8 //bin/bash -c mysql\ -h127.0.0.1\ -uroot\ -proot\ -P3306 : echo "connected to container"'
  else
    stub docker 'exec -it -e COLUMNS=80 -e LINES=23 --user=mysql project-mysql8 //bin/bash -c mysql\ -h127.0.0.1\ -uroot\ -proot\ -P3306 : echo "connected to container"'
  fi
  run "${toolsDir}/cli" mysql 2>&1
  [[ "${status}" -eq 0 ]]
  [[ "${lines[1]}" = "connected to container" ]]
}

function to_existing_container_override_user { #@test
  stub_tput
  if read -r -t 0; then
    stub docker 'exec -i -e COLUMNS=80 -e LINES=23 --user=user2 project-apache2 //bin/bash : echo "connected to container"'
  else
    stub docker 'exec -it -e COLUMNS=80 -e LINES=23 --user=user2 project-apache2 //bin/bash : echo "connected to container"'
  fi
  run "${toolsDir}/cli" web user2 2>&1
  [[ "${status}" -eq 0 ]]
  [[ "${lines[1]}" = "connected to container" ]]
}

function to_existing_container_override_user_and_command { #@test
  stub_tput
  if read -r -t 0; then
    stub docker 'exec -i -e COLUMNS=80 -e LINES=23 --user=user2 project-apache2 gulp : echo "gulp running"'
  else
    stub docker 'exec -it -e COLUMNS=80 -e LINES=23 --user=user2 project-apache2 gulp : echo "gulp running"'
  fi
  run "${toolsDir}/cli" web user2 gulp 2>&1
  [[ "${status}" -eq 0 ]]
  [[ "${lines[1]}" = "gulp running" ]]
}

function add_a_custom_profile_and_use_this_profile { #@test
  stub_tput
  cp "${BATS_TEST_DIRNAME}/data/my-container.sh" "${HOME}/.bash-tools/cliProfiles"
  if read -r -t 0; then
    stub docker 'exec -i -e COLUMNS=80 -e LINES=23 --user=superuser my-container mycommand : echo "connected to container"'
  else
    stub docker 'exec -it -e COLUMNS=80 -e LINES=23 --user=superuser my-container mycommand : echo "connected to container"'
  fi
  run "${toolsDir}/cli" my-container 2>&1
  [[ "${status}" -eq 0 ]]
  [[ "${lines[1]}" = "connected to container" ]]
}

function to_a_container_without_a_matching_profile { #@test
  stub_tput
  if read -r -t 0; then
    stub docker 'exec -i -e COLUMNS=80 -e LINES=23 --user=www-data my-container //bin/bash : echo "connected to container"'
  else
    stub docker 'exec -it -e COLUMNS=80 -e LINES=23 --user=www-data my-container //bin/bash : echo "connected to container"'
  fi
  run "${toolsDir}/cli" my-container 2>&1
  [[ "${status}" -eq 0 ]]
  [[ "${lines[1]}" = "connected to container" ]]
}
