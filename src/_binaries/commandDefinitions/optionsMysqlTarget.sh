#!/usr/bin/env bash

# shellcheck disable=SC2034
declare defaultTargetCollationName="utf8_general_ci"
declare defaultTargetCharacterSet="utf8"

initializeDefaultTargetMysqlOptions() {
  local -n dbFromInstanceTargetMysql=$1
  local fromDbName="$2"

  # get remote db collation name
  if [[ -n ${optionCollationName+x} && -z "${optionCollationName}" ]]; then
    optionCollationName=$(Database::query dbFromInstanceTargetMysql \
      "SELECT default_collation_name FROM information_schema.SCHEMATA WHERE schema_name = \"${fromDbName}\";" "information_schema")
  fi

  # get remote db character set
  if [[ -z "${optionCharacterSet}" ]]; then
    optionCharacterSet=$(Database::query dbFromInstanceTargetMysql \
      "SELECT default_character_set_name FROM information_schema.SCHEMATA WHERE schema_name = \"${fromDbName}\";" "information_schema")
  fi
}
