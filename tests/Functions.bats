#!/usr/bin/env bash

load '../vendor/bats-support/load'
load '../vendor/bats-assert/load'

# shellcheck source=bash-framework/_bootstrap.sh
__bash_framework_envFile="" source "$(cd "$( readlink -e "${BATS_TEST_DIRNAME}/..")" && pwd)/bash-framework/_bootstrap.sh" || exit 1

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
    unalias uname
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

    [[ "$(Functions::checkDnsHostname "willywonka.fchastanet.lan" && echo "0" || echo "$?")" = "0" ]]

    unalias uname
    unalias ping
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
    Functions::checkDnsHostname "willywonka.fchastanet.lan"
    [[ "$?" = "0" ]]

    unalias uname
    unalias ping
    unalias ifconfig
}

@test "Functions::checkCommandExists exists" {
    (
        Functions::checkCommandExists bash
    ) && exitStatus=$? && true
    [[ "${exitStatus}" = "0" ]]
}

@test "Functions::checkCommandExists not exists" {
    (
        Functions::checkCommandExists dsfdsfsd
    ) || exitStatus=$? && true
    [[ "${exitStatus}" = "1" ]]
}
