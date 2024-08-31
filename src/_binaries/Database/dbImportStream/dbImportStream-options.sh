#!/usr/bin/env bash

declare PROFILES_DIR
declare HOME_PROFILES_DIR
# shellcheck disable=SC2034
declare versionNumber="2.0"
# shellcheck disable=SC2034
declare copyrightBeginYear="2020"
# shellcheck disable=SC2034
declare defaultFromDsn="default.remote"

beforeParseCallback() {
  BashTools::Conf::requireLoad
  Env::requireLoad
  UI::requireTheme
  Log::requireLoad
  Linux::requireExecutedAsUser
  Linux::requireRealpathCommand
}

initConf() {
  # shellcheck disable=SC2034
  PROFILES_DIR="${BASH_TOOLS_ROOT_DIR}/conf/dbImportProfiles"
  HOME_PROFILES_DIR="${HOME}/.bash-tools/dbImportProfiles"
  Db::checkRequirements
}

optionHelpCallback() {
  dbImportStreamCommandHelp
  exit 0
}

longDescriptionFunction() {
  local profilesList=""
  local dsnList=""
  dsnList="$(Conf::getMergedList "dsn" "env")"
  profilesList="$(Conf::getMergedList "dbImportProfiles" "sh" || true)"

  echo -e "${__HELP_TITLE}Default profiles directory:${__HELP_NORMAL}"
  echo -e "${PROFILES_DIR-configuration error}"
  echo
  echo -e "${__HELP_TITLE}User profiles directory:${__HELP_NORMAL}"
  echo -e "${HOME_PROFILES_DIR-configuration error}"
  echo -e "Allows to override profiles defined in 'Default profiles directory'"
  echo
  echo -e "${__HELP_TITLE}List of available profiles:${__HELP_NORMAL}"
  echo -e "${profilesList}"
  echo
  echo -e "${__HELP_TITLE}List of available dsn:${__HELP_NORMAL}"
  echo -e "${dsnList}"
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
