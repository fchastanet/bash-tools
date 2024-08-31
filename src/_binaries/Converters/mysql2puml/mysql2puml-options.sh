#!/usr/bin/env bash

# shellcheck disable=SC2034
declare copyrightBeginYear="2020"
# shellcheck disable=SC2034
declare versionNumber="1.0"

declare optionBashFrameworkConfig="${BASH_TOOLS_ROOT_DIR}/.framework-config"

optionHelpCallback() {
  mysql2pumlCommandHelp
  exit 0
}

longDescriptionFunction() {
  echo -e "${__HELP_TITLE}EXAMPLE 1:${__HELP_NORMAL}"
  echo -e "${__HELP_EXAMPLE}mysql2puml dump.dql${__HELP_NORMAL}"
  echo
  echo -e "${__HELP_TITLE}EXAMPLE 2:${__HELP_NORMAL}"
  echo -e "${__HELP_EXAMPLE}mysqldump --skip-add-drop-table \\"
  echo -e "  --skip-add-locks \\"
  echo -e "  --skip-disable-keys \\"
  echo -e "  --skip-set-charset \\"
  echo -e "  --user=root \\"
  echo -e "  --password=root \\"
  echo -e "  --no-data skills | mysql2puml"
  echo -e "${__HELP_NORMAL}"
  echo -e "${__HELP_TITLE}LIST OF AVAILABLE SKINS:${__HELP_NORMAL}"
  Conf::getMergedList "mysql2pumlSkins" ".puml" "  - "
}

# shellcheck disable=SC2317
inputSqlFileCallback() {
  # shellcheck disable=SC2154
  if [[ ! -f "${inputSqlFile}" ]]; then
    Log::displayError "${SCRIPT_NAME} - File '${inputSqlFile}' does not exists"
    return 1
  fi
}

optionSkinCallback() {
  declare -a skinList
  readarray -t skinList < <(Conf::getMergedList "mysql2pumlSkins" ".puml" "")
  # shellcheck disable=SC2154
  if ! Array::contains "${optionSkin}" "${skinList[@]}"; then
    Log::displayError "${SCRIPT_NAME} - invalid skin '${optionSkin}' provided"
    exit 1
  fi
}

inputSqlFileCallback() {
  # shellcheck disable=SC2154
  if [[ ! -f "${inputSqlFile}" ]]; then
    Log::displayError "${SCRIPT_NAME} - File '${inputSqlFile}' does not exists"
    exit 1
  fi
}
