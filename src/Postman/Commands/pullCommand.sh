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
  Postman::Commands::getValidatedRefs "${modelFile}" "pull" refs "$@" || return 1
  Postman::Commands::pullCollections "${modelFile}" "${refs[@]}" || return 1
}
