#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/upgradeGithubRelease

.INCLUDE "$(dynamicTemplateDir _headerNoFrameworkDependency.tpl)"

#default values
TARGET_FILE=""
VERSION_ARG="--version"
MIN_VERSION=""
CURRENT_VERSION=""
EXACT_VERSION=""
GITHUB_URL_PATTERN=""

# Usage info
showHelp() {
  cat <<EOF
${__HELP_TITLE}Description:${__HELP_NORMAL} retrieve latest binary release from github and install it

${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} [-h|--help] prints this help and exits
${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} <targetFile> <githubUrlPattern>
    [--version-arg <versionArg>]
    [--minimal-version|-m <minimalVersion>]
    [--current-version|-c <currentVersion>]
    [--exact-version|-e <exactVersion>]

    --help,-h prints this help and exits

    --version-arg <versionArg>: The argument that will be provided to the currently installed binary
      to check the version of the software. This parameter is needed if --minimal-version
      argument is used and is different than default value (--version).

    --current-version|-c <currentVersion>: sometimes the command to retrieve the version is complicated
      some command needs you to parse json or other commands provides multiple sub command versions.
      In this case you can provide the version you currently have, see examples below.

    --minimal-version|-m <minimalVersion>: if provided, if currently installed binary is below
      this minimalVersion, a new version of the binary will be installed. If this argument is not
      provided, the latest binary is unconditionally downloaded from github.

    --current-version|-c and --version-arg are mutually exclusive, you cannot use both argument at the
      same time.

    --exact-version|-e and --minimal-version|-m are mutually exclusive, you cannot use both argument at
      the same time.

    <targetFile> the binary downloaded will e written to this file path. Ensure the path is writable.
    <githubUrlPattern> the url pattern to use to download the binary, see examples below.
      @version@ is template variable that will be replaced by the latest version tag found on
      github.

${__HELP_TITLE}Github template urls examples:${__HELP_NORMAL}

Simple ones(Sometimes @version@ template variable has to be specified twice):
"https://github.com/hadolint/hadolint/releases/download/v@version@/hadolint-Linux-x86_64"
"https://github.com/koalaman/shellcheck/releases/download/v@version@/shellcheck-v@version@.linux.x86_64.tar.xz"
"https://github.com/sharkdp/fd/releases/download/v@version@/fd_@version@_amd64.deb"
"https://github.com/sharkdp/bat/releases/download/v@version@/bat_@version@_amd64.deb"
'https://github.com/kubernetes-sigs/kind/releases/download/v@version@/kind-linux-amd64'
"https://github.com/kubernetes/minikube/releases/download/v@version@/minikube-linux-amd64"
"https://github.com/plantuml/plantuml/releases/download/v@version@/plantuml-@version@.jar"
"https://github.com/Versent/saml2aws/releases/download/v@version@/saml2aws_@version@_linux_amd64.tar.gz"

If you want to add condition on architecture(linux, windows, x86, 64/32 bits):
"https://github.com/docker/compose/releases/download/v@version@/docker-compose-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)"
"https://github.com/docker/docker-credential-helpers/releases/download/v@version@/docker-credential-wincred-v@version@.windows-$(dpkg --print-architecture).exe"
"https://github.com/Blacksmoke16/oq/releases/download/v@version@/oq-v@version@-$(uname -s)-$(uname -m)"

${__HELP_TITLE}Command examples:${__HELP_NORMAL}
upgradeGithubRelease

.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/author.tpl"
EOF
}

# read command parameters
# $@ is all command line parameters passed to the script.
# -o is for short options like -h
# -l is for long options with double dash like --help
# the comma separates different long options
options=$(getopt \
  -l help,version-arg:,minimal-version:,current-version:,exact-version: \
  -o hm:c:e: -- "$@" 2>/dev/null) || {
  showHelp
  Log::fatal "invalid options specified"
}

eval set -- "${options}"
while true; do
  case $1 in
    -h | --help)
      showHelp
      exit 0
      ;;
    --version-arg)
      shift || true
      VERSION_ARG="$1"
      ;;
    --minimal-version | -m)
      shift || true
      MIN_VERSION="$1"
      ;;
    --current-version | -c)
      shift || true
      CURRENT_VERSION="$1"
      ;;
    --exact-version | -e)
      shift || true
      EXACT_VERSION="$1"
      ;;
    --)
      shift || true
      break
      ;;
    *)
      Log::fatal "invalid argument $1"
      ;;
  esac
  shift || true
