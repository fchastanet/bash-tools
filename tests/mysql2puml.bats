#!/usr/bin/env bash

rootDir="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
binDir="${rootDir}/bin"
vendorDir="${rootDir}/vendor"
export FRAMEWORK_DIR="${vendorDir}/bash-tools-framework"

load "${vendorDir}/bats-support/load.bash"
load "${vendorDir}/bats-assert/load.bash"

# shellcheck source=vendor/bash-tools-framework/src/Env/load.sh
source "${vendorDir}/bash-tools-framework/src/Env/load.sh" || exit 1
# shellcheck source=vendor/bash-tools-framework/src/Log/__all.sh
source "${vendorDir}/bash-tools-framework/src/Log/__all.sh" || exit 1

setup() {
  export BASH_FRAMEWORK_ENV_FILEPATH="${rootDir}/conf/.env"
}

function Converters::mysql2puml::display_help { #@test
  run "${binDir}/mysql2puml" --help 2>&1
  assert_success
  assert_line --index 0 "Description: convert mysql dump sql schema to plantuml format"
}

function Converters::mysql2puml::display_version { #@test
  run "${binDir}/mysql2puml" --version 2>&1
  assert_success
  assert_line --index 0 "mysql2puml Version: 0.1"
}

function Converters::mysql2puml::bad_skin_file { #@test
  run "${binDir}/mysql2puml" --skin badSkin 2>&1
  assert_failure
  assert_line --index 0 --partial "ERROR   - conf file 'badSkin' not found"
}

function Converters::mysql2puml::input_file_not_found { #@test
  run "${binDir}/mysql2puml" --skin default notFound.sql 2>&1
  assert_failure
  assert_line --index 0 --partial "FATAL   - file notFound.sql does not exist"
}

function Converters::mysql2puml::parse_file { #@test
  run "${binDir}/mysql2puml" --skin default "${BATS_TEST_DIRNAME}/data/mysql2puml.dump.sql" 2>&1
  assert_success
  assert_output "$(cat "${BATS_TEST_DIRNAME}/data/mysql2puml.puml")"
}

function Converters::mysql2puml::parse_file_from_input { #@test
  run "${binDir}/mysql2puml" --skin default <"${BATS_TEST_DIRNAME}/data/mysql2puml.dump.sql" 2>&1
  assert_success
  assert_output "$(cat "${BATS_TEST_DIRNAME}/data/mysql2puml.puml")"
}
