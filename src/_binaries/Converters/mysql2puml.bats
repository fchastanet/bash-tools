#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"

  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p \
    "${HOME}/.bash-tools/mysql2pumlSkins"
  cp "${BATS_TEST_DIRNAME}/testsData/mysql2pumlSkins/"* "${HOME}/.bash-tools/mysql2pumlSkins/"
  cp "${BATS_TEST_DIRNAME}/testsData/.env" "${HOME}/.bash-tools/.env"

  export BASH_FRAMEWORK_ENV_FILEPATH="${HOME}/.bash-tools/.env"
}

function Converters::mysql2puml::display_help { #@test
  # shellcheck disable=SC2154
  run "${binDir}/mysql2puml" --help 2>&1
  assert_success
  assert_line --index 0 "DESCRIPTION: convert mysql dump sql schema to plantuml format"
}

function Converters::mysql2puml::display_version { #@test
  run "${binDir}/mysql2puml" --version 2>&1
  assert_success
  assert_line --index 0 "mysql2puml version 1.0"
}

function Converters::mysql2puml::bad_skin_file { #@test
  run "${binDir}/mysql2puml" --skin badSkin 2>&1
  assert_failure
  assert_line --index 0 --partial "ERROR   - mysql2puml - invalid skin 'badSkin' provided"
}

function Converters::mysql2puml::input_file_not_found { #@test
  run "${binDir}/mysql2puml" --skin default notFound.sql 2>&1
  assert_failure
  assert_line --index 0 --partial "ERROR   - mysql2puml - File 'notFound.sql' does not exists"
}

function Converters::mysql2puml::parse_file { #@test
  run "${binDir}/mysql2puml" --skin default "${BATS_TEST_DIRNAME}/testsData/mysql2puml.dump.sql" 2>&1
  assert_success
  assert_output "$(cat "${BATS_TEST_DIRNAME}/testsData/mysql2puml.puml")"
}

function Converters::mysql2puml::parse_file_from_input { #@test
  run "${binDir}/mysql2puml" --skin default <"${BATS_TEST_DIRNAME}/testsData/mysql2puml.dump.sql" 2>&1
  assert_success
  assert_output "$(cat "${BATS_TEST_DIRNAME}/testsData/mysql2puml.puml")"
}
