#!/usr/bin/env bash

Log::logError() { :;}
Log::logWarning() { :;}
Log::logInfo() { :;}
Log::logSuccess() { :;}
Log::logDebug() { :;}

declare logLevel=${BASH_FRAMEWORK_LOG_LEVEL:-${__LEVEL_OFF}}
if (( logLevel > __LEVEL_OFF )); then
  if [[ -z "${BASH_FRAMEWORK_LOG_FILE}" ]]; then
      logLevel=${__LEVEL_OFF}
      BASH_FRAMEWORK_LOG_LEVEL=${__LEVEL_OFF}
  else
      if ! touch --no-create "${BASH_FRAMEWORK_LOG_FILE}" ; then
          Log::displayError "Log file ${BASH_FRAMEWORK_LOG_FILE} is not writable"
         logLevel=${__LEVEL_OFF}
         BASH_FRAMEWORK_LOG_LEVEL=${__LEVEL_OFF}
      fi
  fi
  if (( logLevel >= __LEVEL_ERROR )); then
      Log::logError() { __logMessage "ERROR  " "$@"; }
  fi
  if (( logLevel >= __LEVEL_WARNING )); then
      Log::logWarning() { __logMessage "WARNING" "$@"; }
  fi
  if (( logLevel >= __LEVEL_INFO )); then
      Log::logInfo() { __logMessage "INFO   " "$@"; }
  fi
  if (( logLevel >= __LEVEL_SUCCESS )); then
      Log::logSuccess() { __logMessage "SUCCESS" "$@"; }
  fi
  if (( logLevel >= __LEVEL_DEBUG )); then
      Log::logDebug() { __logMessage "DEBUG  " "$@"; }
  fi
fi

Log::displayError() { :;}
Log::displayWarning() { :;}
Log::displayInfo() { :;}
Log::displaySuccess() { :;}
Log::displayDebug() { :;}

declare displayLevel=${BASH_FRAMEWORK_DISPLAY_LEVEL:-${__LEVEL_OFF}}
if (( displayLevel > __LEVEL_OFF )); then
  if (( displayLevel >= __LEVEL_ERROR )); then
      Log::displayError() { __displayError "$@"; }
  fi
  if (( displayLevel >= __LEVEL_WARNING )); then
      Log::displayWarning() { __displayWarning "$@"; }
  fi
  if (( displayLevel >= __LEVEL_INFO )); then
      Log::displayInfo() { __displayInfo "$@"; }
  fi
  if (( displayLevel >= __LEVEL_SUCCESS )); then
      Log::displaySuccess() { __displaySuccess "$@"; }
  fi
  if (( displayLevel >= __LEVEL_DEBUG )); then
      Log::displayDebug() { __displayDebug "$@"; }
  fi
fi
