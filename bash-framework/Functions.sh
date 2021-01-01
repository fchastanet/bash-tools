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
# * $2 the extension (default: sh)
# * $3 the indentation ('       - ' by default) can be any string compatible with sed not containing any /
# **Output**: list of files without extension/directory
# eg:
#       - default.local
#       - default.remote
#       - localhost-root
Functions::getList() {
    local DIR="$1"
    local EXT="${2:-sh}"
    local INDENT_STR="${3:-       - }"

    local extension="${EXT}"
    if  [[ -n "${EXT}" && "${EXT:0:1}" != "." ]]; then
      extension=".${EXT}"
    fi

    (
        cd "${DIR}" && find . -type f -name "*${extension}" | sort | sed 's#^./##g' | sed "s/\.${EXT}\$//g" | sed "s/^/${INDENT_STR}/"
    )
}

# Public: get absolute file from name deduced using these rules
#   * using absolute/relative <conf> file (ignores <confFolder> and <extension>
#   * from home/.bash-tools/<confFolder>/<conf><extension> file
#   * from framework conf/<conf><extension> file
# 
# **Arguments**:
# * $1 confFolder to use below bash-tools conf folder
# * $2 conf file to use without extension
# * $3 file extension to use (default: sh)
#
# Returns 1 if file not found or error during file loading
Functions::loadConf() {
  local confFolder="$1"
  local conf="$2"
  local extension="${3:-sh}"
  local confFile=""

  if  [[ -n "${extension}" && "${extension:0:1}" != "." ]]; then
    extension=".${extension}"
  fi

  # if conf is absolute
  if [[ "${conf}" == /* ]]; then
    # file contains /, consider it as absolute filename
    confFile="${conf}"
  else
    # shellcheck source=/conf/dsn/default.local.env
    confFile="${HOME}/.bash-tools/${confFolder}/${conf}${extension}"
    if [ ! -f "${confFile}" ]; then
      confFile="${__BASH_FRAMEWORK_VENDOR_PATH:?}/conf/${confFolder}/${conf}${extension}"
    fi
  fi
  if [ ! -f "${confFile}" ]; then
    return 1
  fi
  # shellcheck disable=SC1090
  source "${confFile}"
}

# Public: list the conf files list available in bash-tools/conf/<conf> folder
# and those overriden in $HOME/.bash-tools/<conf> folder
# **Arguments**:
# * $1 confFolder the directory name (not the path) to list
# * $2 the extension (sh by default)
# * $3 the indentation ('       - ' by default) can be any string compatible with sed not containing any /
#
# **Output**: list of files without extension/directory
# eg:
#       - default.local
#       - default.remote
#       - localhost-root
Functions::getConfMergedList() {
    local confFolder="$1"
    local extension="${2:-sh}"
    local indentStr="${3:-       - }"
    
    DEFAULT_CONF_DIR="${__BASH_FRAMEWORK_VENDOR_PATH:?}/conf/${confFolder}"
    HOME_CONF_DIR="${HOME}/.bash-tools/${confFolder}"
    
    (
        Functions::getList "${DEFAULT_CONF_DIR}" "${extension}" "${indentStr}"
        Functions::getList "${HOME_CONF_DIR}" "${extension}" "${indentStr}"
    ) | sort | uniq
}

# Public: get absolute conf file from specified conf folder deduced using these rules
#   * from absolute file (ignores <confFolder> and <extension>)
#   * relative to where script is executed (ignores <confFolder> and <extension>)
#   * from home/.bash-tools/<confFolder>
#   * from framework conf/<confFolder>
#
# **Arguments**:
# * $1 confFolder the directory name (not the path) to list
# * $2 conf file to use without extension
# * $3 the extension (sh by default)
#
# Returns absolute conf filename
Functions::getAbsoluteConfFile() {
  local confFolder="$1"
  local conf="$2"
  local extension="${3-.sh}"
  local absoluteConfFile=""

  # load conf from absolute file, then home folder, then bash framework conf folder
  absoluteConfFile="${conf}"
  if [[ "${absoluteConfFile:0:1}" = "/" && -f "${absoluteConfFile}" ]]; then
    # file contains /, consider it as absolute filename
    echo "${absoluteConfFile}"
    return 0
  fi
  
  # relative to where script is executed
  absoluteConfFile="$(realpath "${__BASH_FRAMEWORK_CALLING_SCRIPT}/${conf}" 2>/dev/null || echo "")"
  if [ -f "${absoluteConfFile}" ]; then
    echo "${absoluteConfFile}"
    return 0
  fi

  # take extension into account
  if  [[ -n "${extension}" && "${extension:0:1}" != "." ]]; then
    extension=".${extension}"
  fi

  # shellcheck source=/conf/dsn/default.local.env
  absoluteConfFile="${HOME}/.bash-tools/${confFolder}/${conf}${extension}"
  if [ -f "${absoluteConfFile}" ]; then
    echo "${absoluteConfFile}"
    return 0
  fi
  absoluteConfFile="${__BASH_FRAMEWORK_VENDOR_PATH:?}/conf/${confFolder}/${conf}${extension}"
  if [ -f "${absoluteConfFile}" ]; then
    echo "${absoluteConfFile}"
    return 0
  fi

  # file not found
  Log::displayError "conf file '${conf}' not found"
  return 1    
}


# appends a command to a trap
#
# - 1st arg:  code to add
# - remaining args:  names of traps to modify
#
Functions::trapAdd() {
    local trapAddCmd="$1" 
    shift || Log::fatal "${FUNCNAME[0]} usage error"
    # helper fn to get existing trap command from output
    # of trap -p
    extract_trap_cmd() { printf '%s\n' "$3"; }
    for trapAddName in "$@"; do
        trap -- "$(
            # print existing trap command with newline
            eval "extract_trap_cmd $(trap -p "${trapAddName}")"
            # print the new trap command
            printf '%s\n' "${trapAddCmd}"
        )" "${trapAddName}" \
            || Log::fatal "unable to add to trap ${trapAddName}"
    done
}