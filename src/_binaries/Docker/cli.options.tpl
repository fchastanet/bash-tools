%
declare versionNumber="2.0"
declare commandFunctionName="cliCommand"
declare help="easy connection to docker container"
# shellcheck disable=SC2016
declare longDescription='''
${__HELP_TITLE}AVAILABLE PROFILES (from ${PROFILES_DIR})${__HELP_NORMAL}
This list can be overridden in ${HOME_PROFILES_DIR}

${profilesList}

${__HELP_TITLE}AVAILABLE CONTAINERS:${__HELP_NORMAL}
${containers}

${__HELP_TITLE}EXAMPLES:${__HELP_EXAMPLE}
    to connect to mysql container in bash mode with user mysql
        ${SCRIPT_NAME} mysql mysql '/bin/bash'
    to connect to web container with user root
        ${SCRIPT_NAME} web root
${__HELP_NORMAL}

${__HELP_TITLE}CREATE NEW PROFILE:${__HELP_NORMAL}
You can create new profiles in ${HOME_PROFILES_DIR}.
This script will be called with the
arguments ${__HELP_OPTION_COLOR}userArg${__HELP_NORMAL}, ${__HELP_OPTION_COLOR}containerArg${__HELP_NORMAL}, ${__HELP_OPTION_COLOR}commandArg${__HELP_NORMAL}
The script has to compute the following
variables ${__HELP_OPTION_COLOR}finalUserArg${__HELP_NORMAL}, ${__HELP_OPTION_COLOR}finalContainerArg${__HELP_NORMAL}, ${__HELP_OPTION_COLOR}finalCommandArg${__HELP_NORMAL}
'''
%
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"
%
# shellcheck source=/dev/null
source <(
  containerArgHelpCallback() { :; }
  Options::generateArg \
    --help containerArgHelpCallback \
    --min 0 \
    --max 1 \
    --name "container" \
    --variable-name "containerArg" \
    --function-name containerArgFunction

  userArgHelpCallback() { :; }
  Options::generateArg \
    --help userArgHelpCallback \
    --min 0 \
    --max 1 \
    --name "user" \
    --variable-name "userArg" \
    --function-name userArgFunction

  commandArgHelpCallback() { :; }
  Options::generateArg \
    --help commandArgHelpCallback \
    --variable-name "commandArg" \
    --min 0 \
    --name "commandArg" \
    --function-name commandArgFunction
)
options+=(
  --unknown-option-callback unknownOption
  --unknown-argument-callback unknownOption
  containerArgFunction
  userArgFunction
  commandArgFunction
)
Options::generateCommand "${options[@]}"
%

containerArgHelpCallback() {
  Conf::load "cliProfiles" "default"
  echo "container should be the name of a profile from profile list,"
  echo "check containers list below."
  echo "If not provided, it will load the container specified in default configuration."
  echo "Default configuration: ${__HELP_OPTION_COLOR}${containerArg}${__HELP_NORMAL}"
  echo "Default container: ${__HELP_OPTION_COLOR}${finalContainerArg}${__HELP_NORMAL}"
}

userArgHelpCallback() {
  Conf::load "cliProfiles" "default"
  echo "user to connect on this container" $'\n'
  echo "Default user: ${__HELP_OPTION_COLOR}${finalUserArg}${__HELP_NORMAL}"
  echo "  loaded from profile selected as first arg"
  echo "  or deduced from default configuration." $'\n'
  echo "Default configuration: ${__HELP_OPTION_COLOR}${containerArg}${__HELP_NORMAL}" $'\n'
  echo "if first arg is not a profile"
}

commandArgHelpCallback() {
  Conf::load "cliProfiles" "default"
  echo "The command to execute" $'\n'
  echo "Default command: ${__HELP_OPTION_COLOR}${finalCommandArg[*]}${__HELP_NORMAL}"
  echo "  loaded from profile selected as first arg"
  echo "  or deduced from default configuration."
  echo "Default configuration: ${__HELP_OPTION_COLOR}${containerArg}${__HELP_NORMAL}" $'\n'
  echo "if first arg is not a profile"
}

optionHelpCallback() {
  local containers
  # shellcheck disable=SC2046
  containers="$(Array::wrap2 ", " 80 0 $(docker ps --format '{{.Names}}'))"
  local profilesList=""
  Conf::load "cliProfiles" "default"

  profilesList="$(Conf::getMergedList "cliProfiles" ".sh" "  - " || true)"

  <% ${commandFunctionName} %> help | envsubst
  exit 0
}

# shellcheck disable=SC2317 # if function is overridden
unknownOption() {
  commandArg+=("$1")
}

<% ${commandFunctionName} %> parse "${BASH_FRAMEWORK_ARGV[@]}"
