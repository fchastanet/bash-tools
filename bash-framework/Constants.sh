#!/usr/bin/env bash

if [[ "${BASH_FRAMEWORK_LOG_INITIALIZED:-0}" = "0" ]]; then
  # log level constants
  readonly __LEVEL_OFF=0
  readonly __LEVEL_ERROR=1
  readonly __LEVEL_WARNING=2
  readonly __LEVEL_INFO=3
  readonly __LEVEL_SUCCESS=3
  readonly __LEVEL_DEBUG=4

  # check colors applicable https://misc.flogisoft.com/bash/tip_colors_and_formatting
  readonly __ERROR_COLOR='\e[31m'           # Red
  readonly __INFO_COLOR='\e[44m'            # white on lightBlue
  readonly __SUCCESS_COLOR='\e[32m'         # Green
  readonly __WARNING_COLOR='\e[33m'         # Yellow
  readonly __DEBUG_COLOR='\e[37m'           # Grey
  readonly __RESET_COLOR='\e[0m'            # Reset Color
fi
BASH_FRAMEWORK_LOG_INITIALIZED=1
