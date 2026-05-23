#!/bin/bash

# @description validate and get collection refs for pull/push commands
# @arg $1 modelFile:String model file containing the collections
# @arg $2 action:String action name ("pull" or "push")
# @arg $3 refsVarName:String name of the array variable to populate with refs
# @arg $@ list of collection references (all if not provided)
# @stderr diagnostic logs
# @exitcode 1 if validation fails or no refs found
Postman::Commands::getValidatedRefs() {
  local modelFile="$1"
  local action="$2"
  local refsVarName="$3"
  local -n _getValidatedRefs="${refsVarName}"
  shift 3 || true

  Postman::Model::getCollectionRefs "${modelFile}" "${refsVarName}" || return 1
  if (($# > 0)); then
    Postman::Model::checkIfValidCollectionRefs "${modelFile}" "${refsVarName}" "$@" || return 1
    _getValidatedRefs=("$@")
  fi

  if ((${#_getValidatedRefs[@]} == 0)); then
    Log::displayError "No collection refs to ${action}"
    return 1
  fi
  Log::displayDebug "Collection refs to ${action} ${_getValidatedRefs[*]}"
}
