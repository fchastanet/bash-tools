#!/usr/bin/env bash

# shellcheck disable=SC2034
declare optionBashFrameworkConfig="${BASH_TOOLS_ROOT_DIR}/.framework-config"
declare defaultTargetCharacterSet=""

declare TIMEFORMAT='time spent : %3R'
declare DOWNLOAD_DUMP=0

declare DB_IMPORT_DUMP_DIR
declare PROFILES_DIR
declare HOME_PROFILES_DIR

beforeParseCallback() {
  defaultBeforeParseCallback
  Linux::requireRealpathCommand
  Linux::requireExecutedAsUser
}

initConf() {
  # shellcheck disable=SC2034
  DB_IMPORT_DUMP_DIR=${DB_IMPORT_DUMP_DIR%/}
  PROFILES_DIR="${BASH_TOOLS_ROOT_DIR}/conf/dbImportProfiles"
  HOME_PROFILES_DIR="${HOME}/.bash-tools/dbImportProfiles"
}

optionHelpCallback() {
  dbImportCommandHelp
  exit 0
}

longDescriptionFunction() {
  mysqlSourceLongDescription
  echo
  profileOptionLongDescription
  echo
  echo -e "  ${__HELP_TITLE}Examples${__HELP_NORMAL}"
  echo -e "    1. from one database to another one"
  echo -e "    ${__HELP_EXAMPLE}dbImport --from-dsn localhost --target-dsn remote fromDb toDb${__HELP_NORMAL}"
  echo
  echo -e "    2. import from S3"
  echo -e "    ${__HELP_EXAMPLE}dbImport --from-aws awsFile.tar.gz --target-dsn localhost fromDb toDb${__HELP_NORMAL}"
  Db::checkRequirements
}

dsnHelpFunction() {
  echo 'dsn to use for source database'
  echo 'this option is incompatible with -a|--from-aws option'
}

dbImportCommandCallback() {
  if [[ -z "${targetDbName}" ]]; then
    # shellcheck disable=SC2154
    targetDbName="${fromDbName}"
  fi

  if [[ -n "${optionFromAws}" ]]; then
    Assert::commandExists aws \
      "Command ${SCRIPT_NAME} - missing aws, please check https://docs.aws.amazon.com/fr_fr/cli/latest/userguide/install-cliv2.html" || exit 1

    if [[ -n "${optionFromDsn}" ]]; then
      Log::fatal "Command ${SCRIPT_NAME} - you cannot use from-dsn and from-aws at the same time"
    fi

    if [[ -z "${S3_BASE_URL}" ]]; then
      Log::fatal "Command ${SCRIPT_NAME} - missing S3_BASE_URL, please provide a value in .env file"
    fi
  elif [[ -z "${optionFromDsn}" ]]; then
    # default value for FROM_DSN if from-aws not set
    # shellcheck disable=SC2154
    optionFromDsn="default.remote"
  fi

  if [[ -z "${DB_IMPORT_DUMP_DIR}" ]]; then
    Log::fatal "Command ${SCRIPT_NAME} - you have to specify a value for DB_IMPORT_DUMP_DIR env variable"
  fi

  if [[ ! -d "${DB_IMPORT_DUMP_DIR}" ]]; then
    mkdir -p "${DB_IMPORT_DUMP_DIR}" ||
      Log::fatal "Command ${SCRIPT_NAME} - impossible to create directory ${DB_IMPORT_DUMP_DIR} specified by DB_IMPORT_DUMP_DIR env variable"
  fi
}
