#!/usr/bin/env bash

longDescriptionFunction() {
  echo -e "  ${__HELP_TITLE}EXIT CODES:${__HELP_NORMAL}"
  echo -e "    ${__HELP_OPTION_COLOR}1${__HELP_NORMAL}: if commit does not exists"
  echo -e "    ${__HELP_OPTION_COLOR}2${__HELP_NORMAL}: if ref is not convertible to commit oid"
  echo -e "    ${__HELP_OPTION_COLOR}3${__HELP_NORMAL}: if commit is not included in given branch"
}

optionHelpCallback() {
  postmanCliCommandHelp
  exit 0
}

optionPostmanModelConfigHelpFunction() {
  echo "    postmanCli model file to use"
  echo "    Default value: <currentDir>/postmanCli.collections.json"
}

argCommandHelpFunction() {
  echo -e "    ${__HELP_OPTION_COLOR}pull${__HELP_NORMAL}"
  echo -e "      Pull collections from Postman back to repositories."
  echo -e "    ${__HELP_OPTION_COLOR}push${__HELP_NORMAL}"
  echo -e '      Push repositories collections to Postman.'
}

commandArgsHelpFunction() {
  echo -e "    List of postman collection's references to pull or push"
  echo -e "    or no argument to pull or push all the collections"
}

# shellcheck disable=SC2317 # if function is overridden
unknownOption() {
  commandArgs+=("$1")
}

postmanCliCommandCallback() {
  if [[ -z "${optionPostmanModelConfig}" ]]; then
    optionPostmanModelConfig="${CURRENT_DIR}/postmanCli.collections.json"
  fi
  if [[ ! -f "${optionPostmanModelConfig}" ]]; then
    Log::displayError "Please provide a valid postman config file, using --postman-model option."
    exit 1
  fi
  if [[ "${displayConfig}" = "1" ]]; then
    # shellcheck disable=SC2154
    Postman::Model::validate "${optionPostmanModelConfig}" "config"
    original_displayConfig
    UI::drawLine "-"
    printf '%-40s = %s\n' "POSTMAN_API_KEY" "${POSTMAN_API_KEY:0:15}...(truncated)"
    exit 0
  fi
}

eval "original_$(declare -f displayConfig | grep -v 'exit 0')"
declare displayConfig=0
displayConfig() {
  displayConfig=1
}
