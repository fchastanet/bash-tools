#!/bin/bash

# @description display curl response only if verbose mode is not off
# @arg $1 type:String type of response displayed
# @arg $2 responseFile:String file containing curl response
# @env BASH_FRAMEWORK_ARGS_VERBOSE
# @exitcode 1 if responseFile not found
Postman::displayResponse() {
  local type="$1"
  local responseFile="$2"
  if ((BASH_FRAMEWORK_ARGS_VERBOSE > __VERBOSE_LEVEL_OFF)); then
    (UI::drawLine >&2 "-")
    (echo >&2 -e "${__DEBUG_COLOR}${type}${__RESET_COLOR}")
    (cat >&2 "${responseFile}")
    (echo >&2)
  fi
}
