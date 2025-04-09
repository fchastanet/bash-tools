#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)/batsHeaders.sh"

load "${FRAMEWORK_ROOT_DIR}/src/_standalone/Bats/assert_lines_count.sh"

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"
  export HOME="${BATS_TEST_TMPDIR}/home"
  export BASH_FRAMEWORK_ENV_FILEPATH="${BATS_TEST_DIRNAME}/testsData/.env"
  mkdir -p "${HOME}/.bash-tools"
  cp "${rootDir}/conf/defaultEnv/.env" "${HOME}/.bash-tools/.env"
}

teardown() {
  unstub_all
}

function Github::githubReleaseManager::display_help { #@test
  stub yq
  testCommand "${binDir}/githubReleaseManager" githubReleaseManager.help.txt
}

function Github::githubReleaseManager::noArg { #@test
  stub yq
  (
    cd "${BATS_TEST_TMPDIR}" || exit

    run "${binDir}/githubReleaseManager" 2>&1
    assert_failure 1
    assert_lines_count 1
    assert_output --partial "FATAL   - Configuration file ${BATS_TEST_TMPDIR}/githubReleaseManager.yaml does not exist"
  )
}

function Github::githubReleaseManager::filePathInvalid { #@test
  stub yq
  run "${binDir}/githubReleaseManager" -c François 2>&1
  assert_failure 1
  assert_lines_count 1
  assert_line --index 0 --partial "FATAL   - Configuration file François does not exist"
}

function Github::githubReleaseManager::missingSoftwaresKey { #@test
  local f="${BATS_TEST_DIRNAME}/testsData/githubReleaseManager-MissingSoftwaresKey.yaml"
  stub yq \
    "'.softwares | type' '${f}' : echo 'invalidType'" \
    "'.softwares | keys | .[]' '${f}' : exit 0"
  run "${binDir}/githubReleaseManager" -c "${f}" invalidSoftwareId 2>&1
  assert_failure 1
  assert_lines_count 4
  assert_line --index 0 --partial "INFO    - Validating configuration file ${f}"
  assert_line --index 1 --partial "ERROR   - Configuration file must have a 'softwares' array"
  assert_line --index 2 --partial "INFO    - Configuration file ${f} validation complete"
  assert_line --index 3 --partial "FATAL   - Configuration file ${f} is invalid"
}

function Github::githubReleaseManager::invalidSoftwareId { #@test
  local f="${BATS_TEST_DIRNAME}/testsData/githubReleaseManager.yaml"
  stub yq \
    "'.softwares | type' '${f}' : echo '!!seq'" \
    "'.softwares | keys | .[]' "${f}" : exit 0" \
    "'.softwares[].id' "${f}" : exit 1"
  run "${binDir}/githubReleaseManager" \
    -c "${f}" invalidSoftwareId 2>&1
  assert_failure 1
  assert_lines_count 4
  assert_line --index 0 --partial "INFO    - Validating configuration file ${f}"
  assert_line --index 1 --partial "INFO    - Configuration file ${f} validation complete"
  assert_line --index 2 --partial "ERROR   - Software ID 'invalidSoftwareId' not found in configuration file"
  assert_line --index 3 --partial "FATAL   - Invalid software ID(s) provided"
}

function Github::githubReleaseManager::invalidSoftwareConfigurationMissingId { #@test
  local f="${BATS_TEST_DIRNAME}/testsData/githubReleaseManager.yaml"
  stub yq \
    "'.softwares | type' '${f}' : echo '!!seq'" \
    "'.softwares | keys | .[]' '${f}' : echo 'invalidSoftwareConfig'" \
    "eval * '${f}' : echo 'version'"
  run "${binDir}/githubReleaseManager" \
    -c "${BATS_TEST_DIRNAME}/testsData/githubReleaseManager.yaml" invalidSoftwareConfig 2>&1
  assert_failure 1
  assert_lines_count 4
  assert_line --index 0 --partial "INFO    - Validating configuration file ${BATS_TEST_DIRNAME}/testsData/githubReleaseManager.yaml"
  assert_line --index 1 --partial "ERROR   - Missing required fields in software invalidSoftwareConfig entries: version"
  assert_line --index 2 --partial "INFO    - Configuration file ${BATS_TEST_DIRNAME}/testsData/githubReleaseManager.yaml validation complete"
  assert_line --index 3 --partial "FATAL   - Configuration file ${BATS_TEST_DIRNAME}/testsData/githubReleaseManager.yaml is invalid"
}

function Github::githubReleaseManager::validSoftwareConfigNonExistingGithub { #@test
  local f="${BATS_TEST_DIRNAME}/testsData/githubReleaseManager.yaml"
  local validSoftwareConfigFile="${BATS_TEST_DIRNAME}/testsData/validSoftware.sh"
  stub yq \
    "'.softwares | type' '${f}' : echo '!!seq'" \
    "'.softwares | keys | .[]' '${f}' : echo '0'" \
    "eval * '${f}' : echo '[unknown]'" \
    "'.softwares[].id' '${f}' : echo 'validSoftwareConfig'" \
    "-o p -r * '${f}' : cat '${validSoftwareConfigFile}'"
  stub gh \
    'auth status : exit 0'
  stub dpkg '--print-architecture : echo "amd64"'
  Github::isReleaseVersionExist() { return 1; }

  ERROR_CODE=0 RETRY_DELAY_BETWEEN_RETRIES=0 testCommand "${binDir}/githubReleaseManager" "githubReleaseManager.validSoftwareConfigNonExistingGithub.txt" \
    -c "${BATS_TEST_DIRNAME}/testsData/githubReleaseManager.yaml" validSoftwareConfig 2>&1
}
