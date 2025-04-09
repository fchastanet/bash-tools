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

function Git::upgradeGithubRelease::display_help { #@test
  testCommand "${binDir}/upgradeGithubRelease" upgradeGithubRelease.help.txt
}

function Git::upgradeGithubRelease::noArg { #@test
  run "${binDir}/upgradeGithubRelease" 2>&1
  assert_failure 1
  assert_lines_count 1
  assert_output --partial "ERROR   - Command upgradeGithubRelease - Argument 'targetFile' should be provided at least 1 time(s)"
}

function Git::upgradeGithubRelease::1ArgNotWritable { #@test
  run "${binDir}/upgradeGithubRelease" /notWritable/arg1 2>&1
  assert_failure 1
  assert_output --partial "FATAL   - File /notWritable/arg1 is not writable"
}

function Git::upgradeGithubRelease::1ArgWritable { #@test
  run "${binDir}/upgradeGithubRelease" /tmp/arg1 2>&1
  assert_failure 1
  assert_output --partial "ERROR   - Command upgradeGithubRelease - Argument 'githubUrlPattern' should be provided at least 1 time(s)"
}

function Git::upgradeGithubRelease::githubArgInvalid { #@test
  run "${binDir}/upgradeGithubRelease" /tmp/arg1 arg2 2>&1
  assert_failure
  assert_lines_count 1
  assert_line --index 0 --partial "FATAL   - Invalid githubUrlPattern arg2 provided, it should begin with https://github.com/"
}

function Git::upgradeGithubRelease::filePathInvalid { #@test
  run "${binDir}/upgradeGithubRelease" François https://github.com/ 2>&1
  assert_failure
  assert_lines_count 1
  assert_line --index 0 --partial "FATAL   - File $(pwd)/François is not a valid path"
}

function Git::upgradeGithubRelease::filePathNotWritable { #@test
  mkdir "${BATS_TEST_TMPDIR}/dir" || true
  chmod 444 "${BATS_TEST_TMPDIR}/dir" || true
  run "${binDir}/upgradeGithubRelease" "${BATS_TEST_TMPDIR}/dir/targetFile" https://github.com/ 2>&1
  assert_failure
  assert_lines_count 1
  assert_line --index 0 --partial "FATAL   - File ${BATS_TEST_TMPDIR}/dir/targetFile is not writable"
}

function Git::upgradeGithubRelease::filePathNotExistsExactVersionShortArg { #@test
  # shellcheck disable=SC2016
  stub curl \
    '-L --connect-timeout 5 -o /dev/null --silent --head --fail https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64 : exit 0' \
    '-L --connect-timeout 5 -o * --fail https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64 : echo "success" > "$5"'

  upgradeGithubRelease() {
    RETRY_MAX_RETRY=1 \
      "${binDir}/upgradeGithubRelease" \
      "${BATS_TEST_TMPDIR}/targetFile" \
      "https://github.com/hadolint/hadolint/releases/download/v@version@/hadolint-Linux-x86_64" \
      -e "1.0.0" \
      --verbose
  }
  run upgradeGithubRelease 2>&1
  assert_success
  assert_lines_count 4
  assert_line --index 0 --partial "INFO    - Upgrading ${BATS_TEST_TMPDIR}/targetFile from version not existing to 1.0.0"
  assert_line --index 1 --partial "INFO    - Using url https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64"
  assert_line --index 2 --partial "INFO    - Attempt 1/1:"
  assert_line --index 3 --partial "SUCCESS - Version not existing upgraded to 1.0.0 in ${BATS_TEST_TMPDIR}/targetFile"

  [[ "$(cat "${BATS_TEST_TMPDIR}/targetFile")" = "success" ]]
}

function Git::upgradeGithubRelease::filePathNotExistsExactVersionLongArg { #@test
  # shellcheck disable=SC2016
  stub curl \
    '-L --connect-timeout 5 -o /dev/null --silent --head --fail https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64 : exit 0' \
    '-L --connect-timeout 5 -o * --fail https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64 : echo "success" > "$5"'

  upgradeGithubRelease() {
    RETRY_MAX_RETRY=1 \
      "${binDir}/upgradeGithubRelease" \
      "${BATS_TEST_TMPDIR}/targetFile" \
      "https://github.com/hadolint/hadolint/releases/download/v@version@/hadolint-Linux-x86_64" \
      --exact-version "1.0.0" \
      --verbose
  }
  run upgradeGithubRelease 2>&1
  assert_success
  assert_success
  assert_lines_count 4
  assert_line --index 0 --partial "INFO    - Upgrading ${BATS_TEST_TMPDIR}/targetFile from version not existing to 1.0.0"
  assert_line --index 1 --partial "INFO    - Using url https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64"
  assert_line --index 2 --partial "INFO    - Attempt 1/1:"
  assert_line --index 3 --partial "SUCCESS - Version not existing upgraded to 1.0.0 in ${BATS_TEST_TMPDIR}/targetFile"

  [[ "$(cat "${BATS_TEST_TMPDIR}/targetFile")" = "success" ]]
}

