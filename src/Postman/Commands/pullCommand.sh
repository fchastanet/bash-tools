#!/bin/bash

# @description validate arguments before calling Postman::Commands::pullCollections
# @arg $1 modelFile:String model file containing the collections to be pulled
# @arg $@ list of collection references to pull (all if not provided)
# @stderr diagnostic logs
# @exitcode * if one of sub commands fails
Postman::Commands::pullCommand() {
  local modelFile="$1"
  shift || true

  Postman::Model::validate "${modelFile}" "pull" || return 1

  local -a refs
  # shellcheck disable=SC2154
  Postman::Model::getCollectionRefs "${modelFile}" refs || return 1
  if ((${#refs} == 0)); then
    Log::displayError "No collection refs to pull"
    return 1
  fi

  if (($# > 0)); then
    # shellcheck disable=SC2154
    Postman::Model::checkIfValidCollectionRefs "${modelFile}" refs "$@" || return 1
    refs=("$@")
  fi

  local writeMode
  writeMode="$(Postman::Model::getWriteMode "${modelFile}")"
  Log::displayDebug "Collection refs to pull ${refs[*]} - write mode ${writeMode}"
  if [[ "${writeMode}" = "single" ]]; then
    Postman::Commands::pullCollectionsSingle "${modelFile}" "${refs[@]}" || return 1
  else
    Postman::Commands::pullCollectionsMerge "${modelFile}" "${refs[@]}" || return 1
  fi
}
