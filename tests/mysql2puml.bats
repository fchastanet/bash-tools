#!/usr/bin/env bash

toolsDir="$(cd "${BATS_TEST_DIRNAME}/../../bin" && pwd)"
vendorDir="$(cd "${BATS_TEST_DIRNAME}/../../vendor" && pwd)"
load "${vendorDir}/bats-support/load.bash"
load "${vendorDir}/bats-assert/load.bash"

# shellcheck source=bash-framework/Constants.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/Constants.sh" || exit 1

function display_help { #@test
  run "${toolsDir}/mysql2puml" --help 2>&1
  # shellcheck disable=SC2154
  [[ "${status}" -eq 0 ]]
  # shellcheck disable=SC2154
  [[ "${lines[0]}" == "${__HELP_TITLE}Description:${__HELP_NORMAL} convert mysql dump sql schema to plantuml format" ]]
}

function display_version { #@test
  run "${toolsDir}/mysql2puml" --version 2>&1
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "mysql2puml Version: 0.1" ]]
}

function bad_skin_file { #@test
  run "${toolsDir}/mysql2puml" --skin badSkin 2>&1
  [[ "${status}" -eq "1" ]]
  [[ "${lines[0]}" == *"ERROR - conf file 'badSkin' not found"* ]]
}

function input_file_not_found { #@test
  run "${toolsDir}/mysql2puml" --skin default notFound.sql 2>&1
  [[ "${status}" -eq "1" ]]
  [[ "${lines[0]}" == *"FATAL - file notFound.sql does not exist"* ]]
}

function parse_file { #@test
  run "${toolsDir}/mysql2puml" --skin default "${BATS_TEST_DIRNAME}/data/mysql2puml.dump.sql" 2>&1
  [[ "${status}" -eq 0 ]]
  # shellcheck disable=SC2154
  [[ "${output}" = "$(cat "${BATS_TEST_DIRNAME}/data/mysql2puml.puml")" ]]
}

function parse_file_from_input { #@test
  run "${toolsDir}/mysql2puml" --skin default <"${BATS_TEST_DIRNAME}/data/mysql2puml.dump.sql" 2>&1
  [[ "${status}" -eq 0 ]]
  [[ "${output}" = "$(cat "${BATS_TEST_DIRNAME}/data/mysql2puml.puml")" ]]
}
