%
declare versionNumber="1.0"
declare commandFunctionName="mysql2pumlCommand"
declare optionSkinDefault="default"
declare help="convert mysql dump sql schema to plantuml format"
declare longDescription="""
${__HELP_TITLE}Examples${__HELP_NORMAL}
mysql2puml dump.dql

mysqldump --skip-add-drop-table \
  --skip-add-locks \
  --skip-disable-keys \
  --skip-set-charset \
  --user=root \
  --password=root \
  --no-data skills | mysql2puml

${__HELP_TITLE}List of available skins:${__HELP_NORMAL}
@@@SKINS_LIST@@@"""
%

.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"

%
# shellcheck source=/dev/null
source <(
  Options::generateOption \
    --variable-type String \
    --help "header configuration of the plant uml file (default: ${optionSkinDefault})" \
    --alt "--skin" \
    --callback "optionSkinCallback" \
    --variable-name "optionSkin" \
    --function-name optionSkinFunction
  inputSqlFileCallback() { :; }
  Options::generateArg \
    --variable-name "inputSqlFile" \
    --min 0 \
    --max 1 \
    --name "inputSqlFile" \
    --callback inputSqlFileCallback \
    --help "sql filepath to parse (read from stdin if not provided)" \
    --function-name argumentInputSqlFileFunction
)
options+=(
  optionSkinFunction
  argumentInputSqlFileFunction
)
Options::generateCommand "${options[@]}"
%
declare copyrightBeginYear="2020"
declare optionBashFrameworkConfig="${BASH_TOOLS_ROOT_DIR}/.framework-config"
declare optionSkin="<% ${optionSkinDefault} %>"

optionHelpCallback() {
  local skinListHelpFile
  skinListHelpFile="$(Framework::createTempFile "shellcheckHelp")"
  Conf::getMergedList "mysql2pumlSkins" ".puml" "  - " >"${skinListHelpFile}"

  <% ${commandFunctionName} %> help |
    sed -E \
      -e "/@@@SKINS_LIST@@@/r ${skinListHelpFile}" \
      -e "/@@@SKINS_LIST@@@/d"
  exit 0
}

optionSkinCallback() {
  declare -a skinList
  readarray -t skinList < <(Conf::getMergedList "mysql2pumlSkins" ".puml" "")
  if ! Array::contains "$2" "${skinList[@]}"; then
    Log::displayError "${SCRIPT_NAME} - invalid skin '$2' provided"
    return 1
  fi
}

inputSqlFileCallback() {
  # shellcheck disable=SC2154
  if [[ ! -f "${inputSqlFile}" ]]; then
    Log::displayError "${SCRIPT_NAME} - File '${inputSqlFile}' does not exists"
    return 1
  fi
}
