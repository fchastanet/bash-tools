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
  echo
  echo -e "  ${__HELP_TITLE}Changelog${__HELP_NORMAL}"
  echo -e "    ${__HELP_EXAMPLE}4.0 (2026-04-14)${__HELP_NORMAL}"
  echo -e "      - add support for tar.gz and tar.individual.sql.gz dump files"
  echo -e "    ${__HELP_EXAMPLE}3.0${__HELP_NORMAL}"
  echo -e "      - initial version"
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
