%
declare versionNumber="2.0"
declare commandFunctionName="dbScriptAllDatabasesCommand"
declare help="Allows to execute a script on each database of specified mysql server"
# shellcheck disable=SC2016
declare longDescription='''
${__HELP_TITLE}NOTE:${__HELP_NORMAL}
the use of output, log-format, verbose options highly depends on the script used

${__HELP_TITLE}LIST OF AVAILABLE DSN:${__HELP_NORMAL}
${dsnList}

${__HELP_TITLE}DEFAULT QUERIES DIRECTORY:${__HELP_NORMAL}
${QUERIES_DIR-configuration error}

${__HELP_TITLE}USER QUERIES DIRECTORY:${__HELP_NORMAL}
${HOME_QUERIES_DIR-configuration error}
Allows to override queries defined in "Default queries directory"

${__HELP_TITLE}LIST OF AVAILABLE SCRIPTS:${__HELP_NORMAL}
${scriptsList}

${__HELP_TITLE}EXAMPLES:${__HELP_NORMAL} script conf/dbScripts/extractData.sh
    executes query databaseSize (see conf/dbQueries/databaseSize.sql) on each db and log the result in log file in default output dir, call it using
    ${__HELP_EXAMPLE}$0 -j 10 extractData databaseSize${__HELP_NORMAL}

    executes query databaseSize on each db and display the result on stdout (2>/dev/null hides information messages)
    ${__HELP_EXAMPLE}$0 -j 10 --log-format none extractData databaseSize${__HELP_NORMAL}

    use --verbose to get some debug information
    ${__HELP_EXAMPLE}$0 -j 10 --log-format none --verbose extractData databaseSize${__HELP_NORMAL}

${__HELP_TITLE}USE CASES:${__HELP_NORMAL}
    you can use this script in order to check that each db model conforms with your ORM schema
    simply create a new script in conf/dbQueries that will call your orm schema checker

    update multiple db at once (simple to complex update script)

'''
declare defaultFromDsn="default.remote"
%

.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.dsn.tpl)"
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.jobs.tpl)"
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.progressBar.tpl)"

%
# shellcheck source=/dev/null
source <(
  Options::generateGroup \
    --title "SCRIPT OPTIONS:" \
    --function-name groupSourceDbOptionsFunction

  argScriptToExecuteCallback() { :; }
  Options::generateArg \
    --help "the script that will be executed on each databases" \
    --name 'scriptToExecute' \
    --min 1 \
    --max 1 \
    --variable-name "argScriptToExecute" \
    --callback argScriptToExecuteCallback \
    --function-name argScriptToExecuteFunction

  Options::generateArg \
    --help "optional parameters to pass to the script" \
    --name 'scriptArguments' \
    --min 0 \
    --max -1 \
    --variable-name "scriptArguments" \
    --function-name scriptArgumentsFunction

  # shellcheck disable=SC2116
  Options::generateOption \
    --help "if provided will check only this db, otherwise script will be executed on all dbs of mysql server" \
    --help-value-name "dbName" \
    --variable-type "StringArray" \
    --group groupSourceDbOptionsFunction \
    --alt "--database" \
    --variable-name "optionDatabases" \
    --function-name optionDatabasesFunction

    # shellcheck disable=SC2116
  Options::generateOption \
    --help "output directory, see log-format option" \
    --help-value-name "outputDirectory" \
    --variable-type "String" \
    --group groupSourceDbOptionsFunction \
    --alt "--output" \
    --alt "-o" \
    --callback outputDirectoryCallback \
    --variable-name "optionOutputDir" \
    --function-name optionOutputDirFunction

  # shellcheck disable=SC2116
  Options::generateOption \
    --help "if output dir provided, will log each db result to log file" \
    --help-value-name "logFormat" \
    --authorized-values "none|log" \
    --default-value "none" \
    --group groupSourceDbOptionsFunction \
    --alt "--log-format" \
    --alt "-l" \
    --variable-type "String" \
    --variable-name "optionLogFormat" \
    --function-name optionLogFormatFunction
)
options+=(
  argScriptToExecuteFunction
  scriptArgumentsFunction
  optionDatabasesFunction
  optionOutputDirFunction
  optionLogFormatFunction
  --callback dbScriptAllDatabasesCommandCallback
)
Options::generateCommand "${options[@]}"
%

optionHelpCallback() {
  local dsnList queriesList scriptsList
  dsnList="$(Conf::getMergedList "dsn" "env")"
  queriesList="$(Conf::getMergedList "dbQueries" "sql" || true)"
  scriptsList="$(Conf::getMergedList "dbScripts" "sh")"

  <% ${commandFunctionName} %> help | envsubst
  exit 0
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
      if (( BASH_FRAMEWORK_ARGS_VERBOSE >= __VERBOSE_LEVEL_DEBUG )); then
        Log::displayInfo "Using script file ${scriptAbsoluteFile}"
      fi
    }
  fi
}

dbScriptAllDatabasesCommandCallback() {
  if [[ -z "${optionFromDsn}" ]]; then
    # default value for FROM_DSN if from-aws not set
    optionFromDsn="<% ${defaultFromDsn} %>"
  fi
}

<% ${commandFunctionName} %> parse "${BASH_FRAMEWORK_ARGV[@]}"
