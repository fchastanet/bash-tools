%
declare versionNumber="1.0"
declare commandFunctionName="mysql2pumlCommand"
declare optionSkinDefault="default"
declare help="convert mysql dump sql schema to plantuml format"
# shellcheck disable=SC2016
# kics-scan disable=487f4be7-3fd9-4506-a07a-eae252180c08
declare longDescription='''
${__HELP_TITLE}EXAMPLE 1:${__HELP_NORMAL}
${__HELP_EXAMPLE}mysql2puml dump.dql${__HELP_NORMAL}

${__HELP_TITLE}EXAMPLE 2:${__HELP_NORMAL}
${__HELP_EXAMPLE}mysqldump --skip-add-drop-table \
  --skip-add-locks \
  --skip-disable-keys \
  --skip-set-charset \
  --user=root \
  --password=root \
  --no-data skills | mysql2puml
${__HELP_NORMAL}
${__HELP_TITLE}LIST OF AVAILABLE SKINS:${__HELP_NORMAL}
@@@SKINS_LIST@@@'''
%

.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"

%
# shellcheck source=/dev/null
source <(
  Options::generateOption \
    --variable-type String \
    --help "header configuration of the plant uml file" \
    --default-value "${optionSkinDefault}" \
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

<% ${commandFunctionName} %> parse "${BASH_FRAMEWORK_ARGV[@]}"
