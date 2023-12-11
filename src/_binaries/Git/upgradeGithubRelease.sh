#!/usr/bin/env bash
# BIN_FILE=${BASH_TOOLS_ROOT_DIR}/bin/upgradeGithubRelease
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE
# shellcheck disable=SC2034

# default
declare defaultVersionArg="--version"

# option values
declare targetFileArg=""
declare githubUrlPatternArg=""
declare optionVersionArg="${defaultVersionArg}"
declare optionCurrentVersion=""
declare optionMinimalVersion=""
declare optionExactVersion=""

# other values
declare copyrightBeginYear="2020"

.INCLUDE "$(dynamicTemplateDir _binaries/Git/upgradeGithubRelease.options.tpl)"

run() {
  computeCurrentCommandVersion() {
    if [[ -n "${optionCurrentVersion}" ]]; then
      echo "${optionCurrentVersion}"
      return 0
    fi
    if [[ -n "${optionVersionArg}" ]]; then
      # need eval here to correctly interpret --version-arg '-V | grep oq:'
      eval "'${targetFileArg}' ${optionVersionArg} 2>&1" | Version::parse || return 3
    fi
  }

  # if minVersion arg provided, we have to compute current bin version
  local tryDownloadNewVersion=1
  if [[ -f "${targetFileArg}" ]]; then
    local commandVersion
    commandVersion="$(computeCurrentCommandVersion)"

    if [[ -n "${optionExactVersion}" ]]; then
      if Version::compare "${commandVersion}" "${optionExactVersion}"; then
        tryDownloadNewVersion=0
        Log::displayStatus "${targetFileArg} version is the exact required version ${optionExactVersion}"
      else
        Log::displayWarning "${targetFileArg} version ${commandVersion} is different than required version ${optionExactVersion}"
      fi
    else
      if [[ -n "${optionMinimalVersion}" ]]; then
        if ! Github::isReleaseVersionExist "$(echo "${githubUrlPatternArg}" | sed -E "s/@version@/${optionMinimalVersion}/g")"; then
          Log::displayError "Minimal version ${optionMinimalVersion} doesn't exist on github"
          return 5
        fi
        local versionCompare=0
        Version::compare "${commandVersion}" "${optionMinimalVersion}" || versionCompare=$?
        # do not try to down version if current version is greater or equal to min version
        if [[ "${versionCompare}" = "1" ]]; then
          local msg="${targetFileArg} version ${commandVersion} is greater than minimal version ${optionMinimalVersion}"
          # current version > min version
          optionExactVersion="$(Github::getLatestVersionFromUrl "${githubUrlPatternArg}")" || return 1
          versionCompare=0
          Version::compare "${commandVersion}" "${optionExactVersion}" || versionCompare=$?
          if [[ "${versionCompare}" = "2" ]]; then
            # current version < remote version
            Log::displayWarning "${msg} but new version ${optionExactVersion} is available on github"
          else
            Log::displayInfo "${msg}"
          fi
          return 0
        elif [[ "${versionCompare}" = "2" ]]; then
          # current version < min version
          Log::displayWarning "${targetFileArg} version ${commandVersion} is lesser than minimal version ${optionMinimalVersion}"
        else
          tryDownloadNewVersion=2 # need to check if a newer version exists
          Log::displayStatus "${targetFileArg} version is the required minimal version ${optionMinimalVersion}"
        fi
      else
        tryDownloadNewVersion="2"
      fi

      # check if a newer version is available
      if [[ "${tryDownloadNewVersion}" = "2" ]]; then
        Log::displayInfo "compute last remote version"
        optionExactVersion="$(Github::getLatestVersionFromUrl "${githubUrlPatternArg}")" || return 1
        versionCompare=0
        Version::compare "${commandVersion}" "${optionExactVersion}" || versionCompare=$?
        if [[ "${versionCompare}" = "1" ]]; then
          # current version > remote version, shouldn't happen
          tryDownloadNewVersion=0
          Log::displayWarning "${targetFileArg} version ${commandVersion} is greater than remote version ${optionExactVersion}"
        elif [[ "${versionCompare}" = "2" ]]; then
          # current version < remote version
          tryDownloadNewVersion=1
          Log::displayWarning "${targetFileArg} version ${optionCurrentVersion} is lesser than remote version ${optionExactVersion}"
        else
          tryDownloadNewVersion=0
          Log::displayStatus "${targetFileArg} version is the same as remote version ${optionExactVersion}"
        fi
      fi
    fi
  fi

  if [[ "${tryDownloadNewVersion}" = "0" ]]; then
    return 0
  fi

  # check if target file is writable
  Assert::fileWritable "${targetFileArg}"

  if [[ -z "${optionExactVersion}" ]]; then
    Log::displayInfo "compute last remote version"
    optionExactVersion="$(Github::getLatestVersionFromUrl "${githubUrlPatternArg}")" || return 1
    if [[ -z "${optionExactVersion}" ]]; then
      Log::displayError "${targetFileArg} latest version not found on github"
      return 5
    fi
  elif ! Github::isReleaseVersionExist "$(echo "${githubUrlPatternArg}" | sed -E "s/@version@/${optionExactVersion}/g")"; then
    Log::displayError "${targetFileArg} version ${optionExactVersion} doesn't exist on github"
    return 4
  fi

  local githubUrl
  githubUrl="$(echo "${githubUrlPatternArg}" | sed -E "s/@version@/${optionExactVersion}/g")"
  Log::displayInfo "Using url ${githubUrl}"

  newSoftware=$(Github::downloadReleaseVersion "${githubUrl}")
  Github::defaultInstall "${newSoftware}" "${targetFileArg}"
  Log::displayStatus "Version ${optionExactVersion} installed in ${targetFileArg}"
}

if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "1" ]]; then
  run &>/dev/null
else
  run
fi