function Git::upgradeGithubRelease::filePathNotExistsLatestVersionNotFound { #@test
  # shellcheck disable=SC2016
  stub curl \
    '-L --connect-timeout 5 --fail --silent https://api.github.com/repos/hadolint/hadolint/releases/latest : exit 1'

  upgradeGithubRelease() {
    RETRY_MAX_RETRY=1 \
      "${binDir}/upgradeGithubRelease" \
      "${BATS_TEST_TMPDIR}/targetFile" \
      "https://github.com/hadolint/hadolint/releases/download/v@version@/hadolint-Linux-x86_64" \
      --verbose
  }
  run upgradeGithubRelease 2>&1
  assert_failure 1
  assert_lines_count 3
  assert_line --index 0 --partial "INFO    - Attempt 1/1: Retrieving release versions list ..."
  assert_line --index 1 --partial "ERROR   - The command has failed after 1 attempts."
  assert_line --index 2 --partial "ERROR   - latest version not found on https://api.github.com/repos/hadolint/hadolint/releases/latest"
}

function Git::upgradeGithubRelease::filePathNotExistsLatestVersionFound { #@test
  # shellcheck disable=SC2016
  stub curl \
    '-L --connect-timeout 5 --fail --silent https://api.github.com/repos/hadolint/hadolint/releases/latest : echo "{\"tag_name\": \"1.0.0\"}"' \
    '-L --connect-timeout 5 -o /dev/null --silent --head --fail https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64 : exit 0' \
    '-L --connect-timeout 5 -o * --fail https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64 : echo "success" > "$5"'

  upgradeGithubRelease() {
    RETRY_MAX_RETRY=1 \
      "${binDir}/upgradeGithubRelease" \
      "${BATS_TEST_TMPDIR}/targetFile" \
      "https://github.com/hadolint/hadolint/releases/download/v@version@/hadolint-Linux-x86_64" \
      --verbose
  }
  run upgradeGithubRelease 2>&1

  assert_success
  assert_lines_count 6
  assert_line --index 0 --partial "INFO    - Attempt 1/1: Retrieving release versions list ..."
  assert_line --index 1 --partial "INFO    - Latest version found is 1.0.0"
  assert_line --index 2 --partial "INFO    - Upgrading ${BATS_TEST_TMPDIR}/targetFile from version not existing to 1.0.0"
  assert_line --index 3 --partial "INFO    - Using url https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64"
  assert_line --index 4 --partial "INFO    - Attempt 1/1:"
  assert_line --index 5 --partial "SUCCESS - Version not existing upgraded to 1.0.0 in ${BATS_TEST_TMPDIR}/targetFile"

  [[ "$(cat "${BATS_TEST_TMPDIR}/targetFile")" = "success" ]]
}

function Git::upgradeGithubRelease::filePathExistsExactVersionUpgradeNeeded { #@test
  cp "${BATS_TEST_DIRNAME}/testsData/upgradeGithubRelease_bin" "${BATS_TEST_TMPDIR}"
  # shellcheck disable=SC2016
  stub curl \
    '-L --connect-timeout 5 -o /dev/null --silent --head --fail https://github.com/hadolint/hadolint/releases/download/v1.1.0/hadolint-Linux-x86_64 : exit 0' \
    '-L --connect-timeout 5 -o * --fail https://github.com/hadolint/hadolint/releases/download/v1.1.0/hadolint-Linux-x86_64 : echo "success" > "$5"'

  upgradeGithubRelease() {
    RETRY_MAX_RETRY=1 \
      "${binDir}/upgradeGithubRelease" \
      "${BATS_TEST_TMPDIR}/targetFile" \
      "https://github.com/hadolint/hadolint/releases/download/v@version@/hadolint-Linux-x86_64" \
      --exact-version "1.1.0" \
      --verbose
  }
  run upgradeGithubRelease 2>&1
  assert_success
  assert_lines_count 4
  assert_line --index 0 --partial "INFO    - Upgrading ${BATS_TEST_TMPDIR}/targetFile from version not existing to 1.1.0"
  assert_line --index 1 --partial "INFO    - Using url https://github.com/hadolint/hadolint/releases/download/v1.1.0/hadolint-Linux-x86_64"
  assert_line --index 2 --partial "INFO    - Attempt 1/1:"
  assert_line --index 3 --partial "SUCCESS - Version not existing upgraded to 1.1.0 in ${BATS_TEST_TMPDIR}/targetFile"

  [[ "$(cat "${BATS_TEST_TMPDIR}/targetFile")" = "success" ]]
}

function Git::upgradeGithubRelease::filePathExistsExactVersionUpgradeNotNeeded { #@test
  cp "${BATS_TEST_DIRNAME}/testsData/upgradeGithubRelease_bin" "${BATS_TEST_TMPDIR}/upgradeGithubRelease"
  stub curl \
    '-L --connect-timeout 5 -o /dev/null --silent --head --fail https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64 : exit 0'

  upgradeGithubRelease() {
    RETRY_MAX_RETRY=1 \
      "${binDir}/upgradeGithubRelease" \
      "${BATS_TEST_TMPDIR}/upgradeGithubRelease" \
      "https://github.com/hadolint/hadolint/releases/download/v@version@/hadolint-Linux-x86_64" \
      --exact-version "1.0.0" \
      --verbose
  }
  run upgradeGithubRelease 2>&1

  assert_success
  assert_lines_count 1
  assert_line --index 0 --partial "INFO    - ${BATS_TEST_TMPDIR}/upgradeGithubRelease version 1.0.0 already installed"
}
