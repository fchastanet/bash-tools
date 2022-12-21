#!/usr/bin/env bash

rootDir="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
binDir="${rootDir}/bin"
vendorDir="${rootDir}/vendor"

load "${vendorDir}/bats-support/load.bash"
load "${vendorDir}/bats-assert/load.bash"

# shellcheck source=vendor/bash-tools-framework/src/Env/load.sh
source "${vendorDir}/bash-tools-framework/src/Env/load.sh" || exit 1
# shellcheck source=vendor/bash-tools-framework/src/Log/_all.sh
FRAMEWORK_DIR="${vendorDir}/bash-tools-framework" source "${vendorDir}/bash-tools-framework/src/Log/__all.sh" || exit 1

setup() {
  export BASH_FRAMEWORK_ENV_FILEPATH="${rootDir}/tests/data/.env"
}

function display_help { #@test
  run "${binDir}/mysql2puml" --help 2>&1
  assert_success
  assert_line --index 0 "Description: convert mysql dump sql schema to plantuml format"
}

function display_version { #@test
  run "${binDir}/mysql2puml" --version 2>&1
  assert_success
  assert_line --index 0 "mysql2puml Version: 0.1"
}

function bad_skin_file { #@test
  run "${binDir}/mysql2puml" --skin badSkin 2>&1
  assert_failure
  assert_line --index 0 --partial "ERROR   - conf file 'badSkin' not found"
}

function input_file_not_found { #@test
  run "${binDir}/mysql2puml" --skin default notFound.sql 2>&1
  assert_failure
  assert_line --index 0 --partial "FATAL   - file notFound.sql does not exist"
}

function parse_file { #@test
  run "${binDir}/mysql2puml" --skin default "${BATS_TEST_DIRNAME}/data/mysql2puml.dump.sql" 2>&1
  assert_success
  assert_output "$(cat "${BATS_TEST_DIRNAME}/data/mysql2puml.puml")"
}

function parse_file_from_input { #@test
  run "${binDir}/mysql2puml" --skin default <"${BATS_TEST_DIRNAME}/data/mysql2puml.dump.sql" 2>&1
  assert_success
  assert_output "$(cat "${BATS_TEST_DIRNAME}/data/mysql2puml.puml")"
}
