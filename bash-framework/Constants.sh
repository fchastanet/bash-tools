#!/usr/bin/env bash
# Module: Framework constants definition
#
# for color constants,
# check colors applicable https://misc.flogisoft.com/bash/tip_colors_and_formatting

if [[ "${CONSTANTS_MODULE_VERSION:+xxx}" != "xxx" ]]; then
  readonly CONSTANTS_MODULE_VERSION="1.0"
  # Public: log level off
  readonly __LEVEL_OFF=0
  # Public: log level error
  readonly __LEVEL_ERROR=1
  # Public: log level warning
  readonly __LEVEL_WARNING=2
  # Public: log level info
  readonly __LEVEL_INFO=3
  # Public: log level success
  readonly __LEVEL_SUCCESS=3
  # Public: log level debug
  readonly __LEVEL_DEBUG=4

  # Internal: color used f error level (red bold)
  readonly __FATAL_COLOR='\e[31m\e[1m'
  # Internal: color used for error level (red)
  readonly __ERROR_COLOR='\e[31m'
  # Internal: color used for info level (white on lightBlue)
  readonly __INFO_COLOR='\e[44m'
  # Internal: color used for success level (green)
  readonly __SUCCESS_COLOR='\e[32m'
  # Internal: color used for warning level (yellow)
  readonly __WARNING_COLOR='\e[33m'
  # Internal: color used for debug level (grey)
  readonly __DEBUG_COLOR='\e[37m'
  # Internal: reset color
  readonly __RESET_COLOR='\e[0m'
fi
