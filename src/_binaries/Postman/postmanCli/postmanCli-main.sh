#!/usr/bin/env bash

# shellcheck disable=SC2154
case "${argCommand}" in
  pull)
    Postman::Commands::pullCommand "${optionPostmanModelConfig}" "${commandArgs[@]}"
    ;;
  push)
    Postman::Commands::pushCommand "${optionPostmanModelConfig}" "${commandArgs[@]}"
    ;;
  *)
    Log::displayError "Invalid command ${argCommand}"
    exit 1
    ;;
esac
