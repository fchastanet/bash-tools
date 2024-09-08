#!/usr/bin/env bash

declare PROFILES_DIR
declare HOME_PROFILES_DIR
# shellcheck disable=SC2034
declare defaultFromDsn="default.remote"

beforeParseCallback() {
  defaultBeforeParseCallback
  Linux::requireExecutedAsUser
  Linux::requireRealpathCommand
}

initConf() {
  # shellcheck disable=SC2034
  PROFILES_DIR="${BASH_TOOLS_ROOT_DIR}/conf/dbImportProfiles"
  # shellcheck disable=SC2034
  HOME_PROFILES_DIR="${HOME}/.bash-tools/dbImportProfiles"
  Db::checkRequirements
}

optionHelpCallback() {
  dbImportStreamCommandHelp
  exit 0
}

longDescriptionFunction() {
  fromDsnOptionLongDescription
  echo
  profileOptionLongDescription
}

dbImportStreamCommandCallback() {
  if [[ -z "${argTargetDbName}" ]]; then
    Log::fatal "you must provide argTargetDbName"
  fi
  # shellcheck disable=SC2154
  if [[ ! -f "${argDumpFile}" ]]; then
    Log::fatal "invalid argDumpFile provided - file does not exist"
  fi
}
