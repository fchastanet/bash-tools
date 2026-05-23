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
  Postman::Commands::getValidatedRefs "${modelFile}" "push" refs "$@" || return 1
  Postman::Commands::pushCollections "${modelFile}" "${refs[@]}" || return 1
}
