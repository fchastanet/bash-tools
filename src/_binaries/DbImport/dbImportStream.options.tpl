%
declare versionNumber="2.0"
declare commandFunctionName="dbImportStreamCommand"
declare help="stream tar.gz file or gz file through mysql"
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
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.profile.tpl)"
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.mysql.target.tpl)"

%
# shellcheck source=/dev/null
source <(

  Options::generateArg \
    --help "the of the file that will be streamed through mysql" \
    --min 1 \
    --max 1 \
    --name "argDumpFile" \
    --variable-name "argDumpFile" \
    --function-name argDumpFileFunction

  Options::generateArg \
    --help "the name of the mysql target database" \
    --min 1 \
    --max 1 \
    --name "argTargetDbName" \
    --variable-name "argTargetDbName" \
    --function-name argTargetDbNameFunction

)
options+=(
  argDumpFileFunction
  argTargetDbNameFunction
  --callback dbImportStreamCommandCallback
)
Options::generateCommand "${options[@]}"
%

.INCLUDE "$(dynamicTemplateDir _includes/dbTools.requirements.tpl)"

optionHelpCallback() {
  local profilesList=""
  local dsnList=""
  dsnList="$(Conf::getMergedList "dsn" "env")"
  profilesList="$(Conf::getMergedList "dbImportProfiles" "sh" || true)"

  <% ${commandFunctionName} %> help | envsubst
  checkRequirements
  exit 0
}

dbImportStreamCommandCallback() {
  if [[ -z "${argTargetDbName}" ]]; then
    Log::fatal "you must provide argTargetDbName"
  fi
  if [[ ! -f "${argDumpFile}" ]]; then
    Log::fatal "invalid argDumpFile provided - file does not exist"
  fi
}

<% ${commandFunctionName} %> parse "${BASH_FRAMEWORK_ARGV[@]}"
