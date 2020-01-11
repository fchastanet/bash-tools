#!/usr/bin/env bash

#---
## check if an element is contained in an array
## @param $@ first parameter is the needle, rest is the array
## eg: Array::Contains "$libPath" "${__bash_framework__importedFiles[@]}"
## @return 0 if found, 1 otherwise
#---
Array::Contains() {
  local element
  for element in "${@:2}"
  do
    [[ "$element" = "$1" ]] && return 0
  done
  return 1
}
