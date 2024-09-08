#!/usr/bin/env bash

declare SCRIPTS_DIR
declare HOME_SCRIPTS_DIR
# shellcheck disable=SC2034
declare defaultFromDsn="default.remote"
# shellcheck disable=SC2034
declare outputDirectory="${HOME}/.bash-tools/output"

beforeParseCallback() {
  defaultBeforeParseCallback
  Assert::commandExists mysql "sudo apt-get install -y mysql-client"
  Assert::commandExists mysqlshow "sudo apt-get install -y mysql-client"
  Assert::commandExists parallel "sudo apt-get install -y parallel"
  Linux::requireExecutedAsUser
  Linux::requireRealpathCommand
}

initConf() {
  # shellcheck disable=SC2034
  SCRIPTS_DIR="${BASH_TOOLS_ROOT_DIR}/conf/dbScripts"
  HOME_SCRIPTS_DIR="${HOME}/.bash-tools/dbScripts"
  Db::checkRequirements
}

optionHelpCallback() {
  dbScriptAllDatabasesCommandHelp
  exit 0
}

longDescriptionFunction() {
  local scriptsList
  scriptsList="$(Conf::getMergedList "dbScripts" "sh" "      - " || true)"

  fromDsnOptionLongDescription
  echo
  echo -e "  ${__HELP_TITLE}SCRIPTS${__HELP_NORMAL}"
  echo -e "    ${__HELP_TITLE}Default scripts directory:${__HELP_NORMAL}"
  echo -e "      ${SCRIPTS_DIR-configuration error}"
  echo
  echo -e "    ${__HELP_TITLE}User scripts directory:${__HELP_NORMAL}"
  echo -e "      ${HOME_SCRIPTS_DIR-configuration error}"
  echo -e "      Allows to override queries defined in 'Default scripts directory'"
  echo
  echo -e "    ${__HELP_TITLE}List of available scripts:${__HELP_NORMAL}"
  echo -e "${scriptsList}"
  echo
  echo -e "  ${__HELP_TITLE}NOTE:${__HELP_NORMAL}"
  echo -e "    the use of output, log-format, verbose options highly depends on the script used"
  echo
  echo -e "  ${__HELP_TITLE}EXAMPLES:${__HELP_NORMAL} script conf/dbScripts/extractData.sh"
  echo -e "    1. executes query databaseSize (see conf/dbQueries/databaseSize.sql) on each db and log the result in log file in default output dir, call it using"
  echo -e "    ${__HELP_EXAMPLE}$0 -j 10 extractData databaseSize${__HELP_NORMAL}"
  echo
  echo -e "    2. executes query databaseSize on each db and display the result on stdout (2>/dev/null hides information messages)"
  echo -e "    ${__HELP_EXAMPLE}$0 -j 10 --log-format none extractData databaseSize${__HELP_NORMAL}"
  echo
  echo -e "    3. use --verbose to get some debug information"
  echo -e "    ${__HELP_EXAMPLE}$0 -j 10 --log-format none --verbose extractData databaseSize${__HELP_NORMAL}"
  echo
  echo -e "  ${__HELP_TITLE}USE CASES:${__HELP_NORMAL}"
  echo -e "    you can use this script in order to check that each db model conforms with your ORM schema"
  echo -e "    simply create a new script in conf/dbQueries that will call your orm schema checker"
  echo
  echo -e "    update multiple db at once (simple to complex update script)"
}

outputDirectoryCallback() {
  if [[ "${optionOutputDir:0:1}" != "/" ]]; then
    # relative path
    optionOutputDir="${PWD}/${optionOutputDir}"
  fi
  mkdir -p "${optionOutputDir}" || Log::fatal "unable to create directory ${optionOutputDir}"
  if [[ ! -d "${optionOutputDir}" || ! -w "${optionOutputDir}" ]]; then
    Log::fatal "output dir is not correct or not writable"
  fi
}

argScriptToExecuteCallback() {
  if [[ ! -f "${argScriptToExecute}" ]]; then
    declare scriptAbsoluteFile
    scriptAbsoluteFile="$(Conf::getAbsoluteFile "dbScripts" "${argScriptToExecute}" "sh")" && {
      argScriptToExecute="${scriptAbsoluteFile}"
      if ((BASH_FRAMEWORK_ARGS_VERBOSE >= __VERBOSE_LEVEL_DEBUG)); then
        Log::displayInfo "Using script file ${scriptAbsoluteFile}"
      fi
    }
  fi
}

dbScriptAllDatabasesCommandCallback() {
  if [[ -z "${optionFromDsn}" ]]; then
    # default value for FROM_DSN if from-aws not set
    optionFromDsn="${defaultFromDsn}"
  fi
}
