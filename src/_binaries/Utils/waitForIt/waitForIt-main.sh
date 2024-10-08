#!/usr/bin/env bash
# shellcheck disable=SC2154

# Use this script to test if a given TCP host/port are available
# https://github.com/vishnubob/wait-for-it
# shellcheck disable=SC2317
usingTcp() {
  # couldn't find another way to mock this part
  if [[ -n "${WAIT_FOR_IT_MOCKED_TCP:-}" ]]; then
    "${WAIT_FOR_IT_MOCKED_TCP}" "/dev/tcp/${hostOrIpArg}/${portArg}"
  else
    echo >"/dev/tcp/${hostOrIpArg}/${portArg}"
  fi
}

# shellcheck disable=SC2317
usingNc() {
  local -a ncCmd=(nc -z "${hostOrIpArg}" "${portArg}" -w 1)
  if ((BASH_FRAMEWORK_ARGS_VERBOSE >= __VERBOSE_LEVEL_INFO)); then
    ncCmd+=(-v)
  fi

  BashTools::runVerboseIfNeeded "${ncCmd[@]}"
}

whileLoop() {
  local commandToUse="$1"
  local reportTimeout="${2:-0}"
  if ! Array::contains "${commandToUse}" "usingTcp" "usingNc"; then
    Log::fatal "${SCRIPT_NAME} - can't call command ${commandToUse} in child mode"
  fi

  local -i start_ts=${SECONDS}
  while true; do
    if "${commandToUse}"; then
      Log::displayInfo "${SCRIPT_NAME} - ${hostOrIpArg}:${portArg} is available after $((SECONDS - start_ts)) seconds"
      break
    fi
    if ((optionTimeout != 0 && SECONDS - start_ts >= optionTimeout)); then
      if [[ "${reportTimeout}" = "1" ]]; then
        Log::displayError "${SCRIPT_NAME} - timeout for ${hostOrIpArg}:${portArg} occurred after $((SECONDS - start_ts)) seconds > ${optionTimeout}"
      fi
      return 2
    fi
    sleep 1
  done
  return 0
}

# shellcheck disable=SC2317
timeoutCommand() {
  local timeoutVersion="$1"
  local commandToUse="$2"
  local result
  local -i start_ts=${SECONDS}

  if ! Array::contains "${commandToUse}" "usingTcp" "usingNc"; then
    Log::fatal "${SCRIPT_NAME} - can't call command ${commandToUse} in timeout mode"
  fi

  # compute timeout command
  local -a timeoutCmd=(timeout)
  if [[ "${timeoutVersion}" = "v1" ]]; then
    # In order to support SIGINT during timeout: http://unix.stackexchange.com/a/57692
    timeoutCmd+=("-t")
  fi
  timeoutCmd+=(
    "${optionTimeout}"
    "$0"
    "${ORIGINAL_BASH_FRAMEWORK_ARGV[@]}"
  )
  WAIT_FOR_IT_TIMEOUT_CHILD_ALGO="${commandToUse}" "${timeoutCmd[@]}" &

  local pid=$!
  # shellcheck disable=2064
  trap "kill -INT -${pid}" INT
  wait "${pid}"
  result=$?
  if [[ "${result}" != "0" ]]; then
    Log::displayError "${SCRIPT_NAME} - timeout for ${hostOrIpArg}:${portArg} occurred after $((SECONDS - start_ts)) seconds"
  fi
  return "${result}"
}

# --------------------------------------
# ALGORITHMS
# shellcheck disable=SC2317
timeoutV1WithNc() {
  timeoutCommand "v1" "usingNc"
}
# shellcheck disable=SC2317
timeoutV2WithNc() {
  timeoutCommand "v2" "usingNc"
}
# shellcheck disable=SC2317
whileLoopWithNc() {
  whileLoop "usingNc" "1"
}
# shellcheck disable=SC2317
timeoutV1WithTcp() {
  timeoutCommand "v1" "usingTcp"
}
# shellcheck disable=SC2317
timeoutV2WithTcp() {
  timeoutCommand "v2" "usingTcp"
}
# shellcheck disable=SC2317
whileLoopWithTcp() {
  whileLoop "usingTcp" "1"
}
# --------------------------------------

algorithmAutomaticSelection() {
  if Array::contains "${optionAlgo}" "${availableAlgos[@]}"; then
    echo "${optionAlgo}"
    return 0
  fi

  local command="WithTcp"
  if Assert::commandExists nc &>/dev/null; then
    # nc has the -w option allowing for timeout
    command="WithNc"
  fi

  if ((optionTimeout > 0)); then
    if Assert::commandExists timeout &>/dev/null; then
      if timeout --help 2>&1 | grep -q -E -e '--timeout '; then
        echo "timeoutV1${command}"
      else
        echo "timeoutV2${command}"
      fi
    fi
    return 0
  fi
  echo "whileLoop${command}"
}

declare result="0"
if [[ -n "${WAIT_FOR_IT_TIMEOUT_CHILD_ALGO:-}" ]]; then
  # parent process is executing timeout with current child process
  # call algo nc or tcp inside whileLoop
  whileLoop "${WAIT_FOR_IT_TIMEOUT_CHILD_ALGO}" "0" || result=$?
else
  declare algo="${optionAlgo}"
  if [[ -z "${algo}" ]]; then
    algo=$(algorithmAutomaticSelection)
  fi
  Log::displayInfo "${SCRIPT_NAME} - using algorithm ${algo}"
  if ((optionTimeout > 0)); then
    Log::displayInfo "${SCRIPT_NAME} - waiting ${optionTimeout} seconds for ${hostOrIpArg}:${portArg}"
  else
    Log::displayInfo "${SCRIPT_NAME} - waiting for ${hostOrIpArg}:${portArg} without a timeout"
  fi
  "${algo}" || result=$?
  # when timed out, call command if any
  if [[ -n "${commandArgs+x}" && "${commandArgs[*]}" != "" ]]; then
    if [[ "${result}" != "0" && "${optionExecIfTimedOut}" = "0" ]]; then
      Log::displayError "${SCRIPT_NAME} - failed to connect - strict mode - command not executed"
      exit "${result}"
    fi
    exec "${commandArgs[@]}"
  fi
fi

exit "${result}"