done
shift $((OPTIND - 1)) || true

if [[ -n "${EXACT_VERSION}" && -n "${MIN_VERSION}" ]]; then
  Log::fatal "--exact-version|-e and --minimal-version|-m are mutually exclusive, you cannot use both argument at the same time."
fi
if (($# != 2)); then
  Log::fatal "Exactly 2 fixed arguments are required"
fi
TARGET_FILE="$1"
GITHUB_URL_PATTERN="$2"

if [[ ! "${GITHUB_URL_PATTERN}" =~ ^https://github.com/ ]]; then
  Log::fatal "Invalid githubUrlPattern ${GITHUB_URL_PATTERN} provided, it should begin with https://github.com/"
fi

if [[ "${TARGET_FILE:0:1}" != "/" ]]; then
  TARGET_FILE="$(pwd)/${TARGET_FILE}"
fi
if ! Assert::validPath "${TARGET_FILE}"; then
  Log::fatal "File ${TARGET_FILE} is not a valid path"
fi
if ! Assert::fileWritable "${TARGET_FILE}"; then
  Log::fatal "File ${TARGET_FILE} is not writable"
fi

# if minVersion arg provided, we have to compute current bin version
TRY_DOWNLOAD_NEW_VERSION=1
if [[ -f "${TARGET_FILE}" ]]; then
  if [[ -n "${MIN_VERSION}" ]]; then
    if [[ -z "${CURRENT_VERSION}" && -n "${VERSION_ARG}" ]]; then
      if Version::checkMinimal "${TARGET_FILE}" "${VERSION_ARG}" "${MIN_VERSION}"; then
        TRY_DOWNLOAD_NEW_VERSION=0
      fi
    elif [[ -n "${CURRENT_VERSION}" ]]; then
      versionCompare=0
      Version::compare "${CURRENT_VERSION}" "${MIN_VERSION}" || versionCompare=$?
      # do not try to down version if current version is greater or equal to min version
      if [[ "${versionCompare}" = "1" ]]; then
        # current version > min version
        TRY_DOWNLOAD_NEW_VERSION=0
        Log::displayWarning "${TARGET_FILE} version is ${CURRENT_VERSION} greater than ${MIN_VERSION}"
      elif [[ "${versionCompare}" = "2" ]]; then
        # current version < min version
        Log::displayError "${TARGET_FILE} minimal version is ${MIN_VERSION}, your version is ${CURRENT_VERSION}"
      else
        TRY_DOWNLOAD_NEW_VERSION=0
        Log::displayStatus "${TARGET_FILE} version is the required minimal version ${MIN_VERSION}"
      fi
    fi
  elif [[ -n "${EXACT_VERSION}" ]]; then
    if [[ -z "${CURRENT_VERSION}" && -n "${VERSION_ARG}" ]]; then
      CURRENT_VERSION="$("${TARGET_FILE}" "${VERSION_ARG}" 2>&1 | Version::parse)"
    fi
    if Version::compare "${CURRENT_VERSION}" "${EXACT_VERSION}"; then
      TRY_DOWNLOAD_NEW_VERSION=0
      Log::displayStatus "${TARGET_FILE} version is the exact required version ${EXACT_VERSION}"
    else
      Log::displayWarning "${TARGET_FILE} version ${CURRENT_VERSION} is different than required version ${EXACT_VERSION}"
    fi
  fi
fi

if [[ "${TRY_DOWNLOAD_NEW_VERSION}" = "0" ]]; then
  exit 0
fi

if [[ -z "${EXACT_VERSION}" ]]; then
  EXACT_VERSION="$(Github::getLatestVersionFromUrl "${GITHUB_URL_PATTERN}")"
fi
GITHUB_URL="$(echo "${GITHUB_URL_PATTERN}" | sed -E "s/@version@/${EXACT_VERSION}/g")"
Log::displayInfo "Using url ${GITHUB_URL}"

newSoftware=$(Github::downloadReleaseVersion "${GITHUB_URL}")
Github::defaultInstall "${newSoftware}" "${TARGET_FILE}"
Log::displayStatus "Version ${EXACT_VERSION} installed in ${TARGET_FILE}"
