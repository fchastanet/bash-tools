#!/usr/bin/env bash
#   Use this script to test if a given TCP host/port are available
#  https://github.com/vishnubob/wait-for-it

# load ckls-bootstrap
# shellcheck source=.dev/vendor/bash-framework/_bootstrap.sh
source "$( cd "$( readlink -f "${BASH_SOURCE[0]%/*}/.." )" && pwd )/vendor/bash-framework/_bootstrap.sh"

cmdName=$(basename $0)

usage()
{
    cat << USAGE >&2
Usage:
    ${cmdName} host:port [-s] [-t timeout] [-- command args]
    -h HOST | --host=HOST       Host or IP under test
    -p PORT | --port=PORT       TCP port under test
                                Alternatively, you specify the host and port as host:port
    -s | --strict               Only execute sub-command if the test succeeds
    -q | --quiet                Don't output any status messages
    -t TIMEOUT | --timeout=TIMEOUT
                                Timeout in seconds, zero for no timeout
    -- COMMAND ARGS             Execute command with args after the test finishes
USAGE
    exit 1
}

wait_for()
{
    local result=0
    if (( ${TIMEOUT} > 0 )); then
        Log::displayInfo "${cmdName}: waiting ${TIMEOUT} seconds for ${HOST}:${PORT}"
    else
        Log::displayInfo "${cmdName}: waiting for ${HOST}:${PORT} without a timeout"
    fi
    local start_ts=${SECONDS}
    while true; do
        result=0
        if [[ "${ISBUSY}" = "1" ]]; then
            (nc -z "${HOST}" "${PORT}") >/dev/null 2>&1 || result=$? || true
        else
            (echo > /dev/tcp/${HOST}/${PORT}) >/dev/null 2>&1 || result=$? || true
        fi
        if [[ "${result}" = "0" ]]; then
            local end_ts=${SECONDS}
            Log::displayInfo "${cmdName}: ${HOST}:${PORT} is available after $((end_ts - start_ts)) seconds"
            break
        fi
        sleep 1
    done
    return ${result}
}

wait_for_wrapper()
{
    local result
    # In order to support SIGINT during timeout: http://unix.stackexchange.com/a/57692
    if [[ "${QUIET}" = "1" ]]; then
        timeout "${BUSYTIMEFLAG}" "${TIMEOUT}" $0 --quiet --child --host="${HOST}" --port="{PORT}" --timeout="${TIMEOUT}" &
    else
        timeout ${BUSYTIMEFLAG} ${TIMEOUT} $0 --child --host=${HOST} --port=${PORT} --timeout=${TIMEOUT} &
    fi
    local pid=$!
    # shellcheck disable=2064
    trap "kill -INT -${pid}" INT
    wait ${pid}
    result=$?
    if [[ "${result}" != "0" ]]; then
        Log::displayError "${cmdName}: timeout occurred after waiting ${TIMEOUT} seconds for ${HOST}:${PORT}"
    fi
    return ${result}
}

# process arguments
while [[ $# -gt 0 ]]
do
    case "$1" in
        *:* )
        # shellcheck disable=2206
        hostPort=(${1//:/ })
        HOST=${hostPort[0]}
        PORT=${hostPort[1]}
        shift 1
        ;;
        --child)
        CHILD=1
        shift 1
        ;;
        -q | --quiet)
        QUIET=1
        shift 1
        ;;
        -s | --strict)
        STRICT=1
        shift 1
        ;;
        -h)
        HOST="$2"
        if [[ "${HOST}" = "" ]]; then break; fi
        shift 2
        ;;
        --host=*)
        HOST="${1#*=}"
        shift 1
        ;;
        -p)
        PORT="$2"
        if [[ "${PORT}" = "" ]]; then break; fi
        shift 2
        ;;
        --port=*)
        PORT="${1#*=}"
        shift 1
        ;;
        -t)
        TIMEOUT="$2"
        if [[ "${TIMEOUT}" = "" ]]; then break; fi
        shift 2
        ;;
        --timeout=*)
        TIMEOUT="${1#*=}"
        shift 1
        ;;
        --)
        shift
        CLI=("$@")
        break
        ;;
        --help)
        usage
        ;;
        *)
        Log::displayError "Unknown argument: $1"
        usage
        ;;
    esac
done

if [[ "${HOST}" = "" || "${PORT}" = "" ]]; then
    Log::displayError "Error: you need to provide a host and port to test."
    usage
fi

TIMEOUT=${TIMEOUT:-15}
STRICT=${STRICT:-0}
CHILD=${CHILD:-0}
QUIET=${QUIET:-0}

# check to see if timeout is from busybox?
# check to see if timeout is from busybox?
TIMEOUT_PATH=$(readlink -f "$(which timeout)")
if [[ ${TIMEOUT_PATH} =~ "busybox" ]]; then
        ISBUSY=1
        BUSYTIMEFLAG="-t"
else
        ISBUSY=0
        BUSYTIMEFLAG=""
fi

if [[ ${CHILD} -gt 0 ]]; then
    wait_for
    RESULT=$?
    exit ${RESULT}
else
    if [[ ${TIMEOUT} -gt 0 ]]; then
        wait_for_wrapper
        RESULT=$?
    else
        wait_for
        RESULT=$?
    fi
fi
if [[ ! -z "${CLI+x}" && "${CLI[*]}" != "" ]]; then
    if [[ "${RESULT}" != "0" && "${STRICT}" = "1" ]]; then
        Log::displayError "${cmdName}: strict mode, refusing to execute sub-process"
        exit ${RESULT}
    fi
    exec "${CLI[@]}"
else
    exit ${RESULT}
fi
