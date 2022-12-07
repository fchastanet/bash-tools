#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/waitForIt
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

#   Use this script to test if a given TCP host/port are available
#  https://github.com/vishnubob/wait-for-it

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

showHelp() {
  cat <<USAGE >&2
${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} host:port [-s] [-t timeout] [-- command args]
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

waitFor() {
  local result=0
  if ((TIMEOUT > 0)); then
    Log::displayInfo "${SCRIPT_NAME}: waiting ${TIMEOUT} seconds for ${HOST}:${PORT}"
  else
    Log::displayInfo "${SCRIPT_NAME}: waiting for ${HOST}:${PORT} without a timeout"
  fi
  local start_ts=${SECONDS}
  while true; do
    result=0
    if [[ "${ISBUSY}" = "1" ]]; then
      (nc -z "${HOST}" "${PORT}") >/dev/null 2>&1 || result=$? || true
    else
      (echo >"/dev/tcp/${HOST}/${PORT}") >/dev/null 2>&1 || result=$? || true
    fi
    if [[ "${result}" = "0" ]]; then
      local end_ts=${SECONDS}
      Log::displayInfo "${SCRIPT_NAME}: ${HOST}:${PORT} is available after $((end_ts - start_ts)) seconds"
      break
    fi
    sleep 1
  done
  return "${result}"
}

waitForWrapper() {
  local result
  # In order to support SIGINT during timeout: http://unix.stackexchange.com/a/57692
  local -a ARGS=(--child "--host=${HOST}" "--port=${PORT}" "--timeout=${TIMEOUT}")
  if [[ "${QUIET}" = "1" ]]; then
    ARGS+=(--quiet)
  fi
  timeout "${BUSYTIMEFLAG}" "${TIMEOUT}" "$0" "${ARGS[@]}" &

  local pid=$!
  # shellcheck disable=2064
  trap "kill -INT -${pid}" INT
  wait "${pid}"
  result=$?
  if [[ "${result}" != "0" ]]; then
    Log::displayError "${SCRIPT_NAME}: timeout occurred after waiting ${TIMEOUT} seconds for ${HOST}:${PORT}"
  fi
  return "${result}"
}

# process arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    *:*)
      # shellcheck disable=2206
      hostPort=(${1//:/ })
      HOST=${hostPort[0]}
      PORT=${hostPort[1]}
      shift 1 || true
      ;;
    --child)
      CHILD=1
      shift 1 || true
      ;;
    -q | --quiet)
      QUIET=1
      shift 1 || true
      ;;
    -s | --strict)
      STRICT=1
      shift 1 || true
      ;;
    -h)
      HOST="$2"
      if [[ "${HOST}" = "" ]]; then break; fi
      shift 2 || true
      ;;
    --host=*)
      HOST="${1#*=}"
      shift 1 || true
      ;;
    -p)
      PORT="$2"
      if [[ "${PORT}" = "" ]]; then break; fi
      shift 2 || true
      ;;
    --port=*)
      PORT="${1#*=}"
      shift 1 || true
      ;;
    -t)
      TIMEOUT="$2"
      if [[ "${TIMEOUT}" = "" ]]; then break; fi
      shift 2 || true
      ;;
    --timeout=*)
      TIMEOUT="${1#*=}"
      shift 1 || true
      ;;
    --)
      shift || true
      CLI=("$@")
      break
      ;;
    --help)
      showHelp
      ;;
    *)
      showHelp
      Log::fatal "Unknown argument: $1"
      ;;
  esac
done

if [[ "${HOST}" = "" || "${PORT}" = "" ]]; then
  showHelp
  Log::fatal "Error: you need to provide a host and port to test."
fi

TIMEOUT=${TIMEOUT:-15}
STRICT=${STRICT:-0}
CHILD=${CHILD:-0}
QUIET=${QUIET:-0}

# check to see if timeout is from busybox?
# check to see if timeout is from busybox?
TIMEOUT_PATH=$(dirname "$(command -v timeout)")
if [[ ${TIMEOUT_PATH} =~ "busybox" ]]; then
  ISBUSY=1
  BUSYTIMEFLAG="-t"
else
  ISBUSY=0
  BUSYTIMEFLAG=""
fi

if [[ ${CHILD} -gt 0 ]]; then
  waitFor
  RESULT=$?
  exit "${RESULT}"
else
  if [[ ${TIMEOUT} -gt 0 ]]; then
    waitForWrapper
    RESULT=$?
  else
    waitFor
    RESULT=$?
  fi
fi
if [[ -n "${CLI+x}" && "${CLI[*]}" != "" ]]; then
  if [[ "${RESULT}" != "0" && "${STRICT}" = "1" ]]; then
    Log::displayError "${SCRIPT_NAME}: strict mode, refusing to execute sub-process"
    exit "${RESULT}"
  fi
  exec "${CLI[@]}"
else
  exit "${RESULT}"
fi
