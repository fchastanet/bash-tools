#!/usr/bin/env bash
# shellcheck disable=SC2154

importInstallCallbacks() {
  InstallCallbacks::installDeb
  Github::defaultInstall
  Linux::Apt::install
  Linux::requireUbuntu
  InstallCallbacks::getVersion
  InstallCallbacks::installFromTarGz
  InstallCallbacks::installFromTarXz
}

forEachSoftware() {
  local configFile="${1}"
  shift 2 || true
  local softwareIds=("$@")

  # Run installations in parallel using xargs
  printf "%s\n" "${softwareIds[@]}" |
    SKIP_YAML_CHECKS=1 xargs -P "$(nproc)" -I {} \
      "${BASH_SOURCE[0]}" \
      -c "${optionConfigFile}" \
      "{}" 2>&1
}

processSingleSoftware() {
  local configFile="${1}"
  local softwareId="${2}"

  local software
  software="$(yq ".softwares[] | select(.id == \"${softwareId}\")" "${configFile}")"
  # shellcheck disable=SC2034
  LOG_CONTEXT="Software ${softwareId} - "
  if [[ -n "${software}" ]]; then
    url="$(echo "${software}" | yq --raw-output '.url' -)"
    version="$(echo "${software}" | yq --raw-output '.version' -)"
    versionArg="$(echo "${software}" | yq --raw-output '.versionArg' -)"
    targetFile="$(echo "${software}" | yq --raw-output '.targetFile' -)"
    sudo="$(echo "${software}" | yq --raw-output '.sudo' -)"
    installCallback="$(echo "${software}" | yq --raw-output '.installCallback' -)"
    if [[ -z "${installCallback}" || "${installCallback}" = "null" ]]; then
      installCallback="Github::defaultInstall"
    fi
    softVersionCallback="$(echo "${software}" | yq --raw-output '.softVersionCallback' -)"
    if [[ -z "${softVersionCallback}" || "${softVersionCallback}" = "null" ]]; then
      softVersionCallback="Version::getCommandVersionFromPlainText"
    fi

    installSoftware \
      "${softwareId}" "${url}" "${version}" \
      "${versionArg}" "${targetFile}" "${sudo}" \
      "${installCallback}" "${softVersionCallback}"
  fi
}

installSoftware() {
  local softwareId="${1}"
  local githubUrlPattern="${2}"
  local version="${3}"
  local versionArg="${4}"
  local targetFileArg="${5}"
  local sudo="${6}"
  local installCallback="${7:-Github::defaultInstall}"
  local softVersionCallback="${8:-Version::getCommandVersionFromPlainText}"
  if [[ "${sudo}" == "null" ]]; then
    sudo=""
  fi
  local githubUrl
  # shellcheck disable=SC2097,SC2098
  githubUrl="$(
    ARCH="$(dpkg --print-architecture)" \
    arch="${ARCH,,}" \
    KERNEL="$(uname -s)" \
    kernel="${KERNEL,,}" \
    MACHINE="$(uname -m)" \
    machine="${MACHINE,,}" \
    OS="$(uname -s)" \
    os="${OS,,}" \
      eval echo "${githubUrlPattern}"
  )"
  local targetFile
  targetFile="$(eval echo "${targetFileArg}")"
  Log::displayInfo "Installing ${softwareId}..."
  echo "  URL pattern: ${githubUrlPattern}"
  echo "  URL: ${githubUrl}"
  echo "  Version: ${version}"
  echo "  Target file: ${targetFile}"
  echo "  Sudo: ${sudo}"
  echo "  Install callback: ${installCallback}"
  echo "  Soft version callback: ${softVersionCallback}"
  local exactVersion
  if [[ "${version}" == "latest" ]]; then
    exactVersion=""
  else
    exactVersion="${version}"
  fi

  if ! SUDO="${sudo}" \
    VERSION_PLACEHOLDER="@version@" EXACT_VERSION="${exactVersion}" \
    SOFT_VERSION_CALLBACK="${softVersionCallback}" \
    Github::upgradeRelease \
    "${targetFile}" \
    "${githubUrl}" \
    "${versionArg}" \
    "${softVersionCallback}" \
    "${installCallback}"; then
    Log::displayError "Failed to install ${softwareId}"
  fi
}
if command -v gh &>/dev/null; then
  if [[ -z "${SKIP_YAML_CHECKS:-}" && -z "${GH_TOKEN}" ]]; then
    if gh auth status | grep -q "Logged in to github.com"; then
      GH_TOKEN="$(gh auth token)"
      export GH_TOKEN
    fi
  fi
  if [[ -z "${GH_TOKEN}" ]]; then
    Log::displayWarning "GH_TOKEN is not set, cannot use gh, using curl to retrieve release versions list"
    export GH_WARNING_DISPLAYED=1
  fi
fi

declare -a softwareIds
# Get all software entries if no specific IDs provided
if [[ ${#softwareIdsArg[@]} -eq 0 ]]; then
  readarray -t softwareIds < <(yq --raw-output '.softwares[].id' "${optionConfigFile}")
else
  softwareIds=("${softwareIdsArg[@]}")
fi
if [[ ${#softwareIds[@]} -eq 1 ]]; then
  processSingleSoftware "${optionConfigFile}" "${softwareIds[0]}"
else
  forEachSoftware \
    "${optionConfigFile}" "${softwareIds[@]}"
fi
