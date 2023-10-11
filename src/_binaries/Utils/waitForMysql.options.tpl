%
declare versionNumber="2.0"
declare commandFunctionName="waitForMysqlCommand"
declare help="wait for mysql to be ready"
# shellcheck disable=SC2016
declare longDescription="""
${__HELP_TITLE}EXIT STATUS CODES:${__HELP_NORMAL}
${__HELP_OPTION_COLOR}0${__HELP_NORMAL}: mysql is available
${__HELP_OPTION_COLOR}1${__HELP_NORMAL}: indicates mysql is not available or argument error
${__HELP_OPTION_COLOR}2${__HELP_NORMAL}: timeout reached
"""
declare defaultTimeout="15"
%
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"
%
# shellcheck source=/dev/null
source <(
  Options::generateArg \
    --help "Mysql host name" \
    --name "mysqlHost" \
    --variable-name "mysqlHostArg" \
    --function-name mysqlHostArgFunction

  mysqlPortArgCallback() { :; }
  Options::generateArg \
    --help "Mysql port" \
    --name "mysqlPort" \
    --variable-name "mysqlPortArg" \
    --callback mysqlPortArgCallback \
    --function-name mysqlPortArgFunction

  Options::generateArg \
    --help "Mysql user name" \
    --name "mysqlUserArg" \
    --variable-name "mysqlUserArg" \
    --function-name mysqlUserArgFunction

  Options::generateArg \
    --help "Mysql password" \
    --name "mysqlPasswordArg" \
    --variable-name "mysqlPasswordArg" \
    --function-name mysqlPasswordArgFunction

  optionTimeoutCallback() { :; }
  Options::generateOption \
    --help-value-name "timeout" \
    --help "Timeout in seconds, zero for no timeout." \
    --default-value "${defaultTimeout}" \
    --alt "--timeout" \
    --alt "-t" \
    --variable-type "String" \
    --variable-name "optionTimeout" \
    --function-name optionTimeoutFunction \
    --callback optionTimeoutCallback
)
options+=(
  mysqlHostArgFunction
  mysqlPortArgFunction
  mysqlUserArgFunction
  mysqlPasswordArgFunction
  optionTimeoutFunction
)
Options::generateCommand "${options[@]}"
%

mysqlPortArgCallback() {
  if [[ ! "${mysqlPortArg}" =~ ^[0-9]+$ ]] || (( mysqlPortArg == 0 )); then
    Log::fatal "${SCRIPT_NAME} - invalid port option - must be greater than to 0"
  fi
}

optionTimeoutCallback() {
  if [[ ! "${optionTimeout}" =~ ^[0-9]+$ ]]; then
    Log::fatal "${SCRIPT_NAME} - invalid timeout option - must be greater or equal to 0"
  fi
}


# default values
declare copyrightBeginYear="2020"
declare optionTimeout="<% ${defaultTimeout} %>"
