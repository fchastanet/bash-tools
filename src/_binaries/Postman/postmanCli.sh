#!/bin/bash
# BIN_FILE=${BASH_TOOLS_ROOT_DIR}/bin/postmanCli
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE

.INCLUDE "$(dynamicTemplateDir _binaries/Postman/command.postmanCli.tpl)"
# call main
postmanCliCommand parse "$@"

run() {
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
}

if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "1" ]]; then
  run "$@" &>/dev/null
else
  run "$@"
fi
