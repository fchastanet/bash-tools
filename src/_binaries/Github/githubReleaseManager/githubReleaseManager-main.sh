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
  Git::cloneOrPullIfNoChanges
  Git::requireGitCommand
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

  local id=""
  local url=""
  local version=""
  local versionArg=""
  local targetFile=""
  local sudo=""
  local installCallback=""
  local softVersionCallback=""
  local type=""
  local installScript=""
  local targetDir=""
  local cloneOptions=""
  local branch=""

  # shellcheck source=/dev/null
  source <(
    yq -o shell -r \
      ".softwares[] | select(.id == \"${softwareId}\") | del(.installScript)" \
      "${configFile}" | sed -E \
      -e '/^$/d' \
      -e 's/^([^=]+)=["\x27]*(.*)$/\1="\2/' \
      -e 's/["\x27]*$/"/'
  )
  if [[ -z "${id}" ]]; then
    return 0
  fi
  # shellcheck disable=SC2034
  LOG_CONTEXT="Software ${softwareId} - "
  if [[ -z "${installCallback}" || "${installCallback}" = "null" ]]; then
    installCallback="Github::defaultInstall"
  fi
  if [[ -z "${softVersionCallback}" || "${softVersionCallback}" = "null" ]]; then
    softVersionCallback="Version::getCommandVersionFromPlainText"
  fi
  if [[ -z "${type}" || "${type}" == "null" ]]; then
    type="githubRelease"
  fi
  if [[ "${type}" == "gitClone" ]]; then
    installScript="$(yq -r ".softwares[] | select(.id == \"${softwareId}\") | .installScript" "${configFile}")"
    if [[ "${installScript}" = "null" ]]; then
      installScript=""
    fi
    if [[ -z "${targetDir}" || "${targetDir}" == "null" ]]; then
      Log::displayError "targetDir is required for gitClone type"
      return 1
    fi
    installUsingGitClone \
      "${softwareId}" "${url}" "${sudo}" \
      "${targetDir}" "${branch}" "${cloneOptions}" "${installScript}"
  else
    installGithubRelease \
      "${softwareId}" "${url}" "${version}" \
      "${versionArg}" "${targetFile}" "${sudo}" \
      "${installCallback}" "${softVersionCallback}"
  fi
}

installUsingGitClone() {
  local softwareId="${1}"
  local githubUrl="${2}"
  local sudo="${3}"
  local targetDir="${4}"
  local branch="${5:-master}"
  local cloneOptions="${6:-}"
  local installScript="${7:-}"

  if [[ "${sudo}" == "null" ]]; then
    sudo=""
  fi
  Log::displayInfo "Installing ${softwareId}..."
  echo "  Type: Git Clone"
  echo "  URL: ${githubUrl}"
  echo "  Sudo: ${sudo}"
  echo "  Branch: ${branch}"
  echo "  Clone options: ${cloneOptions}"
  echo "  Target dir: ${targetDir}"
  if [[ -n "${installScript}" ]]; then
    echo "  Install script: Yes"
  fi
  function changeBranch() {
    local dir="$1"
    (
      cd "${dir}" || return 1
      "${sudo:-}" git checkout "${branch}"
    )
  }
  if ! SUDO="${sudo}" Git::cloneOrPullIfNoChanges \
    "${targetDir}" "${githubUrl}" changeBranch changeBranch; then
    Log::displayError "Failed to clone/pull ${softwareId}"
    return 1
  fi
  if [[ -n "${installScript}" ]]; then
    Log::displayInfo "Executing install script for ${softwareId}"
    (
      cd "${targetDir}" || return 1
      eval "${installScript}"
    ) || {
      Log::displayError "Failed to execute install script for ${softwareId}"
      return 1
    }
  fi
}

installGithubRelease() {
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
  echo "  Type: GitHub Release"
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
