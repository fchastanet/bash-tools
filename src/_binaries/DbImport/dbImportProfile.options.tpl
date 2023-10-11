%
declare versionNumber="2.0"
declare commandFunctionName="dbImportProfileCommand"
declare help="generate optimized profiles to be used by dbImport"
# shellcheck disable=SC2016
declare longDescription='''
${__HELP_TITLE}Default profiles directory:${__HELP_NORMAL}
${PROFILES_DIR-configuration error}

${__HELP_TITLE}User profiles directory:${__HELP_NORMAL}
${HOME_PROFILES_DIR-configuration error}
Allows to override profiles defined in "Default profiles directory"

${__HELP_TITLE}List of available profiles:${__HELP_NORMAL}
${profilesList}

${__HELP_TITLE}List of available dsn:${__HELP_NORMAL}
${dsnList}'''
declare defaultFromDsn="default.remote"
%

.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"

%
# shellcheck source=/dev/null
source <(
  # shellcheck disable=SC2116
  Options::generateOption \
    --help "$(echo \
      "the name of the profile to write in profiles directory. " \
      "If not provided, the file name pattern will be 'auto_<dsn>_<fromDbName>.sh'" \
    )" \
    --variable-type "String" \
    --alt "--profile" \
    --alt "-p" \
    --variable-name "optionProfile" \
    --function-name optionProfileFunction

  # shellcheck disable=SC2116
  Options::generateOption \
    --help "$(echo \
      "dsn to use for source database (Default: ${defaultFromDsn})" \
      "if not provided, the file name pattern will be 'auto_<dsn>_<fromDbName>.sh'" \
    )" \
    --variable-type "String" \
    --alt "--from-dsn" \
    --alt "-f" \
    --variable-name "optionFromDsn" \
    --function-name optionFromDsnFunction

  # shellcheck disable=SC2116
  Options::generateOption \
    --help "$(echo -e "define the ratio to use (0 to 100% - default 70). " \
      "0 means profile will filter out all the tables. " \
      "100 means profile will keep all the tables. " \
      "Eg: 70 means that tables with size(table+index) that are greater that 70% of the max table size will be excluded." \
    )" \
    --variable-type "String" \
    --alt "--ratio" \
    --alt "-r" \
    --variable-name "optionRatio" \
    --function-name optionRatioFunction

  Options::generateArg \
    --help "the name of the source/remote database" \
    --min 1 \
    --max 1 \
    --name "fromDbName" \
    --variable-name "fromDbName" \
    --function-name argumentFromDbNameFunction
)
options+=(
  optionProfileFunction
  optionFromDsnFunction
  optionRatioFunction
  argumentFromDbNameFunction
  --callback dbImportProfileCommandCallback
)
Options::generateCommand "${options[@]}"
%

# default values
declare optionProfile=""
declare fromDbName="" # old FROM_DB
declare optionFromDsn="<% ${defaultFromDsn} %>" # old FROM_DSN
declare optionRatio=70 # old RATIO

# other configuration
declare copyrightBeginYear="2020"
declare PROFILES_DIR="${BASH_TOOLS_ROOT_DIR}/conf/dbImportProfiles"
declare HOME_PROFILES_DIR="${HOME}/.bash-tools/dbImportProfiles"

optionHelpCallback() {
  local profilesList=""
  local dsnList=""
  dsnList="$(Conf::getMergedList "dsn" "env")"
  profilesList="$(Conf::getMergedList "dbImportProfiles" "sh" || true)"

  <% ${commandFunctionName} %> help | envsubst
  exit 0
}

dbImportProfileCommandCallback() {
  if [[ -z "${fromDbName}" ]]; then
    Log::fatal "you must provide fromDbName"
  fi

  if [[ -z "${optionProfile}" ]]; then
    optionProfile="auto_${optionFromDsn}_${fromDbName}.sh"
  fi

  if ! [[ "${optionRatio}" =~ ^-?[0-9]+$ ]]; then
    Log::fatal "Ratio value should be a number"
  fi

  if ((optionRatio < 0 || optionRatio > 100)); then
    Log::fatal "Ratio value should be between 0 and 100"
  fi
}
