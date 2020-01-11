#!/usr/bin/env bash

#---
## exit with code 1 if the command specified does not exist
## @param $1 commandName on which existence must be checked
## @param $2 helpIfNotExists a help command to display if the command does not exist
#---
Functions::checkCommandExists() {
    local commandName="$1"
    local helpIfNotExists="$2"

    Log::displayInfo "check ${commandName} version"
    which ${commandName} >/dev/null 2>/dev/null || {
        Log::displayError "${commandName} is not installed, please install it"
        if [[ ! -z "${helpIfNotExists}" ]]; then
            Log::displayInfo "${helpIfNotExists}"
        fi
        exit 1
    }
}

#---
## echo "1" if on windows system, else "0"
## uname GitBash windows (with wsl) => MINGW64_NT-10.0 ZOXFL-6619QN2 2.10.0(0.325/5/3) 2018-06-13 23:34 x86_64 Msys
## uname GitBash windows (wo wsl)   => MINGW64_NT-10.0 frsa02-j5cbkc2 2.9.0(0.318/5/3) 2018-01-12 23:37 x86_64 Msys
## uname wsl => Linux ZOXFL-6619QN2 4.4.0-17134-Microsoft #112-Microsoft Thu Jun 07 22:57:00 PST 2018 x86_64 x86_64 x86_64 GNU/Linux
#---
Functions::isWindows() {
    if [[ "$(uname -o)" = "Msys" ]]; then
        echo "1"
    else
        echo "0"
    fi
}

#---
## try to ping the dns
##² @param $1 is the dns hostname
## @return 0 if OK
## @return 1 => fail to call ping
## @return 2 => fail to call ipconfig/ifconfig
## @return 3 => host doesn't resolve to local ip address
## else unknown error";;
#---
Functions::checkDnsHostname() {
    local host="$1"
    if [[ -z "${host}" ]]; then
        return 1
    fi

    # check if host is reachable
    local returnCode=0
    if [[ "$(Functions::isWindows)" = "1" ]]; then
        COMMAND_OUTPUT=$(ping -4 -n 1 ${host} 2>&1)
        returnCode=$?
    else
        COMMAND_OUTPUT=$(ping -c 1 ${host} 2>&1)
        returnCode=$?
    fi

    if [[ "${returnCode}" = "0" ]]; then
        # get ip from ping outputcallCommandSafely
        # under windows: Pinging willywonka.fchastanet.lan [127.0.0.1] with 32 bytes of data
        # under linux: PING willywonka.fchastanet.lan (127.0.1.1) 56(84) bytes of data.
        local ip
        ip=$(echo ${COMMAND_OUTPUT} | grep -i ping | grep -Eo '[0-9.]{4,}' | head -1)

        # now we have to check if ip is bound to local ip address
        if [[ ${ip} != 127.0.* ]]; then
            # resolve to a non local address
            # check if ip resolve to our ips
            Log::displayInfo "check if ip(${ip}) associated to host(${host}) is listed in your network configuration"
            if [[ "$(Functions::isWindows)" = "1" ]]; then
                COMMAND_OUTPUT=$(ipconfig 2>&1 | grep ${ip} | cat )
                returnCode=$?
            else
                COMMAND_OUTPUT=$(ifconfig 2>&1 | grep ${ip} | cat )
                returnCode=$?
            fi
            if [[ "${returnCode}" != "0" ]]; then
                returnCode=2
            elif [[ -z "${COMMAND_OUTPUT}" ]]; then
                returnCode=3
            fi
        fi
    fi

    return ${returnCode}
}

Functions::quote() {
    local quoted=${1//\'/\'\\\'\'};
    printf "'%s'" "$quoted"
}
