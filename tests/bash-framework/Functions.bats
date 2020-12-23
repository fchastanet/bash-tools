#!/usr/bin/env bash

# shellcheck source=bash-framework/_bootstrap.sh
__bash_framework_envFile="" source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/_bootstrap.sh" || exit 1

import bash-framework/Functions

@test "framework is loaded" {
    [[ "${BASH_FRAMEWORK_INITIALIZED}" = "1" ]]
}

@test "Functions::isWindows" {
    unameMocked() {
        echo "Msys"
    }
    alias uname="unameMocked"

    [[ "$(Functions::isWindows)" = "1" ]]
}

@test "Functions::checkDnsHostname localhost" {
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

@test "Functions::checkDnsHostname external host" {
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

@test "Functions::checkCommandExists exists" {
   (Functions::checkCommandExists "bash") || false
}

@test "Functions::checkCommandExists not exists" {
    run Functions::checkCommandExists "qsfdsfds"
    [[ "$status" -eq 1 ]]
    (>&2 echo $(env) )
    [[ "${lines[0]}" = "$(echo -e "${__ERROR_COLOR}ERROR - qsfdsfds is not installed, please install it${__RESET_COLOR}")" ]]
}

@test "Functions::getList" {
    run Functions::getList "${BATS_TEST_DIRNAME}/dataGetList" "sh"
    (>&3 echo "$output")
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
