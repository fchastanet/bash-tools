%
declare versionNumber="2.0"
declare commandFunctionName="dbQueryAllDatabasesCommand"
declare help="Execute a query on multiple databases in order to generate a report with tsv format, query can be parallelized on multiple databases"
# shellcheck disable=SC2016
declare longDescription='''
${__HELP_TITLE}LIST OF AVAILABLE DSN:${__HELP_NORMAL}
${dsnList}

${__HELP_TITLE}DEFAULT QUERIES DIRECTORY:${__HELP_NORMAL}
${QUERIES_DIR-configuration error}

${__HELP_TITLE}USER QUERIES DIRECTORY:${__HELP_NORMAL}
${HOME_QUERIES_DIR-configuration error}
Allows to override queries defined in "Default queries directory"

${__HELP_TITLE}LIST OF AVAILABLE QUERIES:${__HELP_NORMAL}
${queriesList}

${__HELP_TITLE}EXAMPLES:${__HELP_NORMAL}
${__HELP_EXAMPLE}${example1}${__HELP_NORMAL}
'''
declare defaultFromDsn="default.remote"
%

declare example1=$'dbQueryAllDatabases databaseSize -j 12 --separator "|" --bar 2>/dev/null | column -s "|" -t -n -c 40'

.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.dsn.tpl)"
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.jobs.tpl)"
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.progressBar.tpl)"

%
# shellcheck source=/dev/null
source <(
  Options::generateGroup \
    --title "QUERY OPTIONS:" \
    --function-name groupSourceDbOptionsFunction

  argQueryCallback() { :; }
  Options::generateArg \
    --min 1 \
    --max 1 \
    --help "$(echo \
      "Query to execute" $'\n' \
      "- <file>, try to execute the mysql query provided by the file" $'\n' \
      '- <queryFile>, search for query file in queries directory (see below)' $'\n' \
      '- else the argument is interpreted as query string' \
    )" \
    --variable-name "argQuery" \
    --callback argQueryCallback \
    --function-name argQueryFunction

  optionSeparatorCallback() { :; }
  # shellcheck disable=SC2116
  Options::generateOption \
    --help-value-name "separator" \
    --help "character to use to separate mysql column" \
    --alt "--separator" \
    --alt "-s" \
    --variable-type "String" \
    --default-value "|" \
    --callback optionSeparatorCallback \
    --variable-name "optionSeparator" \
    --function-name optionSeparatorFunction
)
options+=(
  argQueryFunction
  optionSeparatorFunction
  --callback dbQueryAllDatabasesCommandCallback
)
Options::generateCommand "${options[@]}"
%

optionHelpCallback() {
  local dsnList queriesList
  dsnList="$(Conf::getMergedList "dsn" "env")"
  queriesList="$(Conf::getMergedList "dbQueries" "sql" || true)"

  <% ${commandFunctionName} %> help | envsubst
  exit 0
}

optionSeparatorCallback() {
  if ((${#optionSeparator} != 1)); then
    Log::fatal "Command ${SCRIPT_NAME} - only one character is accepter as separator"
  fi

  if [[ ${optionSeparator} =~ [a-zA-Z0-9/\ ] ]]; then
    Log::fatal "Command ${SCRIPT_NAME} - characters alphanumeric, slash(/) and space( ) are not supported as separator"
  fi
}

argQueryCallback() {
  if [[ -f "${argQuery}" ]]; then
    queryIsFile="1"
  else
    declare queryAbsoluteFile
    queryAbsoluteFile="$(Conf::getAbsoluteFile "dbQueries" "${argQuery}" "sql")" && {
      queryIsFile="1"
      argQuery="${queryAbsoluteFile}"
      Log::displayInfo "Using query file ${queryAbsoluteFile}"
    }
  fi
}

dbQueryAllDatabasesCommandCallback() {
  if [[ -z "${optionFromDsn}" ]]; then
    # default value for FROM_DSN if from-aws not set
    optionFromDsn="<% ${defaultFromDsn} %>"
  fi
}

<% ${commandFunctionName} %> parse "${BASH_FRAMEWORK_ARGV[@]}"
