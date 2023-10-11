#!/usr/bin/env bash
# BIN_FILE=${FRAMEWORK_ROOT_DIR}/bin/waitForMysql
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE
# shellcheck disable=SC2154
# shellcheck disable=SC2317

.INCLUDE "$(dynamicTemplateDir _binaries/Utils/waitForMysql.options.tpl)"

waitForMysqlCommand parse "${BASH_FRAMEWORK_ARGV[@]}"

run() {
  Assert::commandExists "mysql"
  Log::displayInfo "Waiting for mysql"
  local -i start_ts=${SECONDS}
  (printf >&2 ".")
  until (echo "select 1" | mysql \
    -h"${mysqlHostArg}" \
    -P"${mysqlPortArg}" \
    -u"${mysqlUserArg}" \
    -p"${mysqlPasswordArg}" &>/dev/null); do
    (printf >&2 ".")
    if (( optionTimeout!=0 && SECONDS - start_ts >= optionTimeout)); then
      (echo >&2 "")
      Log::displayError "${SCRIPT_NAME} - timeout for ${mysqlHostArg}:${mysqlPortArg} occurred after $((SECONDS - start_ts)) seconds"
      return 2
    fi
    sleep 1
  done

  (echo >&2 "")
  Log::displayInfo "mysql ready"
}

if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "1" ]]; then
  run &>/dev/null
else
  run
fi
