%
declare versionNumber="2.0"
declare commandFunctionName="dbImportCommand"
declare help="Import source db into target db using eventual table filter"
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
${dsnList}

${__HELP_TITLE}Aws s3 location:${__HELP_NORMAL}
${S3_BASE_URL}

${__HELP_TITLE}Example 1: from one database to another one${__HELP_NORMAL}
${__HELP_EXAMPLE}TODO${__HELP_NORMAL}

${__HELP_TITLE}Example 2: import from S3${__HELP_NORMAL}
${__HELP_EXAMPLE}TODO${__HELP_NORMAL}'''
%

defaultFromDsnHelp="$(echo \
  "dsn to use for source database" $'\n' \
  "this option is incompatible with -a|--from-aws option" \
)"
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.dsn.tpl)"
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.profile.tpl)"
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.mysql.target.tpl)"
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.mysql.collationName.tpl)"

%
# shellcheck source=/dev/null
source <(
  Options::generateGroup \
    --title "FROM OPTIONS:" \
    --function-name groupSourceDbOptionsFunction

  Options::generateOption \
    --help "avoid to import the schema" \
    --group groupSourceDbOptionsFunction \
    --alt "--skip-schema" \
    --alt "-s" \
    --variable-name "optionSkipSchema" \
    --function-name optionSkipSchemaFunction

  # shellcheck disable=SC2116
  Options::generateOption \
    --help-value-name "awsFile" \
    --help "$(echo \
      "db dump will be downloaded from s3 instead of using remote db." \
      "The value <awsFile> is the name of the file without s3 location" \
      "(Only .gz or tar.gz file are supported)." \
      "This option is incompatible with -f|--from-dsn option" \
    )" \
    --group groupSourceDbOptionsFunction \
    --alt "--from-aws" \
    --alt "-a" \
    --variable-type "String" \
    --variable-name "optionFromAws" \
    --function-name optionFromAwsFunction

  Options::generateArg \
    --help "the name of the source/remote database" \
    --min 1 \
    --max 1 \
    --name "fromDbName" \
    --variable-name "fromDbName" \
    --function-name argumentFromDbNameFunction

  Options::generateArg \
    --help "the name of the target database, use fromDbName(without extension) if not provided" \
    --variable-name "targetDbName" \
    --min 0 \
    --max 1 \
    --name "targetDbName" \
    --function-name argumentTargetDbNameFunction
)
options+=(
  optionSkipSchemaFunction
  optionFromAwsFunction
  argumentFromDbNameFunction
  argumentTargetDbNameFunction
  --callback dbImportCommandCallback
)
Options::generateCommand "${options[@]}"
%

# default values
declare optionFromAws=""
declare optionSkipSchema="0"
declare targetDbName=""
declare fromDbName=""

# other configuration
declare copyrightBeginYear="2020"
declare TIMEFORMAT='time spent : %3R'
declare DB_IMPORT_DUMP_DIR=${DB_IMPORT_DUMP_DIR%/}
declare PROFILES_DIR="${BASH_TOOLS_ROOT_DIR}/conf/dbImportProfiles"
declare HOME_PROFILES_DIR="${HOME}/.bash-tools/dbImportProfiles"
declare DOWNLOAD_DUMP=0

optionHelpCallback() {
  local profilesList=""
  local dsnList=""
  dsnList="$(Conf::getMergedList "dsn" "env")"
  profilesList="$(Conf::getMergedList "dbImportProfiles" "sh" || true)"

  <% ${commandFunctionName} %> help | envsubst
  exit 0
}

dbImportCommandCallback() {
  if [[ -z "${targetDbName}" ]]; then
    targetDbName="${fromDbName}"
  fi

  if [[ -n "${optionFromAws}" ]]; then
    Assert::commandExists aws \
      "Command ${SCRIPT_NAME} - missing aws, please check https://docs.aws.amazon.com/fr_fr/cli/latest/userguide/install-cliv2.html" || exit 1

    if [[ -n "${optionFromDsn}" ]]; then
      Log::fatal "Command ${SCRIPT_NAME} - you cannot use from-dsn and from-aws at the same time"
    fi

    if [[ -z "${S3_BASE_URL}" ]]; then
      Log::fatal "Command ${SCRIPT_NAME} - missing S3_BASE_URL, please provide a value in .env file"
    fi
  elif [[ -z "${optionFromDsn}" ]]; then
    # default value for FROM_DSN if from-aws not set
    optionFromDsn="<% ${defaultFromDsn} %>"
  fi

  if [[ -z "${DB_IMPORT_DUMP_DIR}" ]]; then
    Log::fatal "Command ${SCRIPT_NAME} -you have to specify a value for DB_IMPORT_DUMP_DIR env variable"
  fi

  if [[ ! -d "${DB_IMPORT_DUMP_DIR}" ]]; then
    mkdir -p "${DB_IMPORT_DUMP_DIR}" ||
      Log::fatal "Command ${SCRIPT_NAME} -impossible to create directory ${DB_IMPORT_DUMP_DIR} specified by DB_IMPORT_DUMP_DIR env variable"
  fi
}
