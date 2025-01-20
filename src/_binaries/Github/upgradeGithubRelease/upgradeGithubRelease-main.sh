#!/usr/bin/env bash
# shellcheck disable=SC2154

computeCurrentCommandVersion() {
  if [[ -n "${optionCurrentVersion}" ]]; then
    echo "${optionCurrentVersion}"
    return 0
  fi
  if [[ -n "${optionVersionArg}" ]]; then
    # shellcheck disable=SC2086
    "${targetFileArg}" ${optionVersionArg} 2>&1 | Version::parse || return 3
  fi
}

VERSION_PLACEHOLDER="@version@" EXACT_VERSION="${optionExactVersion}" \
  Github::upgradeRelease \
  "${targetFileArg}" \
  "${githubUrlPatternArg}" \
  "${optionVersionArg}" \
  computeCurrentCommandVersion \
  Github::defaultInstall
