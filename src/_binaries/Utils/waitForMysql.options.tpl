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
%
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.timeout.tpl)"
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
)
options+=(
  mysqlHostArgFunction
  mysqlPortArgFunction
  mysqlUserArgFunction
  mysqlPasswordArgFunction
)
Options::generateCommand "${options[@]}"
%

mysqlPortArgCallback() {
  if [[ ! "${mysqlPortArg}" =~ ^[0-9]+$ ]] || (( mysqlPortArg == 0 )); then
    Log::fatal "${SCRIPT_NAME} - invalid port option - must be greater than to 0"
  fi
}

<% ${commandFunctionName} %> parse "${BASH_FRAMEWORK_ARGV[@]}"
