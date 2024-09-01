#!/usr/bin/env bash
declare defaultFromDsn="default.remote"
# shellcheck disable=SC2034
declare PROFILES_DIR
declare HOME_PROFILES_DIR

initConf() {
  # shellcheck disable=SC2034
  PROFILES_DIR="${BASH_TOOLS_ROOT_DIR}/conf/dbImportProfiles"
  HOME_PROFILES_DIR="${HOME}/.bash-tools/dbImportProfiles"
}

optionHelpCallback() {
  dbImportProfileCommandHelp
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
  echo -e 'Allows to override profiles defined in "Default profiles directory"'
  echo
  echo -e "${__HELP_TITLE}List of available profiles:${__HELP_NORMAL}"
  echo -e "${profilesList}"
  echo
  echo -e "${__HELP_TITLE}List of available dsn:${__HELP_NORMAL}"
  echo -e "${dsnList}"
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

optionRatioHelpFunction() {
  Array::wrap2 " " 80 4 \
    "    define the ratio to use (0 to 100% - default 70).\n" \
    "- 0 means profile will filter out all the tables\n" \
    "- 100 means profile will keep all the tables.\n" \
    "Eg: 70 means that tables with size(table+index)\n" \
    "that are greater than 70% of the max table size will be excluded."
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
