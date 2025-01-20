#!/usr/bin/env bash

specificRequirements() {
  Linux::requireJqCommand
}

longDescriptionFunction() {
  :
}

optionHelpCallback() {
  githubReleaseManagerCommandHelp
  exit 0
}

softwareIdsArgCallback() {
  # validate if strings provided are valid software ids
  :
}

validateSoftwareIds() {
  local configFile="$1"
  shift
  local softwareIds=("$@")
  local errors=0

  # Get all valid software IDs from config
  local validIds
  validIds="$(yq '.softwares[].id' "${configFile}")"

  for softwareId in "${softwareIds[@]}"; do
    if ! echo "${validIds}" | grep -q "^${softwareId}$"; then
      Log::displayError "Software ID '${softwareId}' not found in configuration file '${configFile}'"
      ((errors++))
    fi
  done

  return "${errors}"
}

validateYamlConfig() {
  local configFile="$1"
  local errors=0
  Log::displayInfo "Validating configuration file ${configFile}"

  # Check if softwares key exists and is an array
  if ! yq '.softwares | type' "${configFile}" | grep -q "array"; then
    Log::displayError "Configuration file must have a 'softwares' array"
    ((errors++))
  fi

  # Validate each software entry
  while IFS= read -r index; do
    local prefix=".softwares[${index}]"

    # Required fields
    for field in "id" "url" "version" "targetFile" "versionArg"; do
      if [[ -z "$(yq "${prefix}.${field}" "${configFile}")" ]]; then
        Log::displayError "Missing required field '${field}' in software entry ${index}"
        ((errors++))
      fi
    done
  done < <(yq '.softwares | keys | .[]' "${configFile}")

  Log::displayInfo "Configuration file ${configFile} validation complete"
  return "${errors}"
}

configFileOptionCallback() {
  if [[ -z "${optionConfigFile}" || "${optionConfigFile}" = "<currentDir>/githubReleaseManager.yaml" ]]; then
    optionConfigFile="$(pwd)/githubReleaseManager.yaml"
  fi
  # shellcheck disable=SC2154
  if [[ ! -f "${optionConfigFile}" ]]; then
    Log::fatal "Configuration file ${optionConfigFile} does not exist"
  fi
  if [[ "${SKIP_YAML_CHECKS:-0}" = "1" ]]; then
    return
  fi
  if ! validateYamlConfig "${optionConfigFile}"; then
    Log::fatal "Configuration file ${optionConfigFile} is invalid"
  fi
  # shellcheck disable=SC2154
  if ! validateSoftwareIds "${optionConfigFile}" "${softwareIdsArg[@]}"; then
    Log::fatal "Invalid software ID(s) provided"
  fi
}
