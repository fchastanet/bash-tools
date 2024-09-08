#!/usr/bin/env bash

optionTablesCallback() {
  # shellcheck disable=SC2154
  if [[ ! ${optionTables} =~ ^[A-Za-z0-9_]+(,[A-Za-z0-9_]+)*$ ]]; then
    Log::fatal "Command ${SCRIPT_NAME} - Table list is not valid : ${optionTables}"
  fi
}
