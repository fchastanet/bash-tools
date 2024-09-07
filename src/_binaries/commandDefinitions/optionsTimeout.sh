#!/usr/bin/env bash

optionTimeoutCallback() {
  # shellcheck disable=SC2154
  if [[ ! "${optionTimeout}" =~ ^[0-9]+$ ]]; then
    Log::fatal "${SCRIPT_NAME} - invalid timeout option - must be greater or equal to 0"
  fi
}
