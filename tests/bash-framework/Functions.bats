#!/usr/bin/env bash

FRAMEWORK_DIR="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"

# shellcheck source=bash-framework/_bootstrap.sh
__BASH_FRAMEWORK_ENV_FILEPATH="" source "${FRAMEWORK_DIR}/bash-framework/_bootstrap.sh" || exit 1
import bash-framework/Functions
load "${FRAMEWORK_DIR}/vendor/bats-mock-Flamefire/load.bash"

setup() {    
    mkdir -p /tmp/home/.bash-tools/cliProfiles
    mkdir -p /tmp/home/.bash-tools/dsn
    cp -v ${FRAMEWORK_DIR}/conf/cliProfiles/default.sh /tmp/home/.bash-tools/cliProfiles
}

teardown() {
    rm -Rf /tmp/home || true 
    unstub_all
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
    [[ "${finalContainerArg}" = "project-apache2" ]]  
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::loadConf default" {
    Functions::loadConf "cliProfiles" "default"
    [[ "${finalUserArg}" = "www-data" ]]
    [[ "${finalCommandArg}" = "//bin/bash" ]]
    [[ "${finalContainerArg}" = "project-apache2" ]]  
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::loadConf dsn" {
    Functions::loadConf "dsn" "default.local" ".env"
    [[ "${HOSTNAME}" = "127.0.0.1" ]]
    [[ "${USER}" = "root" ]]
    [[ "${PASSWORD}" = "root" ]]  
    [[ "${PORT}" = "3306" ]]  
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::loadConf file not found" {
    run Functions::loadConf "dsn" "not found" ".sh"
    [ "$status" -eq 1 ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::getConfMergedList" {
    cp -v ${FRAMEWORK_DIR}/conf/dsn/* /tmp/home/.bash-tools/dsn
    touch /tmp/home/.bash-tools/dsn/dsn_invalid_port.env
    touch /tmp/home/.bash-tools/dsn/otherInvalidExt.ext
    touch /tmp/home/.bash-tools/dsn/otherInvalidExt2.sh
    export HOME=/tmp/home
    run Functions::getConfMergedList "dsn" "env"
    [ "$(cat "${BATS_TEST_DIRNAME}/data/database.dsnList1")" = "${output}" ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::getAbsoluteConfFile env file from home" {
    touch /tmp/home/.bash-tools/dsn/dsn_invalid_port.env
    export HOME=/tmp/home

    run Functions::getAbsoluteConfFile "dsn" "dsn_invalid_port" "env"
    [ "$status" -eq 0 ]
    [ "/tmp/home/.bash-tools/dsn/dsn_invalid_port.env" = "${output}" ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::getAbsoluteConfFile sh file from home default extension" {
    touch /tmp/home/.bash-tools/dsn/otherInvalidExt2.sh
    export HOME=/tmp/home

    run Functions::getAbsoluteConfFile "dsn" "otherInvalidExt2"
    [ "$status" -eq 0 ]
    [ "/tmp/home/.bash-tools/dsn/otherInvalidExt2.sh" = "${output}" ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::getAbsoluteConfFile file default in bash-framework conf folder" {
    export HOME=/tmp/home

    run Functions::getAbsoluteConfFile "dsn" "default.local" "env"
    [ "$status" -eq 0 ]
    [ "${FRAMEWORK_DIR}/conf/dsn/default.local.env" = "${output}" ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::getAbsoluteConfFile relative file" {
    mkdir -p /tmp/home/.bash-tools/data
    touch /tmp/home/.bash-tools/data/dsn_valid.env
    export HOME=/tmp/home

    run Functions::getAbsoluteConfFile "data" "../../../../tests/bash-framework/data/dsn_valid.env" "sh"

    [ "$status" -eq 0 ]
    [ "${BATS_TEST_DIRNAME}/data/dsn_valid.env" = "${output}" ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::getAbsoluteConfFile absolute file 1 (ignores confFolder and ext)" {
    touch /tmp/home/.bash-tools/dsn/otherInvalidExt.ext
    export HOME=/tmp/home

    run Functions::getAbsoluteConfFile "data" "/tmp/home/.bash-tools/dsn/otherInvalidExt.ext" "sh"
    [ "$status" -eq 0 ]
    [ "/tmp/home/.bash-tools/dsn/otherInvalidExt.ext" = "${output}" ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::getAbsoluteConfFile absolute file 2 (ignores confFolder and ext)" {
    touch /tmp/home/.bash-tools/dsn/dsn_invalid_port.sh
    export HOME=/tmp/home

    run Functions::getAbsoluteConfFile "data" "/tmp/home/.bash-tools/dsn/dsn_invalid_port.sh" "env"
    [ "$status" -eq 0 ]
    [ "/tmp/home/.bash-tools/dsn/dsn_invalid_port.sh" = "${output}" ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::getAbsoluteConfFile absolute file 3 (ignores confFolder and ext)" {
    touch /tmp/home/.bash-tools/dsn/otherInvalidExt2.sh
    export HOME=/tmp/home

    run Functions::getAbsoluteConfFile "data" "/tmp/home/.bash-tools/dsn/otherInvalidExt2.sh" "env"
    [ "$status" -eq 0 ]
    [ "/tmp/home/.bash-tools/dsn/otherInvalidExt2.sh" = "${output}" ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::getAbsoluteConfFile file without extension" {
    touch /tmp/home/.bash-tools/dsn/noExtension
    export HOME=/tmp/home

    run Functions::getAbsoluteConfFile "dsn" "noExtension" ""
    [ "$status" -eq 0 ]
    [ "/tmp/home/.bash-tools/dsn/noExtension" = "${output}" ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::getAbsoluteConfFile file not found" {
    touch /tmp/home/.bash-tools/dsn/otherInvalidExt2.sh
    export HOME=/tmp/home

    run Functions::getAbsoluteConfFile "dsn" "invalidFile" "env"
    [ "$status" -eq 1 ]
    [[ "${output}" == *"conf file 'invalidFile' not found"* ]]
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

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::run status 0" {
    stub date \
        '* : echo 1609970133' \
        '* : echo 1609970134'
    
    Functions::run echo 'coucou' 2>/tmp/home/error
    [ "${bash_framework_status}" -eq 0 ]
    [ "${bash_framework_duration}" = "1" ]
    [ "${bash_framework_output}" = "coucou" ]
    [ "$(cat /tmp/home/error)" = "" ]
}

@test "${BATS_TEST_FILENAME#/bash/tests/} Functions::run status 1" {
    stub date \
        '* : echo 1609970133' \
        '* : echo 1609970134'

    Functions::run cat 'unknownFile' 2>/tmp/home/error
    
    [ "${bash_framework_status}" -eq 1 ]
    [ "${bash_framework_duration}" = "1" ]
    [ "${bash_framework_output}" = "" ]
    [[ "$(cat /tmp/home/error)" == *"cat: "* ]]
    [[ "$(cat /tmp/home/error)" == *"unknownFile"* ]]
    [[ "$(cat /tmp/home/error)" == *": No such file or directory" ]]
}
