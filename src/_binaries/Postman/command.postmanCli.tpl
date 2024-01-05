%
declare versionNumber="1.0"
declare commandFunctionName="postmanCliCommand"
declare help="Push/Pull postman collections of all the configured repositories"
declare copyrightBeginYear="2023"
# shellcheck disable=SC2016
%

.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"
%

NBSP="\xc2\xa0"
NBSP2="${NBSP}${NBSP}"
# shellcheck source=/dev/null
source <(
  Options::generateGroup \
    --title "PUSH/PULL OPTIONS:" \
    --function-name groupPushPullFunction

  # shellcheck disable=SC2016
  Options::generateOption \
    --variable-type String \
    --help $'postmanCli model file to use\n
      Default value: <currentDir>/postmanCli.collections.json' \
    --group groupPushPullFunction \
    --alt "--postman-model" \
    --alt "-m" \
    --variable-name "optionPostmanModelConfig" \
    --function-name optionPostmanModelConfigFunction

  Options::generateArg \
    --variable-name "argCommand" \
    --min 0 \
    --max 1 \
    --name "command" \
    --authorized-values 'pull|push' \
    --help \
    $'${__HELP_OPTION_COLOR}pull${__HELP_NORMAL}\n
      ${NBSP2}Pull collections from Postman back to repositories.\n
      ${__HELP_OPTION_COLOR}push${__HELP_NORMAL}\n
      ${NBSP2}Push repositories collections to Postman.\n' \
    --function-name argCommandFunction

  Options::generateArg \
    --variable-name "commandArgs" \
    --min 0 \
    --max -1 \
    --name "commandArgs" \
    --help \
    $'list of postman collection\'s references to pull or push\n
      or no argument to pull or push all the collections' \
    --function-name commandArgsFunction
)

options+=(
  optionPostmanModelConfigFunction
  argCommandFunction
  commandArgsFunction
  --unknown-option-callback unknownOption
  --unknown-argument-callback unknownOption
)

Options::generateCommand "${options[@]}"
%
declare optionPostmanModelConfig="$(pwd -P)/postmanCli.collections.json"

# shellcheck disable=SC2317 # if function is overridden
unknownOption() {
  commandArgs+=("$1")
}

eval "original_$(declare -f displayConfig | grep -v 'exit 0')"
displayConfig() {
  Postman::Model::validate "${optionPostmanModelConfig}" "config"
  original_displayConfig
  UI::drawLine "-"
  printf '%-40s = %s\n' "POSTMAN_API_KEY" "${POSTMAN_API_KEY:0:15}...(truncated)"
  exit 0
}
