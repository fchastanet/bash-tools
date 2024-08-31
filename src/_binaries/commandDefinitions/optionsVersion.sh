#!/usr/bin/env bash

optionVersionCallback() {
  # shellcheck disable=SC2154
  echo "${SCRIPT_NAME} version ${versionNumber}"
  Db::checkRequirements
  exit 0
}
