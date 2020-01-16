#!/usr/bin/env bash

if (( logLevel > __LEVEL_OFF )); then
  if [[ -z "${BASH_FRAMEWORK_LOG_FILE}" ]]; then
      Log::displayError "BASH_FRAMEWORK_LOG_FILE - log file not specified"
  else
      if ! touch --no-create "${BASH_FRAMEWORK_LOG_FILE}" ; then
          Log::displayError "Log file ${BASH_FRAMEWORK_LOG_FILE} is not writable"
          BASH_FRAMEWORK_LOG_LEVEL=${__LEVEL_OFF}
          logLevel=${__LEVEL_OFF}
      fi
  fi
  if (( logLevel >= __LEVEL_ERROR )); then
      alias Log::logError='__logMessage'
  fi
  if (( logLevel >= __LEVEL_WARNING )); then
      alias Log::logWarning='__logMessage'
  fi
  if (( logLevel >= __LEVEL_INFO )); then
      alias Log::logInfo='__logMessage'
  fi
  if (( logLevel >= __LEVEL_INFO )); then
      alias Log::logSuccess='__logMessage'
  fi
  if (( logLevel >= __LEVEL_DEBUG )); then
      alias Log::logDebug='__logMessage'
  fi
else
  alias Log::displayError=':; #'
fi

declare displayLevel=${BASH_FRAMEWORK_DISPLAY_LEVEL:-${__LEVEL_OFF}}
if (( displayLevel > __LEVEL_OFF )); then
  if (( displayLevel >= __LEVEL_ERROR )); then
      alias Log::displayError='__displayError'
  fi
  if (( displayLevel >= __LEVEL_WARNING )); then
      alias Log::displayWarning='__displayWarning'
  fi
  if (( displayLevel >= __LEVEL_INFO )); then
      alias Log::displayInfo='__displayInfo'
  fi
  if (( displayLevel >= __LEVEL_INFO )); then
      alias Log::displaySuccess='__displaySuccess'
  fi
  if (( displayLevel >= __LEVEL_DEBUG )); then
      alias Log::displayDebug='__displayDebug'
  fi
fi

declare logLevel=${BASH_FRAMEWORK_LOG_LEVEL:-${__LEVEL_OFF}}


