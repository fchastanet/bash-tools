#!/bin/bash

# @description validates the model file and checks for file existence
# @arg $1 optionModelFile:String the model file to validate
# @arg $2 mode:Enum(pull|push|config) eg: pull/config don't check for file existence
# @exitcode 1 if file optionModelFile does not exists or invalid
# @stderr diagnostics information is displayed
Postman::Model::validate() {
  local modelFile="$1"
  local mode="$2"

  if ! Array::contains "${mode}" pull push config; then
    Log::displayError "invalid mode ${mode}"
    return 1
  fi

  # shellcheck disable=SC2154
  if [[ ! -f "${modelFile}" ]]; then
    Log::displayError "File ${modelFile} does not exist"
    return 1
  fi

  if ! jq -cre . &>/dev/null <"${modelFile}"; then
    Log::displayError "File '${modelFile}' is not a valid json file"
    return 1
  fi
  local -i errorCount=0

  # check name key presence
  local name
  name="$(jq -cre .name 2>/dev/null <"${modelFile}")" || {
    Log::displayError "File '${modelFile}' - missing name property"
    ((++errorCount))
  }
  if [[ -z "${name}" ]]; then
    Log::displayError "File '${modelFile}' name property cannot be empty"
    ((++errorCount))
  fi

  # check collections key presence
  local expr='.collections | if type=="object" then "yes" else "no" end'
  if [[ "$(jq -cre "${expr}" <"${modelFile}")" = "no" ]]; then
    Log::displayError "File '${modelFile}' - collections property is missing or is not an object"
    ((++errorCount))
  else
    local collectionJson
    local -i index=0
    # shellcheck disable=SC2030
    jq -cre '.collections | to_entries | map(.value + {key: .key}) | .[]' "${modelFile}" | while IFS=$'\n' read -r collectionJson; do
      local collectionFile collectionKey
      local status=0
      collectionFile="$(jq -cre .file 2>/dev/null <<<"${collectionJson}")" || status=1
      if [[ "${status}" = 0 ]]; then
        collectionKey="$(jq -cre .key 2>/dev/null <<<"${collectionJson}")" || status=1
      else
        collectionKey="${index}"
      fi
      if [[ "${status}" = 1 ]]; then
        Log::displayError "File '${modelFile}' - collection ${collectionKey} - missing file property"
        ((++errorCount))
      else
        local configDirectory
        configDirectory="$(Postman::Model::getRelativeConfigDirectory "${modelFile}")"
        collectionFile="${configDirectory}/${collectionFile}"
        case "${mode}" in
          push)
            if [[ ! -f "${collectionFile}" ]]; then
              Log::displayError "File '${modelFile}' - collection ${collectionKey} - collection file ${collectionFile} does not exists"
              ((++errorCount))
              continue
            fi
            if [[ ! -r "${collectionFile}" ]]; then
              Log::displayError "File '${modelFile}' - collection ${collectionKey} - collection file ${collectionFile} is not readable"
              ((++errorCount))
              continue
            fi
            if ! jq -cre . &>/dev/null <"${collectionFile}"; then
              Log::displayError "File '${modelFile}' - collection ${collectionKey} - collection file ${collectionFile} is not a valid json file"
              ((++errorCount))
              continue
            fi
            if ! jq -cre .info.name &>/dev/null <"${collectionFile}"; then
              Log::displayError "File '${modelFile}' - collection ${collectionKey} - collection file ${collectionFile} does not seem to be a valid collection file"
              ((++errorCount))
              continue
            fi
            ;;

          pull)
            if [[ -f "${collectionFile}" && ! -w "${collectionFile}" ]]; then
              Log::displayError "File '${modelFile}' - collection ${collectionKey} - collection file ${collectionFile} is not writable"
              ((++errorCount))
              continue
            fi
            if [[ ! -f "${collectionFile}" && ! -w "${configDirectory}" ]]; then
              Log::displayError "File '${modelFile}' - collection ${collectionKey} - config directory ${configDirectory} is not writable"
              ((++errorCount))
              continue
            fi
            ;;
          *) ;;
            # ignore
        esac
      fi
      # TODO environment
      ((++index))
    done
  fi

  # shellcheck disable=SC2031
  ((errorCount == 0))
}
