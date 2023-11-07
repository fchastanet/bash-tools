%
declare versionNumber="2.0"
declare commandFunctionName="upgradeGithubReleaseCommand"
declare help="retrieve latest binary release from github and install it"
declare example1=$'\\"https://github.com/docker/compose/releases/download/v@version@/docker-compose-\$(uname -s | tr \'[:upper:]\' \'[:lower:]\')-\$(uname -m)\\"'
declare example2=$'\\"https://github.com/docker/docker-credential-helpers/releases/download/v@version@/docker-credential-wincred-v@version@.windows-\$(dpkg --print-architecture).exe\\"'
declare example3=$'\\"https://github.com/Blacksmoke16/oq/releases/download/v@version@/oq-v@version@-\$(uname -s)-\$(uname -m)\\"'
declare longDescription="""
${__HELP_TITLE}OPTIONS EXCEPTIONS:${__HELP_NORMAL}

${__HELP_EXAMPLE}--current-version${__HELP_NORMAL}|${__HELP_EXAMPLE}-c${__HELP_NORMAL} and ${__HELP_EXAMPLE}--version-arg${__HELP_NORMAL} are mutually exclusive,
you cannot use both argument at the same time.

${__HELP_EXAMPLE}--exact-version${__HELP_NORMAL}|${__HELP_EXAMPLE}-e${__HELP_NORMAL} and ${__HELP_EXAMPLE}--minimal-version${__HELP_NORMAL}|${__HELP_EXAMPLE}-m${__HELP_NORMAL} are mutually exclusive,
you cannot use both argument at the same time.

${__HELP_TITLE}GITHUB TEMPLATE URLS EXAMPLES:${__HELP_NORMAL}

Simple ones(Sometimes @version@ template variable has to be specified twice):
'https://github.com/hadolint/hadolint/releases/download/v@version@/hadolint-Linux-x86_64'
'https://github.com/koalaman/shellcheck/releases/download/v@version@/shellcheck-v@version@.linux.x86_64.tar.xz'
'https://github.com/sharkdp/fd/releases/download/v@version@/fd_@version@_amd64.deb'
'https://github.com/sharkdp/bat/releases/download/v@version@/bat_@version@_amd64.deb'
'https://github.com/kubernetes-sigs/kind/releases/download/v@version@/kind-linux-amd64'
'https://github.com/kubernetes/minikube/releases/download/v@version@/minikube-linux-amd64'
'https://github.com/plantuml/plantuml/releases/download/v@version@/plantuml-@version@.jar'
'https://github.com/Versent/saml2aws/releases/download/v@version@/saml2aws_@version@_linux_amd64.tar.gz'

If you want to add a condition on architecture(linux, windows, x86, 64/32 bits):
${example1}
${example2}
${example3}

${__HELP_TITLE}COMMAND EXAMPLES:${__HELP_NORMAL}
Download docker-compose latest version
${__HELP_EXAMPLE}upgradeGithubRelease /usr/local/bin/docker-compose ${example1}${__HELP_NORMAL}

Download oq specific version
${__HELP_EXAMPLE}upgradeGithubRelease /usr/local/bin/oq --exact-version 1.3.4 ${example3}${__HELP_NORMAL}

Download oq specific version correctly retrieving the oq version and not the jq one
${__HELP_EXAMPLE}upgradeGithubRelease /usr/local/bin/oq --exact-version 1.3.4 --version-arg '-V | grep oq:' ${example3}${__HELP_NORMAL}
"""
# TODO find a way to not duplicate this info
declare defaultVersionArg="--version"
%

.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"

%
# shellcheck source=/dev/null
source <(
  targetFileArgCallback() { :; }
  Options::generateArg \
    --help "the binary downloaded will e written to this file path. Ensure the path is writable." \
    --min 1 \
    --max 1 \
    --name "targetFile" \
    --variable-name "targetFileArg" \
    --callback targetFileArgCallback \
    --function-name targetFileArgFunction

  githubUrlPatternArgCallback() { :; }
  # shellcheck disable=SC2116
  Options::generateArg \
    --help "$(echo \
        "the url pattern to use to download the binary, see examples below." $'\n' \
        "@version@ is template variable that will be replaced by the latest"  $'\n' \
        "version tag found on github." \
      )" \
    --min 1 \
    --max 1 \
    --name "githubUrlPattern" \
    --variable-name "githubUrlPatternArg" \
    --callback githubUrlPatternArgCallback \
    --function-name githubUrlPatternArgFunction

  Options::generateGroup \
    --title "VERSION MANAGEMENT:" \
    --function-name groupVersionManagementFunction

  # shellcheck disable=SC2116
  Options::generateOption \
    --help-value-name "versionArg" \
    --default-value "${defaultVersionArg}" \
    --help "$(echo \
      "The argument that will be provided to the currently installed binary " \
      "to check the version of the software." $'\n' \
      "This parameter is needed if ${__HELP_EXAMPLE}--minimal-version${__HELP_NORMAL} argument is used and is " \
      "different than default value (${__HELP_EXAMPLE}${defaultVersionArg}${__HELP_NORMAL})." \
    )" \
    --group groupVersionManagementFunction \
    --alt "--version-arg" \
    --variable-type "String" \
    --variable-name "optionVersionArg" \
    --function-name optionVersionArgFunction

  # shellcheck disable=SC2116
  Options::generateOption \
    --help-value-name "currentVersion" \
    --help "$(echo \
      "Sometimes the command to retrieve the version is complicated. "  $'\n' \
      "Some command needs you to parse json or other commands provides " \
      "multiple sub command versions. In this case you can provide the " \
      "version you currently have, see examples below."
    )" \
    --group groupVersionManagementFunction \
    --alt "--current-version" \
    --alt "-c" \
    --variable-type "String" \
    --variable-name "optionCurrentVersion" \
    --function-name optionCurrentVersionFunction

  # shellcheck disable=SC2116
  Options::generateOption \
    --help-value-name "minimalVersion" \
    --help "$(echo \
      "if provided and currently installed binary is below this ${__HELP_EXAMPLE}minimalVersion${__HELP_NORMAL},"  $'\n' \
      "a new version of the binary will be installed."  $'\n' \
      "If this argument is not provided, the latest binary is unconditionally downloaded from github." \
    )" \
    --group groupVersionManagementFunction \
    --alt "--minimal-version" \
    --alt "-m" \
    --variable-type "String" \
    --variable-name "optionMinimalVersion" \
    --function-name optionMinimalVersionFunction

  # shellcheck disable=SC2116
  Options::generateOption \
    --help-value-name "exactVersion" \
    --help "$(echo \
      "if provided and currently installed binary is not this ${__HELP_EXAMPLE}exactVersion${__HELP_NORMAL},"  $'\n' \
      "This exact version of the binary will be installed." \
    )" \
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
