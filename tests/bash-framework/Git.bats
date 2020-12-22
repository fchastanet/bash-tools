#!/usr/bin/env bash

declare -g toolsDir="$( cd "${BATS_TEST_DIRNAME}/../../bin" && pwd )"
declare -g vendorDir="$( cd "${BATS_TEST_DIRNAME}/../../vendor" && pwd )"

# shellcheck source=bash-framework/_bootstrap.sh
__bash_framework_envFile="" source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1
import bash-framework/Git

load "${vendorDir}/bats-mock-Flamefire/load.bash"

setup() {
  mkdir -p /tmp/home
  export HOME="/tmp/home"
}

teardown() {
  rm -Rf "${HOME}" || true
  unstub_all
}


@test "Git::ShallowClone first time" {
    stub git \
        "init : true" \
        "remote add origin https://github.com/fchastanet/fakeRepo.git : true" \
        "-c advice.detachedHead=false fetch --depth 1 origin master : true" \
        "reset --hard FETCH_HEAD : true"
    
    run Git::ShallowClone \
        "https://github.com/fchastanet/fakeRepo.git" \
        "${HOME}/fakeRepo" \
        "master" \
        "0" 2>&1
    
    [[ "$status" = "0" ]]
    [[ "${output}" != *"WARN  - Removing /tmp/home/fakeRepo ..."* ]]
    [[ "${output}" == *"INFO  - Installing /tmp/home/fakeRepo ..."* ]]
}

@test "Git::ShallowClone second time update" {
    mkdir -p "${HOME}/fakeRepo/.git"    
    stub git \
        "-c advice.detachedHead=false fetch --depth 1 origin master : true" \
        "reset --hard FETCH_HEAD : true"
    
    run Git::ShallowClone \
        "https://github.com/fchastanet/fakeRepo.git" \
        "${HOME}/fakeRepo" \
        "master" \
        "0" 2>&1
    
    [[ "$status" = "0" ]]
    [[ "${output}" != *"WARN  - Removing /tmp/home/fakeRepo ..."* ]]
    [[ "${output}" == *"INFO  - Repository ${HOME}/fakeRepo already installed"* ]]
}

@test "Git::ShallowClone on non git folder (not forced)" {
    mkdir -p "${HOME}/fakeRepo"    
    run Git::ShallowClone \
        "https://github.com/fchastanet/fakeRepo.git" \
        "${HOME}/fakeRepo" \
        "master" \
        "0" 2>&1
    
    [[ $status -eq 1 ]]
    [[ "${output}" != *"WARN  - Removing /tmp/home/fakeRepo ..."* ]]
    [[ "${output}" == *"ERROR - Destination ${HOME}/fakeRepo already exists, use force option to automatically delete the destination"* ]]
    # check directory has not been deleted
    [[ -d "${HOME}/fakeRepo" ]]
}

@test "Git::ShallowClone on non git folder (forced)" {
    mkdir -p "${HOME}/fakeRepo"    
    stub git \
        "init : true" \
        "remote add origin https://github.com/fchastanet/fakeRepo.git : true" \
        "-c advice.detachedHead=false fetch --depth 1 origin master : true" \
        "reset --hard FETCH_HEAD : true"

    run Git::ShallowClone \
        "https://github.com/fchastanet/fakeRepo.git" \
        "${HOME}/fakeRepo" \
        "master" \
        "1" 2>&1
    
    [[ "$status" = "0" ]]
    [[ "${output}" == *"WARN  - Removing /tmp/home/fakeRepo ..."* ]]
    [[ "${output}" == *"INFO  - Installing /tmp/home/fakeRepo ..."* ]]
}