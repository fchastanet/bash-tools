#!/usr/bin/env bash

FRAMEWORK_DIR="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
# shellcheck source=bash-framework/_bootstrap.sh
__bash_framework_envFile="" source "${FRAMEWORK_DIR}/bash-framework/_bootstrap.sh" || exit 1

import bash-framework/Functions

setup() {    
    mkdir -p /tmp/home/.bash-tools/cliProfiles
    mkdir -p /tmp/home/.bash-tools/dsn
    cp -v ${FRAMEWORK_DIR}/conf/cliProfiles/default.sh /tmp/home/.bash-tools/cliProfiles
}

teardown() {
    rm -Rf /tmp/home || true 
}

@test "${BATS_TEST_FILENAME#/bash/tests/} framework is loaded" {
    [[ "${BASH_FRAMEWORK_INITIALIZED}" = "1" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::isWindows" {
    unameMocked() {
        echo "Msys"
    }
    alias uname="unameMocked"

    [[ "$(Functions::isWindows)" = "1" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::checkDnsHostname localhost" {
    unameMocked() {
        echo "Linux"
    }
    alias uname="unameMocked"

    pingMocked() {
        echo "PING willywonka.fchastanet.lan (127.0.1.1) 56(84) bytes of data."
        return 0
    }
    alias ping="pingMocked"

    if ! Functions::checkDnsHostname "willywonka.fchastanet.lan"; then
        false
    fi
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::checkDnsHostname external host" {
    unameMocked() {
        echo "Linux"
    }
    alias uname="unameMocked"

    pingMocked() {
        echo "PING willywonka.fchastanet.lan (192.168.1.1) 56(84) bytes of data."
        return 0
    }
    alias ping="pingMocked"

    ifconfigMocked() {
        echo "eth4: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500"
        echo "inet 192.168.1.1  netmask 255.255.0.0  broadcast 192.168.255.255"
        return 0
    }
    alias ifconfig="ifconfigMocked"
    Functions::checkDnsHostname "willywonka.fchastanet.lan" || false
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::checkCommandExists exists" {
   (Functions::checkCommandExists "bash") || false
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::checkCommandExists not exists" {
    run Functions::checkCommandExists "qsfdsfds"
    [[ "$status" -eq 1 ]]
    (>&2 echo $(env) )
    [[ "${lines[0]}" = "$(echo -e "${__ERROR_COLOR}ERROR - qsfdsfds is not installed, please install it${__RESET_COLOR}")" ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::getList" {
    run Functions::getList "${BATS_TEST_DIRNAME}/dataGetList" "sh"
    [[ "$status" -eq 0 ]]
    [[ "${#lines[@]}" = "2" ]]
    [[ "${lines[0]}" = "       - test" ]]
    [[ "${lines[1]}" = "       - test2" ]]

    run Functions::getList "${BATS_TEST_DIRNAME}/dataGetList" "sh" "-"
    [[ "$status" -eq 0 ]]
    [[ "${#lines[@]}" = "2" ]]
    [[ "${lines[0]}" = "-test" ]]
    [[ "${lines[1]}" = "-test2" ]]

    run Functions::getList "${BATS_TEST_DIRNAME}/dataGetList" "dsn" "*"
    [[ "$status" -eq 0 ]]
    [[ "${output}" = "*hello" ]]
    
    run Functions::getList "${BATS_TEST_DIRNAME}/unknown" "sh" "*"
    [[ "$status" -eq 1 ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::loadConf absolute file" {
    Functions::loadConf "anyFolder" "/tmp/home/.bash-tools/cliProfiles/default.sh"
    [[ "${finalUserArg}" = "www-data" ]]
    [[ "${finalCommandArg}" = "//bin/bash" ]]
    [[ "${finalContainerArg}" = "ckls-apache2" ]]  
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::loadConf default" {
    Functions::loadConf "cliProfiles" "default"
    [[ "${finalUserArg}" = "www-data" ]]
    [[ "${finalCommandArg}" = "//bin/bash" ]]
    [[ "${finalContainerArg}" = "ckls-apache2" ]]  
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::loadConf dsn" {
    Functions::loadConf "dsn" "default.local" ".env"
    [[ "${HOSTNAME}" = "127.0.0.1" ]]
    [[ "${USER}" = "root" ]]
    [[ "${PASSWORD}" = "root" ]]  
    [[ "${PORT}" = "3306" ]]  
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::loadConf file not found" {
    run Functions::loadConf "dsn" "default.local" ".sh"
    [ "$status" -eq 1 ]
    [[ "${output}" == *"conf file 'default.local' not found under 'dsn' using extension '.sh'"* ]]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::getConfMergedList" {
    cp -v ${FRAMEWORK_DIR}/conf/dsn/* /tmp/home/.bash-tools/dsn
    touch /tmp/home/.bash-tools/dsn/dsn_invalid_port.env
    touch /tmp/home/.bash-tools/dsn/otherInvalidExt.ext
    touch /tmp/home/.bash-tools/dsn/otherInvalidExt2.sh
    output="$(HOME=/tmp/home Functions::getConfMergedList "dsn" ".env")"
    [ "$(cat "${BATS_TEST_DIRNAME}/data/database.dsnList1")" = "${output}" ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::trapAdd" {
    trap 'echo "SIGUSR1 original" >> /tmp/home/trap' SIGUSR1
    Functions::trapAdd 'echo "SIGUSR1 overriden" >> /tmp/home/trap' SIGUSR1
    kill -SIGUSR1 $$
    [ "$(cat /tmp/home/trap)" = "$(cat ${BATS_TEST_DIRNAME}/data/Functions_addTrap_expected)" ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::trapAdd 2 events at once" {
    trap 'echo "SIGUSR1 original" >> /tmp/home/trap' SIGUSR1
    trap 'echo "SIGUSR2 original" >> /tmp/home/trap' SIGUSR2
    Functions::trapAdd 'echo "SIGUSR1&2 overriden" >> /tmp/home/trap' SIGUSR1 SIGUSR2
    kill -SIGUSR1 $$
    [ "$(cat /tmp/home/trap)" = "$(cat ${BATS_TEST_DIRNAME}/data/Functions_addTrap2_1_expected)" ]
    rm /tmp/home/trap
    kill -SIGUSR2 $$
    [ "$(cat /tmp/home/trap)" = "$(cat ${BATS_TEST_DIRNAME}/data/Functions_addTrap2_2_expected)" ]
}