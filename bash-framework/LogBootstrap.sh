#!/usr/bin/env bash

alias Log::logError=":; #"
alias Log::logWarning=":; #"
alias Log::logInfo=":; #"
alias Log::logSuccess=":; #"
alias Log::logDebug=":; #"

declare logLevel=${BASH_FRAMEWORK_LOG_LEVEL:-${__LEVEL_OFF}}
if (( logLevel > __LEVEL_OFF )); then
  if [[ -z "${BASH_FRAMEWORK_LOG_FILE}" ]]; then
      logLevel=${__LEVEL_OFF}
  else
      if ! touch --no-create "${BASH_FRAMEWORK_LOG_FILE}" ; then
          Log::displayError "Log file ${BASH_FRAMEWORK_LOG_FILE} is not writable"
          logLevel=${__LEVEL_OFF}
      fi
  fi
  if (( logLevel >= __LEVEL_ERROR )); then
      alias Log::logError='__logMessage "ERROR  " '
  fi
  if (( logLevel >= __LEVEL_WARNING )); then
      alias Log::logWarning='__logMessage "WARNING" '
  fi
  if (( logLevel >= __LEVEL_INFO )); then
      alias Log::logInfo='__logMessage "INFO   " '
  fi
  if (( logLevel >= __LEVEL_SUCCESS )); then
      alias Log::logSuccess='__logMessage "SUCCESS" '
  fi
  if (( logLevel >= __LEVEL_DEBUG )); then
      alias Log::logDebug='__logMessage "DEBUG  " '
  fi
fi

alias Log::displayError=":; #"
alias Log::displayWarning=":; #"
alias Log::displayInfo=":; #"
alias Log::displaySuccess=":; #"
alias Log::displayDebug=":; #"

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
  if (( displayLevel >= __LEVEL_SUCESS )); then
      alias Log::displaySuccess='__displaySuccess'
  fi
  if (( displayLevel >= __LEVEL_DEBUG )); then
      alias Log::displayDebug='__displayDebug'
  fi
fi
