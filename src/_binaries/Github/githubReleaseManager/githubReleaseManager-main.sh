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
  shift || true
  local -a softwareIds=("$@")

  local theme="${optionTheme}"
  if [[ "${theme}" != "noColor" ]]; then
    theme="default-force"
  fi
  # Run installations in parallel using xargs
  local cmd="${BASH_SOURCE[0]}"
  export cmd optionConfigFile theme
  callSoft() {
    local soft="$1"
    SKIP_YAML_CHECKS=1 LOG_CONTEXT="Software ${soft} - " "${cmd}" \
      --theme "${theme}" -c "${optionConfigFile}" "${soft}"
  }
  export -f callSoft

  if command -v parallel &>/dev/null; then
    parallel -j "$(nproc)" callSoft ::: "${softwareIds[@]}"
  else
    printf "%s\n" "${softwareIds[@]}" |
      xargs --no-run-if-empty -n 1 -P "$(nproc)" -I {} bash -c 'callSoft "$@"' _ {}
  fi

}

processSingleSoftware() {
  local configFile="${1}"
  local softwareId="${2}"

  local software
  software="$(yq ".softwares[] | select(.id == \"${softwareId}\")" "${configFile}")"
  # shellcheck disable=SC2034
  LOG_CONTEXT="Software ${softwareId} - "
  if [[ -n "${software}" ]]; then
    local url=""
    local version=""
    local versionArg=""
    local targetFile=""
    local sudo=""
    local installCallback=""
    local softVersionCallback=""
    # shellcheck source=/dev/null
    source <(
      yq -r \
        ".softwares[] | select(.id == \"${softwareId}\") | to_entries[] | \"\(.key)=\(.value)\"" \
        "${configFile}" | sed -E \
        -e '/^$/d' \
        -e 's/^([^=]+)=["\x27]*(.*)$/\1="\2/' \
        -e 's/["\x27]*$/"/'
    )
    if [[ -z "${installCallback}" || "${installCallback}" = "null" ]]; then
      installCallback="Github::defaultInstall"
    fi
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
  local githubUrl="${2}"
  local version="${3}"
  local versionArg="${4}"
  local targetFileArg="${5}"
  local sudo="${6}"
  local installCallback="${7:-Github::defaultInstall}"
  local softVersionCallback="${8:-Version::getCommandVersionFromPlainText}"
  if [[ "${sudo}" == "null" ]]; then
    sudo=""
  fi
  local targetFile
  targetFile="$(eval echo "${targetFileArg}")"
  Log::displayInfo "Installing ${softwareId}..."
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
  readarray -t softwareIds < <(yq '.softwares[].id' "${optionConfigFile}")
else
  softwareIds=("${softwareIdsArg[@]}")
fi

# shellcheck disable=SC2034
declare -g ARCH KERNEL MACHINE OS arch kernel machine os
ARCH="$(dpkg --print-architecture)"
# shellcheck disable=SC2034
arch="${ARCH,,}"
KERNEL="$(uname -s)"
# shellcheck disable=SC2034
kernel="${KERNEL,,}"
MACHINE="$(uname -m)"
# shellcheck disable=SC2034
machine="${MACHINE,,}"
OS="$(uname -s)"
# shellcheck disable=SC2034
os="${OS,,}"

if [[ ${#softwareIds[@]} -eq 1 ]]; then
  processSingleSoftware "${optionConfigFile}" "${softwareIds[0]}"
else
  forEachSoftware \
    "${optionConfigFile}" "${softwareIds[@]}"
fi
