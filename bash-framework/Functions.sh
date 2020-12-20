#!/usr/bin/env bash

# Public: check if command specified exists or exits
# with error and message if not
#
# **Arguments**:
# * $1 commandName on which existence must be checked
# * $2 helpIfNotExists a help command to display if the command does not exist
#
# **Exit**: code 1 if the command specified does not exist
Functions::checkCommandExists() {
    local commandName="$1"
    local helpIfNotExists="$2"

    command -v "${commandName}" >/dev/null 2>&1 || {
        Log::displayError "${commandName} is not installed, please install it"
        if [[ -n "${helpIfNotExists}" ]]; then
            Log::displayInfo "${helpIfNotExists}"
        fi
        exit 1
    }
}

# Public: determine if the script is executed under windows
# <pre>
# uname GitBash windows (with wsl) => MINGW64_NT-10.0 ZOXFL-6619QN2 2.10.0(0.325/5/3) 2018-06-13 23:34 x86_64 Msys
# uname GitBash windows (wo wsl)   => MINGW64_NT-10.0 frsa02-j5cbkc2 2.9.0(0.318/5/3) 2018-01-12 23:37 x86_64 Msys
# uname wsl => Linux ZOXFL-6619QN2 4.4.0-17134-Microsoft #112-Microsoft Thu Jun 07 22:57:00 PST 2018 x86_64 x86_64 x86_64 GNU/Linux
# </pre>
#
# **Echo**: "1" if windows, else "0"
Functions::isWindows() {
    if [[ "$(uname -o)" = "Msys" ]]; then
        echo "1"
    else
        echo "0"
    fi
}

# Public: check if hostname exists by pinging it
# with error and message if not
#
# **Arguments**:
# * $1 is the dns hostname
#
# **Return**:
## * 0 if OK
## * 1 => fail to call ping
## * 2 => fail to call ipconfig/ifconfig
## * 3 => host doesn't resolve to local ip address
## * other ping error codes possible
Functions::checkDnsHostname() {
    local host="$1"
    if [[ -z "${host}" ]]; then
        return 1
    fi

    # check if host is reachable
    local returnCode=0
    if [[ "$(Functions::isWindows)" = "1" ]]; then
        COMMAND_OUTPUT=$(ping -4 -n 1 "${host}" 2>&1)
        returnCode=$?
    else
        COMMAND_OUTPUT=$(ping -c 1 "${host}" 2>&1)
        returnCode=$?
    fi

    if [[ "${returnCode}" = "0" ]]; then
        # get ip from ping outputcallCommandSafely
        # under windows: Pinging willywonka.fchastanet.lan [127.0.0.1] with 32 bytes of data
        # under linux: PING willywonka.fchastanet.lan (127.0.1.1) 56(84) bytes of data.
        local ip
        ip=$(echo "${COMMAND_OUTPUT}" | grep -i ping | grep -Eo '[0-9.]{4,}' | head -1)

        # now we have to check if ip is bound to local ip address
        if [[ ${ip} != 127.0.* ]]; then
            # resolve to a non local address
            # check if ip resolve to our ips
            Log::displayInfo "check if ip(${ip}) associated to host(${host}) is listed in your network configuration"
            if [[ "$(Functions::isWindows)" = "1" ]]; then
                COMMAND_OUTPUT=$(ipconfig 2>&1 | grep "${ip}" | cat )
                returnCode=$?
            else
                COMMAND_OUTPUT=$(ifconfig 2>&1 | grep "${ip}" | cat )
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

# Public: quote a string
# replace ' with \'
#
# **Arguments**:
# * $1 the string to quote
#
# **Output**: the string quoted
Functions::quote() {
    local quoted=${1//\'/\'\\\'\'};
    printf "'%s'" "$quoted"
}

# Public: list files of dir with given extension and display it as a list one by line
#
# **Arguments**:
# * $1 the directory to list
# * $2 the extension (eg: sh)
# * $3 the indentation ('       - ' by default) can be any string compatible with sed not containing any /
# **Output**: list of files without extension/directory
# eg:
#       - default.local
#       - default.remote
#       - localhost-root
Functions::getList() {
    DIR="$1"
    EXT="$2"
    INDENT_STR="${3:-       - }"

    (
        cd "${DIR}" && find . -type f -name "*.${EXT}" | sort | sed 's#^./##g' | sed "s/\.${EXT}\$//g" | sed "s/^/${INDENT_STR}/"
    )
}