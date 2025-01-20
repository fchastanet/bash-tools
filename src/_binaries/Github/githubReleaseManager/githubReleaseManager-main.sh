#!/usr/bin/env bash
# shellcheck disable=SC2154

importInstallCallbacks() {
  InstallCallbacks::installDeb
  Github::defaultInstall
  Linux::Apt::install
  Linux::requireUbuntu
  InstallCallbacks::getVersion
  InstallCallbacks::installFromTarGz
}

forEachSoftware() {
  local configFile="${1}"
  local callback="${2}"
  shift 2 || true
  local softwareIds=("$@")
  local softwareId url version versionArg targetFile
  local sudo installCallback softVersionCallback

  # Process each software entry
  for softwareId in "${softwareIds[@]}"; do
    local software
    software="$(yq ".softwares[] | select(.id == \"${softwareId}\")" "${configFile}")"

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
      if command -v "${targetFile##*/}" &>/dev/null && [[ "$(command -v "${targetFile##*/}")" != "${targetFile}" ]]; then
        Log::displayWarning "Existing executable found at $(command -v "${targetFile##*/}")"
      fi
      "${callback}" \
        "${softwareId}" "${url}" "${version}" \
        "${versionArg}" "${targetFile}" "${sudo}" \
        "${installCallback}" "${softVersionCallback}"
    fi
  done
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
  # shellcheck disable=SC2034
  GH_WARNING_DISPLAYED=1
}

declare -a softwareIds
# Get all software entries if no specific IDs provided
if [[ ${#softwareIdsArg[@]} -eq 0 ]]; then
  readarray -t softwareIds < <(yq --raw-output '.softwares[].id' "${optionConfigFile}")
else
  softwareIds=("${softwareIdsArg[@]}")
fi

forEachSoftware \
  "${optionConfigFile}" installSoftware "${softwareIds[@]}"
