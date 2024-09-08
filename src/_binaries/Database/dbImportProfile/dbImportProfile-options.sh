#!/usr/bin/env bash
declare defaultFromDsn="default.remote"
# shellcheck disable=SC2034
declare PROFILES_DIR
declare HOME_PROFILES_DIR
# shellcheck disable=SC2034
defaultOptionProfile=""

beforeParseCallback() {
  defaultBeforeParseCallback
  Linux::requireExecutedAsUser
  Linux::requireRealpathCommand
  Assert::commandExists mysql "sudo apt-get install -y mysql-client"
  Assert::commandExists mysqlshow "sudo apt-get install -y mysql-client"
}

initConf() {
  # shellcheck disable=SC2034
  PROFILES_DIR="${BASH_TOOLS_ROOT_DIR}/conf/dbImportProfiles"
  # shellcheck disable=SC2034
  HOME_PROFILES_DIR="${HOME}/.bash-tools/dbImportProfiles"
}

initProfileCommandCallback() {
  :
}

optionHelpCallback() {
  dbImportProfileCommandHelp
  exit 0
}

longDescriptionFunction() {
  fromDsnOptionLongDescription
  echo
  profileOptionLongDescription
}

optionProfileHelpFunction() {
  Array::wrap2 " " 80 4 \
    "    The name of the profile to write in profiles directory.\n" \
    "If not provided, the file name pattern will be 'auto_<dsn>_<fromDbName>.sh'"
  echo
}

optionFromDsnHelpFunction() {
  Array::wrap2 " " 80 4 \
    "    dsn to use for source database (Default: ${defaultFromDsn})\n" \
    "if not provided, the file name pattern will be 'auto_<dsn>_<fromDbName>.sh'"
  echo
}

dbImportProfileCommandCallback() {
  if [[ -z "${fromDbName}" ]]; then
    Log::fatal "you must provide fromDbName"
  fi

  if [[ -z "${optionProfile}" ]]; then
    # shellcheck disable=SC2154
    optionProfile="auto_${optionFromDsn}_${fromDbName}"
  fi

  # shellcheck disable=SC2154
  if ! [[ "${optionRatio}" =~ ^-?[0-9]+$ ]]; then
    Log::fatal "Ratio value should be a number"
  fi

  if ((optionRatio < 0 || optionRatio > 100)); then
    Log::fatal "Ratio value should be between 0 and 100"
  fi
}
