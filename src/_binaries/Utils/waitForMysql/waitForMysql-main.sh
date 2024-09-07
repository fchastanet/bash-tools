#!/usr/bin/env bash
# shellcheck disable=SC2154

Assert::commandExists "mysql"
Log::displayInfo "Waiting for mysql"
declare -i start_ts=${SECONDS}
declare status=0
declare -i triesCount=0
while true; do
  ((++triesCount))
  if ((BASH_FRAMEWORK_ARGS_VERBOSE >= __VERBOSE_LEVEL_INFO)); then
    Log::displayInfo "Try connecting to mysql host ${mysqlHostArg}:${mysqlPortArg} - Try ${triesCount}"
  else
    (printf >&2 ".")
  fi
  BashTools::runVerboseIfNeeded mysql -h"${mysqlHostArg}" -P"${mysqlPortArg}" -u"${mysqlUserArg}" \
    -p"${mysqlPasswordArg}" &>/dev/null <<<"SELECT 1" || status=$?
  if [[ "${status}" = "0" ]]; then
    break
  fi
  if ((optionTimeout != 0 && SECONDS - start_ts >= optionTimeout)); then
    (echo >&2 "")
    Log::displayError "${SCRIPT_NAME} - timeout for ${mysqlHostArg}:${mysqlPortArg} occurred after $((SECONDS - start_ts)) seconds"
    status=2
    break
  fi
  sleep 1
done

if ((BASH_FRAMEWORK_ARGS_VERBOSE < __VERBOSE_LEVEL_INFO)); then
  (echo >&2 "")
fi
if [[ "${status}" = "0" ]]; then
  Log::displayInfo "mysql ready"
fi

# when timed out, call command if any
if [[ -n "${commandArgs+x}" && "${commandArgs[*]}" != "" ]]; then
  if [[ "${status}" != "0" && "${optionExecIfTimedOut}" = "0" ]]; then
    Log::displayError "${SCRIPT_NAME} - failed to connect - strict mode - command not executed"
    exit "${status}"
  fi
  exec "${commandArgs[@]}"
fi

exit "${status}"
