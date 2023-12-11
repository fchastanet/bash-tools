%
declare versionNumber="2.0"
declare commandFunctionName="upgradeGithubReleaseCommand"
declare help="retrieve latest binary release from github and install it"
# shellcheck disable=SC2016
declare longDescription
longDescription="$(
%
.INCLUDE "$(dynamicSrcFile "_binaries/Git/upgradeGithubRelease.help.txt")"
%
)"

# TODO find a way to not duplicate this info
declare defaultVersionArg="--version"
%

.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"

%
# shellcheck source=/dev/null
source <(
  targetFileArgCallback() { :; }
  Options::generateArg \
    --help $'the binary downloaded will be written to this file path.\n
      Ensure the path is writable.' \
    --min 1 \
    --max 1 \
    --name "targetFile" \
    --variable-name "targetFileArg" \
    --callback targetFileArgCallback \
    --function-name targetFileArgFunction

  githubUrlPatternArgCallback() { :; }
  # shellcheck disable=SC2116
  Options::generateArg \
    --help $'the url pattern to use to download the binary, see examples below.\n
      @version@ is template variable that will be replaced by the latest \n
      version tag found on github.' \
    --min 1 \
    --max 1 \
    --name "githubUrlPattern" \
    --variable-name "githubUrlPatternArg" \
    --callback githubUrlPatternArgCallback \
    --function-name githubUrlPatternArgFunction

  Options::generateGroup \
    --title "VERSION MANAGEMENT:" \
    --function-name groupVersionManagementFunction

  # shellcheck disable=SC2116,SC2016
  Options::generateOption \
    --help-value-name "versionArg" \
    --default-value "${defaultVersionArg}" \
    --help $'The argument that will be provided to the currently installed binary\n
      to check the version of the software. \n
      See options constraints below.' \
    --group groupVersionManagementFunction \
    --alt "--version-arg" \
    --variable-type "String" \
    --variable-name "optionVersionArg" \
    --function-name optionVersionArgFunction

  # shellcheck disable=SC2116
  Options::generateOption \
    --help-value-name "currentVersion" \
    --help $'Sometimes the command to retrieve the version is complicated. \n
      Some command needs you to parse json or other commands provides multiple \n
      sub command versions. In this case you can provide the version you \n
      currently have, see examples below. \n
      See options constraints below.' \
    --group groupVersionManagementFunction \
    --alt "--current-version" \
    --alt "-c" \
    --variable-type "String" \
    --variable-name "optionCurrentVersion" \
    --function-name optionCurrentVersionFunction

  # shellcheck disable=SC2116,SC2016
  Options::generateOption \
    --help-value-name "minimalVersion" \
    --help $'if provided and currently installed binary is below this \n
      minimalVersion, a new version of the binary will be installed. \n
      If this argument is not provided, the latest binary is unconditionally \n
      downloaded from github. \n
      See options constraints below.' \
    --group groupVersionManagementFunction \
    --alt "--minimal-version" \
    --alt "-m" \
    --variable-type "String" \
    --variable-name "optionMinimalVersion" \
    --function-name optionMinimalVersionFunction

  # shellcheck disable=SC2116,SC2016
  Options::generateOption \
    --help-value-name "exactVersion" \
    --help $'if provided and currently installed binary is not this exactVersion,\n
      This exact version of the binary will be installed.\n
      See options constraints below.' \
    --group groupVersionManagementFunction \
    --alt "--exact-version" \
    --alt "-e" \
    --variable-type "String" \
    --variable-name "optionExactVersion" \
    --function-name optionExactVersionFunction
)
options+=(
  targetFileArgFunction
  githubUrlPatternArgFunction
  optionVersionArgFunction
  optionCurrentVersionFunction
  optionExactVersionFunction
  optionMinimalVersionFunction
  --callback upgradeGithubReleaseCommandCallback
)
Options::generateCommand "${options[@]}"
%

upgradeGithubReleaseCommandCallback() {
  if [[ -n "${optionExactVersion}" && -n "${optionMinimalVersion}" ]]; then
    Log::fatal "--exact-version|-e and --minimal-version|-m are mutually exclusive, you cannot use both argument at the same time."
  fi
}

githubUrlPatternArgCallback() {
  if [[ ! "${githubUrlPatternArg}" =~ ^https://github.com/ ]]; then
    Log::fatal "Invalid githubUrlPattern ${githubUrlPatternArg} provided, it should begin with https://github.com/"
  fi
}

targetFileArgCallback() {
  if [[ "${targetFileArg:0:1}" != "/" ]]; then
    targetFileArg="$(pwd)/${targetFileArg}"
  fi
  if ! Assert::validPath "${targetFileArg}"; then
    Log::fatal "File ${targetFileArg} is not a valid path"
  fi
  if ! Assert::fileWritable "${targetFileArg}"; then
    Log::fatal "File ${targetFileArg} is not writable"
  fi
}

<% ${commandFunctionName} %> parse "${BASH_FRAMEWORK_ARGV[@]}"
