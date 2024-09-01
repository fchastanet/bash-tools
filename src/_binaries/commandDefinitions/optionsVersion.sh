#!/usr/bin/env bash

optionVersionCallback() {
  # shellcheck disable=SC2154
  echo "${SCRIPT_NAME} version {{ .RootData.binData.commands.default.version }}"
  Db::checkRequirements
  exit 0
}
