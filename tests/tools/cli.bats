#!/usr/bin/env bash

declare -g rootDir="$( cd "${BATS_TEST_DIRNAME}/../.." && pwd )"
declare -g toolsDir="${rootDir}/bin"
declare -g vendorDir="${rootDir}/vendor"

load "${vendorDir}/bats-mock-Flamefire/load.bash"

setup() {
    export HOME="/tmp/home"
    (
        mkdir -p "${HOME}" 
        cd "${HOME}"
        mkdir -p bin 
        touch bin/docker
        chmod +x bin/*
        cp -R ${rootDir}/conf .bash-tools
    )
    export PATH="$PATH:/tmp/home/bin"
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

@test "${BATS_TEST_FILENAME#/bash/tests/} display help" {
    run ${toolsDir}/cli --help 2>&1
    [ "$status" -eq 0 ]
    [[ "${output}" == *"Description: easy connection to docker container"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} without any parameter connects to default container" {
    stub_tput
    stub docker 'exec -it -e COLUMNS=80 -e LINES=23 --user=www-data project-apache2 //bin/bash : echo "connected to container"'
    run ${toolsDir}/cli 2>&1
    [ "$status" -eq 0 ]
    [[ "${lines[1]}" = "connected to container" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} to existing container" {
    stub_tput
    stub docker 'exec -it -e COLUMNS=80 -e LINES=23 --user=mysql project-mysql8 //bin/bash -c mysql\ -h127.0.0.1\ -uroot\ -proot\ -P3306 : echo "connected to container"'
    run ${toolsDir}/cli mysql 2>&1
    [ "$status" -eq 0 ]
    [[ "${lines[1]}" = "connected to container" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} to existing container override user" {
    stub_tput
    stub docker 'exec -it -e COLUMNS=80 -e LINES=23 --user=user2 project-apache2 //bin/bash : echo "connected to container"'
    run ${toolsDir}/cli web user2 2>&1
    [ "$status" -eq 0 ]
    [[ "${lines[1]}" = "connected to container" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} to existing container override user and command" {
    stub_tput
    stub docker 'exec -it -e COLUMNS=80 -e LINES=23 --user=user2 project-apache2 gulp : echo "gulp running"'
    run ${toolsDir}/cli web user2 gulp 2>&1
    [ "$status" -eq 0 ]
    [[ "${lines[1]}" = "gulp running" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} add a custom profile and use this profile" {
    stub_tput
    cp ${BATS_TEST_DIRNAME}/data/my-container.sh "${HOME}/.bash-tools/cliProfiles"
    stub docker 'exec -it -e COLUMNS=80 -e LINES=23 --user=superuser my-container mycommand : echo "connected to container"'
    run ${toolsDir}/cli my-container 2>&1
    [ "$status" -eq 0 ]
    [[ "${lines[1]}" = "connected to container" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} to a container without a matching profile" {
    stub_tput
    stub docker 'exec -it -e COLUMNS=80 -e LINES=23 --user=www-data my-container //bin/bash : echo "connected to container"'
    run ${toolsDir}/cli my-container 2>&1
    [ "$status" -eq 0 ]
    [[ "${lines[1]}" = "connected to container" ]]
}
