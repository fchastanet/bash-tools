#!/usr/bin/env bash

specificRequirements() {
  Linux::requireJqCommand
}

longDescriptionFunction() {
  echo -e "  ${__HELP_TITLE}GITHUB TEMPLATE URLS EXAMPLES:${__HELP_NORMAL}"
  echo
  echo -e "    Simple ones(Sometimes @version@ template variable has to be specified twice):${__HELP_EXAMPLE}"
  echo -e '    "https://github.com/hadolint/hadolint/releases/download/v@version@/hadolint-Linux-x86_64"'
  echo -e '    "https://github.com/koalaman/shellcheck/releases/download/v@version@/shellcheck-v@version@.linux.x86_64.tar.xz"'
  echo -e '    "https://github.com/sharkdp/fd/releases/download/v@version@/fd_@version@_amd64.deb"'
  echo -e '    "https://github.com/sharkdp/bat/releases/download/v@version@/bat_@version@_amd64.deb"'
  echo -e '    "https://github.com/kubernetes-sigs/kind/releases/download/v@version@/kind-linux-amd64"'
  echo -e '    "https://github.com/kubernetes/minikube/releases/download/v@version@/minikube-linux-amd64"'
  echo -e '    "https://github.com/plantuml/plantuml/releases/download/v@version@/plantuml-@version@.jar"'
  echo -e '    "https://github.com/Versent/saml2aws/releases/download/v@version@/saml2aws_@version@_linux_amd64.tar.gz"'
  echo -e "${__HELP_NORMAL}"
  echo -e "    If you want to add a condition on architecture(linux, windows, x86, 64/32 bits):${__HELP_EXAMPLE}"
  # shellcheck disable=SC2016
  echo -e '    "https://github.com/docker/compose/releases/download/v@version@/docker-compose-$(uname -s | tr "[:upper:]" "[:lower:]")-$(uname -m)"'
  # shellcheck disable=SC2016
  echo -e '    "https://github.com/docker/docker-credential-helpers/releases/download/v@version@/docker-credential-wincred-v@version@.windows-$(dpkg --print-architecture).exe"'
  # shellcheck disable=SC2016
  echo -e '    "https://github.com/Blacksmoke16/oq/releases/download/v@version@/oq-v@version@-$(uname -s)-$(uname -m)"'
  echo -e "${__HELP_NORMAL}"
  echo -e "  ${__HELP_TITLE}COMMAND EXAMPLES:${__HELP_NORMAL}"
  echo -e "${__HELP_NORMAL}"
  echo -e "    Download docker-compose latest version${__HELP_EXAMPLE}"
  echo -e "    upgradeGithubRelease /usr/local/bin/docker-compose \\"
  # shellcheck disable=SC2016
  echo -e '      "https://github.com/docker/compose/releases/download/v@version@/docker-compose-$(uname -s | tr "[:upper:]" "[:lower:]")-$(uname -m)"'
  echo -e "${__HELP_NORMAL}"
  echo -e "    Download oq specific version${__HELP_EXAMPLE}"
  echo -e "    upgradeGithubRelease /usr/local/bin/oq --exact-version 1.3.4 \\"
  # shellcheck disable=SC2016
  echo -e '      "https://github.com/Blacksmoke16/oq/releases/download/v@version@/oq-v@version@-$(uname -s)-$(uname -m)"'
  echo -e "${__HELP_NORMAL}"
  echo -e "    Download oq specific version correctly retrieving the oq version and not the jq one${__HELP_EXAMPLE}"
  echo -e "    upgradeGithubRelease /usr/local/bin/oq --exact-version 1.3.4 --version-arg '-V | grep oq:' \\"
  # shellcheck disable=SC2016
  echo -e '      "https://github.com/Blacksmoke16/oq/releases/download/v@version@/oq-v@version@-$(uname -s)-$(uname -m)"'
  echo -e "${__HELP_NORMAL}"
}

githubUrlPatternHelpFunction() {
  echo '    The url pattern to use to download the binary, see examples below.'
  echo '    @version@ is template variable that will be replaced by the latest'
  echo '      version tag found on github.'
}

optionCurrentVersionHelpFunction() {
  echo '    Sometimes the command to retrieve the version is complicated.'
  echo '    Some command needs you to parse json or other commands'
  echo '    that provides multiple sub command versions.'
  echo '    In this case you can provide the version you currently have.'
  echo '    See options constraints and examples below.'
}

exactVersionHelpFunction() {
  echo '    If provided and currently installed binary is not this exactVersion,'
  echo '    this exact version of the binary will be installed.'
  echo '    See options constraints below.'
}

optionHelpCallback() {
  upgradeGithubReleaseCommandHelp
  exit 0
}

githubUrlPatternArgCallback() {
  # shellcheck disable=SC2154
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
