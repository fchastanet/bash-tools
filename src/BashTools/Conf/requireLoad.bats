#!/usr/bin/env bash
# shellcheck disable=SC2154
# shellcheck disable=SC2034

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd -P)/batsHeaders.sh"
# shellcheck source=src/BashTools/Conf/requireLoad.sh
source "${rootDir}/src/BashTools/Conf/requireLoad.sh"

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"
  export HOME="${BATS_TEST_TMPDIR}/home"
  export BASH_FRAMEWORK_THEME="noColor"
  export bashToolsDefaultConfigTemplate="$(cat "${rootDir}/conf/.env")"
}

function BashTools::Conf::requireLoad::envFileDoesNotExist { #@test
  local status=0
  BashTools::Conf::requireLoad >"${BATS_TEST_TMPDIR}/result" 2>&1 || status=$?
  [[ "${status}" = "0" ]]
  run cat "${BATS_TEST_TMPDIR}/result"
  assert_output "INFO    - Configuration file '${HOME}/.bash-tools/.env' created"
  [[ -z "${POSTMAN_API_KEY}" ]]
}

function BashTools::Conf::requireLoad::envFileWithApiKeyExists { #@test
  mkdir -p "${HOME}/.bash-tools"
  cp "${rootDir}/conf/.env" "${HOME}/.bash-tools/.env"
  sed -i -E -e 's/^POSTMAN_API_KEY=/POSTMAN_API_KEY=fake2/' "${HOME}/.bash-tools/.env"
  local status=0
  BashTools::Conf::requireLoad >"${BATS_TEST_TMPDIR}/result" 2>&1 || status=$?
  [[ "${status}" = "0" ]]
  run cat "${BATS_TEST_TMPDIR}/result"
  assert_output ""
  [[ "${POSTMAN_API_KEY}" = "fake2" ]]
}

function BashTools::Conf::requireLoad::envFileExistsMissingApiKey { #@test
  mkdir -p "${HOME}/.bash-tools"
  cp "${rootDir}/conf/.env" "${HOME}/.bash-tools/.env"
  sed -i -E -e 's/^POSTMAN_API_KEY=//' "${HOME}/.bash-tools/.env"
  local status=0
  BashTools::Conf::requireLoad >"${BATS_TEST_TMPDIR}/result" 2>&1 || status=$?
  [[ "${status}" = "0" ]]
  run cat "${BATS_TEST_TMPDIR}/result"
  assert_output ""
  [[ "$(grep '# Postman Parameters' "${HOME}/.bash-tools/.env" | wc -l)" = "2" ]]
  [[ "${POSTMAN_API_KEY}" = "" ]]
}

function BashTools::Conf::requireLoad::envFileImpossibleToLoad { #@test
  mkdir -p "${HOME}/.bash-tools"
  cp "${rootDir}/conf/.env" "${HOME}/.bash-tools/.env"
  echo "return 12" >>"${HOME}/.bash-tools/.env"
  run BashTools::Conf::requireLoad 2>&1
  assert_failure 1
  assert_output "ERROR   - impossible to load '${HOME}/.bash-tools/.env'"
}
