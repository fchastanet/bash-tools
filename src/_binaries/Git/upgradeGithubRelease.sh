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
      "${targetFileArg}" "${optionVersionArg}" 2>&1 | Version::parse || return 3
    fi
  }

  EXACT_VERSION="${optionExactVersion}" \
    Github::upgradeRelease \
    "${targetFileArg}" \
    "${githubUrlPatternArg}" \
    "${optionVersionArg}" \
    computeCurrentCommandVersion \
    Github::defaultInstall
}

if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "1" ]]; then
  run &>/dev/null
else
  run
fi
