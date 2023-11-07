%
declare versionNumber="2.0"
declare commandFunctionName="waitForItCommand"
declare help="wait for host:port to be available"
# shellcheck disable=SC2016
declare longDescription="""
${__HELP_TITLE}EXIT STATUS CODES:${__HELP_NORMAL}
${__HELP_OPTION_COLOR}0${__HELP_NORMAL}: the host/port is available
${__HELP_OPTION_COLOR}1${__HELP_NORMAL}: indicates host/port is not available or argument error
${__HELP_OPTION_COLOR}2${__HELP_NORMAL}: timeout reached

${__HELP_TITLE}AVAILABLE ALGORITHMS:${__HELP_NORMAL}
${__HELP_OPTION_COLOR}timeoutV1WithNc${__HELP_NORMAL}: previous version of timeout command with --timeout option, base command nc
${__HELP_OPTION_COLOR}timeoutV2WithNc${__HELP_NORMAL}: newer version of timeout command using timeout as argument, base command nc
${__HELP_OPTION_COLOR}whileLoopWithNc${__HELP_NORMAL}: timeout command simulated using while loop, base command nc
${__HELP_OPTION_COLOR}timeoutV1WithTcp${__HELP_NORMAL}: previous version of timeout command with --timeout option
${__HELP_OPTION_COLOR}timeoutV2WithTcp${__HELP_NORMAL}: newer version of timeout command using timeout as argument
${__HELP_OPTION_COLOR}whileLoopWithTcp${__HELP_NORMAL}: timeout command simulated using while loop, base command tcp
"""
%
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.timeout.tpl)"
%
# shellcheck source=/dev/null
source <(
  Options::generateArg \
    --help "Execute command with args after the test finishes or exit with status code if no command provided." \
    --min 0 \
    --max -1 \
    --name "commandArgs" \
    --variable-name "commandArgs" \
    --function-name commandArgsFunction

  Options::generateOption \
    --help-value-name "hostOrIp" \
    --help "Host or IP under test." \
    --alt "--host" \
    --alt "-i" \
    --mandatory \
    --variable-type "String" \
    --variable-name "optionHostOrIp" \
    --function-name optionHostOrIpFunction

  Options::generateOption \
    --help-value-name "port" \
    --help "TCP port under test." \
    --alt "--port" \
    --alt "-p" \
    --mandatory \
    --variable-type "String" \
    --variable-name "optionPort" \
    --function-name optionPortFunction \
    --callback optionPortCallback

  Options::generateOption \
    --help-value-name "algorithm" \
    --help  "$(echo \
        "Algorithm to use Check algorithms list below." $'\n' \
        "(default: automatic selection based on commands availability and timeout option value)." \
      )" \
    --alt "--algorithm" \
    --alt "--algo" \
    --variable-type "String" \
    --variable-name "optionAlgo" \
    --function-name optionAlgoFunction \
    --callback optionAlgoCallback

  Options::generateOption \
    --help "Only execute sub-command if the test succeeds." \
    --alt "--exec-command-on-success-only" \
    --alt "--strict" \
    --alt "-s" \
    --variable-name "optionStrict" \
    --function-name optionStrictFunction

  Options::generateOption \
    --help "legacy mode using nc command or while loop (uses timeout command by default)." \
    --alt "--user-nc" \
    --variable-name "optionLegacy" \
    --function-name optionLegacyFunction
)
options+=(
  --unknown-option-callback unknownOption
  --unknown-argument-callback unknownOption
  --callback commandCallback
  commandArgsFunction
  optionHostOrIpFunction
  optionPortFunction
  optionAlgoFunction
  optionStrictFunction
)
Options::generateCommand "${options[@]}"
%

# shellcheck disable=SC2317 # if function is overridden
unknownOption() {
  commandArgs+=("$1")
}

optionPortCallback() {
  if [[ ! "${optionPort}" =~ ^[0-9]+$ ]] || (( optionPort == 0 )); then
    Log::fatal "${SCRIPT_NAME} - invalid port option - must be greater than to 0"
  fi
}

optionAlgoCallback() {
  if ! Array::contains "${optionAlgo}" "${availableAlgos[@]}"; then
    Log::fatal "${SCRIPT_NAME} - invalid algorithm '${optionAlgo}'"
  fi
}

commandCallback() {
  if [[ "${optionHostOrIp}" = "" || "${optionPort}" = "" ]]; then
    Log::fatal "${SCRIPT_NAME} - you need to provide a host and port to test."
  fi
}

<% ${commandFunctionName} %> parse "${BASH_FRAMEWORK_ARGV[@]}"
