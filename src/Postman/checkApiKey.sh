#!/bin/bash

# @description check if postman api key is set in .env file
# @arg $1 envFile:String .env file that should contain POSTMAN_API_KEY variable
# @stderr display warning message if postman api key is not filled
# @exitcode 0 always successful
Postman::checkApiKey() {
  local envFile="$1"

  if grep -q '^POSTMAN_API_KEY=$' "${envFile}" 2>/dev/null ||
    ! grep -q '^POSTMAN_API_KEY=' "${envFile}" 2>/dev/null; then
    Log::displayWarning "Please update POSTMAN_API_KEY in '${envFile}'"
  fi
}
