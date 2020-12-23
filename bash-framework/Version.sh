#!/usr/bin/env bash

# shellcheck source=bash-framework/Functions.sh
import bash-framework/Functions
# shellcheck source=bash-framework/Log.sh
import bash-framework/Log

# Public: ensure that command exists with expected version
#
# **Arguments**:
# * $1 command name
# * $2 the command to execute to retrieve the version
# * $3 the expected command version
#
# **Output**:
# * Warning message : ${commandName} version is ${version} greater than ${minimalVersion}, OK let's continue
# * Error message : ${commandName} minimal version is ${minimalVersion}, your version is ${version}
#
# **Exit**:
# * code 2 and error message if command exists but current version is less than expected minimal version
Version::checkMinimal() {
    local commandName="$1"
    local commandVersion="$2"
    local minimalVersion="$3"

    Functions::checkCommandExists "${commandName}"

    local version
    version=$(${commandVersion} | sed -nre 's/^[^0-9]*(([0-9]+\.)*[0-9]+).*/\1/p')

    Log::displayDebug "check ${commandName} version ${version} against minimal ${minimalVersion}"

    Version::compare "${version}" "${minimalVersion}" || {
        local result=$?
        if [[ "${result}" = "1" ]]; then
            Log::displayWarning "${commandName} version is ${version} greater than ${minimalVersion}, OK let's continue"
        elif [[ "${result}" = "2" ]]; then
            Log::fatal"${commandName} minimal version is ${minimalVersion}, your version is ${version}"
        fi
    }

}

# Public: compare version
#
# **Arguments**:
# * $1 ersion 1
# * $2 version 2
#
# **Return**:
# * 0 if equal
# * 1 if version1 > version2
# * 2 else
Version::compare() {
    if [[ "$1" = "$2" ]]
    then
        return 0
    fi
    local IFS=.
    # shellcheck disable=2206
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z "${ver2[i]+unset}" ]] || [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}
