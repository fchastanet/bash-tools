#!/bin/bash

# @description validate arguments before calling Postman::Commands::pushCollections
# @arg $1 modelFile:String model file containing the collections to be pushed
# @arg $@ list of collection references to push (all if not provided)
# @stderr diagnostic logs
# @exitcode * if one of sub commands fails
Postman::Commands::pushCommand() {
  local modelFile="$1"
  shift || true

  Postman::Model::validate "${modelFile}" "push" || return 1

  local -a refs
  # shellcheck disable=SC2154
  Postman::Model::getCollectionRefs "${modelFile}" refs || return 1
  if (($# > 0)); then
    # shellcheck disable=SC2154
    Postman::Model::checkIfValidCollectionRefs "${modelFile}" refs "$@" || return 1
    refs=("$@")
  fi

  if ((${#refs} == 0)); then
    Log::displayError "No collection refs to push"
    return 1
  else
    local writeMode
    writeMode="$(Postman::Model::getWriteMode "${modelFile}")"
    Log::displayDebug "Collection refs to push ${refs[*]} - write mode ${writeMode}"
    if [[ "${writeMode}" = "single" ]]; then
      Postman::Commands::pushCollectionsSingle "${modelFile}" "${refs[@]}" || return 1
    else
      Postman::Commands::pushCollectionsMerge "${modelFile}" "${refs[@]}" || return 1
    fi
  fi
}
