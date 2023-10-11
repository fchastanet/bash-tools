#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/batsHeaders.sh"

load "${FRAMEWORK_ROOT_DIR}/src/_standalone/Bats/assert_lines_count.sh"

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"
  export HOME="${BATS_TEST_TMPDIR}/home"
  export BASH_FRAMEWORK_ENV_FILEPATH="${BATS_TEST_DIRNAME}/testsData/.env"
}

teardown() {
  unstub_all
}

function Git::upgradeGithubRelease::display_help { #@test
  run "${binDir}/upgradeGithubRelease" --help 2>&1
  assert_success
  assert_line --index 0 --partial "retrieve latest binary release from github and install it"
}

function Git::upgradeGithubRelease::noArg { #@test
  run "${binDir}/upgradeGithubRelease" 2>&1
  assert_failure 1
  assert_lines_count 1
  assert_output --partial "ERROR   - Command upgradeGithubRelease - Argument 'targetFile' should be provided at least 1 time(s)"
}

function Git::upgradeGithubRelease::1Arg { #@test
  run "${binDir}/upgradeGithubRelease" arg1 2>&1
  assert_failure 1
  assert_output --partial "ERROR   - Command upgradeGithubRelease - Argument 'githubUrlPattern' should be provided at least 1 time(s)"
}

function Git::upgradeGithubRelease::githubArgInvalid { #@test
  run "${binDir}/upgradeGithubRelease" arg1 arg2 2>&1
  assert_failure
  assert_lines_count 1
  assert_line --index 0 --partial "FATAL   - Invalid githubUrlPattern arg2 provided, it should begin with https://github.com/"
}

function Git::upgradeGithubRelease::filePathInvalid { #@test
  run "${binDir}/upgradeGithubRelease" François https://github.com/ 2>&1
  assert_failure
  assert_lines_count 1
  assert_line --index 0 --partial "FATAL   - File "$(pwd)/François" is not a valid path"
}

function Git::upgradeGithubRelease::filePathNotWritable { #@test
  mkdir "${BATS_TEST_TMPDIR}/dir" || true
  chmod 444 "${BATS_TEST_TMPDIR}/dir" || true
  run "${binDir}/upgradeGithubRelease" "${BATS_TEST_TMPDIR}/dir/targetFile" https://github.com/ 2>&1
  assert_failure
  assert_lines_count 1
  assert_line --index 0 --partial "FATAL   - File "${BATS_TEST_TMPDIR}/dir/targetFile" is not writable"
}

function Git::upgradeGithubRelease::filePathNotExistsExactVersionShortArg { #@test
  stub curl \
    '-L -o /dev/null --silent --head --fail https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64 : exit 0' \
    '-L -o * --fail https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64 : echo "success" > "$3"'

  run "${binDir}/upgradeGithubRelease" \
    "${BATS_TEST_TMPDIR}/targetFile" \
    "https://github.com/hadolint/hadolint/releases/download/v@version@/hadolint-Linux-x86_64" \
    -e "1.0.0" \
    --verbose \
    2>&1
  assert_success
  assert_lines_count 3
  assert_line --index 0 --partial "INFO    - Using url https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64"
  assert_line --index 1 --partial "INFO    - Attempt 1/5:"
  assert_line --index 2 --partial "STATUS  - Version 1.0.0 installed in ${BATS_TEST_TMPDIR}/targetFile"
  [[ "$(cat "${BATS_TEST_TMPDIR}/targetFile")" = "success" ]]
}

function Git::upgradeGithubRelease::filePathNotExistsExactVersionLongArg { #@test
  stub curl \
    '-L -o /dev/null --silent --head --fail https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64 : exit 0' \
    '-L -o * --fail https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64 : echo "success" > "$3"'

  run "${binDir}/upgradeGithubRelease" \
    "${BATS_TEST_TMPDIR}/targetFile" \
    "https://github.com/hadolint/hadolint/releases/download/v@version@/hadolint-Linux-x86_64" \
    --exact-version "1.0.0" \
    --verbose \
    2>&1
  assert_success
  assert_lines_count 3
  assert_line --index 0 --partial "INFO    - Using url https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64"
  assert_line --index 1 --partial "INFO    - Attempt 1/5:"
  assert_line --index 2 --partial "STATUS  - Version 1.0.0 installed in ${BATS_TEST_TMPDIR}/targetFile"
  [[ "$(cat "${BATS_TEST_TMPDIR}/targetFile")" = "success" ]]
}

function Git::upgradeGithubRelease::filePathNotExistsLatestVersionNotFound { #@test
  stub curl \
    '-L -o * --fail --silent https://api.github.com/repos/hadolint/hadolint/releases/latest : echo "{}" > "$3"'

  run "${binDir}/upgradeGithubRelease" \
    "${BATS_TEST_TMPDIR}/targetFile" \
    "https://github.com/hadolint/hadolint/releases/download/v@version@/hadolint-Linux-x86_64" \
    --verbose \
    2>&1
  assert_failure 5
  assert_lines_count 4
  assert_line --index 0 --partial "INFO    - compute last remote version"
  assert_line --index 1 --partial "INFO    - Attempt 1/5:"
  assert_line --index 2 --partial "INFO    - Repo hadolint/hadolint latest version found is "
  assert_line --index 3 --partial "ERROR   - ${BATS_TEST_TMPDIR}/targetFile latest version not found on github"
}

function Git::upgradeGithubRelease::filePathNotExistsLatestVersionFound { #@test
  stub curl \
    '-L -o * --fail --silent https://api.github.com/repos/hadolint/hadolint/releases/latest : echo "{\"tag_name\": \"1.0.0\"}" > "$3"' \
    '-L -o * --fail https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64 : echo "success" > "$3"'

  run "${binDir}/upgradeGithubRelease" \
    "${BATS_TEST_TMPDIR}/targetFile" \
    "https://github.com/hadolint/hadolint/releases/download/v@version@/hadolint-Linux-x86_64" \
    --verbose \
    2>&1
  assert_success
  assert_lines_count 6
  assert_line --index 0 --partial "INFO    - compute last remote version"
  assert_line --index 1 --partial "INFO    - Attempt 1/5:"
  assert_line --index 2 --partial "INFO    - Repo hadolint/hadolint latest version found is 1.0.0"
  assert_line --index 3 --partial "INFO    - Using url https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64"
  assert_line --index 4 --partial "INFO    - Attempt 1/5:"
  assert_line --index 5 --partial "STATUS  - Version 1.0.0 installed in ${BATS_TEST_TMPDIR}/targetFile"
  [[ "$(cat "${BATS_TEST_TMPDIR}/targetFile")" = "success" ]]
}

function Git::upgradeGithubRelease::filePathExistsMinVersion { #@test
  cp "${BATS_TEST_DIRNAME}/testsData/upgradeGithubRelease_bin" "${BATS_TEST_TMPDIR}"
  stub curl \
    '-L -o /dev/null --silent --head --fail https://github.com/hadolint/hadolint/releases/download/v1.1.0/hadolint-Linux-x86_64 : exit 0' \
    '-L -o * --fail --silent https://api.github.com/repos/hadolint/hadolint/releases/latest : echo "{\"tag_name\": \"1.1.0\"}" > "$3"' \
    '-L -o * --fail https://github.com/hadolint/hadolint/releases/download/v1.1.0/hadolint-Linux-x86_64 : echo "success" > "$3"'

  run "${binDir}/upgradeGithubRelease" \
    "${BATS_TEST_TMPDIR}/upgradeGithubRelease_bin" \
    "https://github.com/hadolint/hadolint/releases/download/v@version@/hadolint-Linux-x86_64" \
    --minimal-version "1.1.0" \
    --verbose \
    2>&1

  assert_success
  assert_lines_count 7
  assert_line --index 0 --partial "WARN    - ${BATS_TEST_TMPDIR}/upgradeGithubRelease_bin version 1.0.0 is lesser than minimal version 1.1.0"
  assert_line --index 1 --partial "INFO    - compute last remote version"
  assert_line --index 2 --partial "INFO    - Attempt 1/5:"
  assert_line --index 3 --partial "INFO    - Repo hadolint/hadolint latest version found is 1.1.0"
  assert_line --index 4 --partial "INFO    - Using url https://github.com/hadolint/hadolint/releases/download/v1.1.0/hadolint-Linux-x86_64"
  assert_line --index 5 --partial "INFO    - Attempt 1/5:"
  assert_line --index 6 --partial "STATUS  - Version 1.1.0 installed in ${BATS_TEST_TMPDIR}/upgradeGithubRelease_bin"
  [[ "$(cat "${BATS_TEST_TMPDIR}/upgradeGithubRelease_bin")" = "success" ]]
}

function Git::upgradeGithubRelease::filePathExistsCurrentVersionLessThanMinVersion { #@test
  cp "${BATS_TEST_DIRNAME}/testsData/upgradeGithubRelease_bin" "${BATS_TEST_TMPDIR}"
  stub curl \
    '-L -o /dev/null --silent --head --fail https://github.com/hadolint/hadolint/releases/download/v1.1.0/hadolint-Linux-x86_64 : exit 0' \
    '-L -o * --fail --silent https://api.github.com/repos/hadolint/hadolint/releases/latest : echo "{\"tag_name\": \"1.1.0\"}" > "$3"' \
    '-L -o * --fail https://github.com/hadolint/hadolint/releases/download/v1.1.0/hadolint-Linux-x86_64 : echo "success" > "$3"'

  run "${binDir}/upgradeGithubRelease" \
    "${BATS_TEST_TMPDIR}/upgradeGithubRelease_bin" \
    "https://github.com/hadolint/hadolint/releases/download/v@version@/hadolint-Linux-x86_64" \
    --minimal-version "1.1.0" \
    --current-version "1.0.0" \
    --verbose \
    2>&1

  assert_success
  assert_lines_count 7
  assert_line --index 0 --partial "WARN    - ${BATS_TEST_TMPDIR}/upgradeGithubRelease_bin version 1.0.0 is lesser than minimal version 1.1.0"
  assert_line --index 1 --partial "INFO    - compute last remote version"
  assert_line --index 2 --partial "INFO    - Attempt 1/5:"
  assert_line --index 3 --partial "INFO    - Repo hadolint/hadolint latest version found is 1.1.0"
  assert_line --index 4 --partial "INFO    - Using url https://github.com/hadolint/hadolint/releases/download/v1.1.0/hadolint-Linux-x86_64"
  assert_line --index 5 --partial "INFO    - Attempt 1/5:"
  assert_line --index 6 --partial "STATUS  - Version 1.1.0 installed in ${BATS_TEST_TMPDIR}/upgradeGithubRelease_bin"
  [[ "$(cat "${BATS_TEST_TMPDIR}/upgradeGithubRelease_bin")" = "success" ]]
}

function Git::upgradeGithubRelease::filePathExistsCurrentVersionEqualsMinVersion { #@test
  cp "${BATS_TEST_DIRNAME}/testsData/upgradeGithubRelease_bin" "${BATS_TEST_TMPDIR}"
  stub curl \
    '-L -o /dev/null --silent --head --fail https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64 : exit 0' \
    '-L -o * --fail --silent https://api.github.com/repos/hadolint/hadolint/releases/latest : echo "{\"tag_name\": \"1.0.0\"}" > "$3"'

  run "${binDir}/upgradeGithubRelease" \
    "${BATS_TEST_TMPDIR}/upgradeGithubRelease_bin" \
    "https://github.com/hadolint/hadolint/releases/download/v@version@/hadolint-Linux-x86_64" \
    --minimal-version "1.0.0" \
    --current-version "1.0.0" \
    --verbose \
    2>&1

  assert_success
  assert_lines_count 5
  assert_line --index 0 --partial "STATUS  - ${BATS_TEST_TMPDIR}/upgradeGithubRelease_bin version is the required minimal version 1.0.0"
  assert_line --index 1 --partial "INFO    - compute last remote version"
  assert_line --index 2 --partial "INFO    - Attempt 1/5:"
  assert_line --index 3 --partial "INFO    - Repo hadolint/hadolint latest version found is 1.0.0"
  assert_line --index 4 --partial "STATUS  - ${BATS_TEST_TMPDIR}/upgradeGithubRelease_bin version is the same as remote version 1.0.0"
}

function Git::upgradeGithubRelease::filePathExistsCurrentVersionGreaterThanMinVersion { #@test
  cp "${BATS_TEST_DIRNAME}/testsData/upgradeGithubRelease_bin" "${BATS_TEST_TMPDIR}"
  stub curl \
    '-L -o /dev/null --silent --head --fail https://github.com/hadolint/hadolint/releases/download/v1.0.0/hadolint-Linux-x86_64 : exit 0' \
    '-L -o * --fail --silent https://api.github.com/repos/hadolint/hadolint/releases/latest : echo "{\"tag_name\": \"1.0.0\"}" > "$3"'

  run "${binDir}/upgradeGithubRelease" \
    "${BATS_TEST_TMPDIR}/upgradeGithubRelease_bin" \
    "https://github.com/hadolint/hadolint/releases/download/v@version@/hadolint-Linux-x86_64" \
    --minimal-version "1.0.0" \
    --current-version "1.1.0" \
    --verbose \
    2>&1

  assert_success
  assert_lines_count 3
  assert_line --index 0 --partial "INFO    - Attempt 1/5:"
  assert_line --index 1 --partial "INFO    - Repo hadolint/hadolint latest version found is 1.0.0"
  assert_line --index 2 --partial "INFO    - ${BATS_TEST_TMPDIR}/upgradeGithubRelease_bin version 1.1.0 is greater than minimal version 1.0.0"
}

function Git::upgradeGithubRelease::filePathExistsExactVersionUpgradeNeeded { #@test
  cp "${BATS_TEST_DIRNAME}/testsData/upgradeGithubRelease_bin" "${BATS_TEST_TMPDIR}"
  stub curl \
    '-L -o /dev/null --silent --head --fail https://github.com/hadolint/hadolint/releases/download/v1.1.0/hadolint-Linux-x86_64 : exit 0' \
    '-L -o * --fail https://github.com/hadolint/hadolint/releases/download/v1.1.0/hadolint-Linux-x86_64 : echo "success" > "$3"'

  run "${binDir}/upgradeGithubRelease" \
    "${BATS_TEST_TMPDIR}/upgradeGithubRelease_bin" \
    "https://github.com/hadolint/hadolint/releases/download/v@version@/hadolint-Linux-x86_64" \
    --exact-version "1.1.0" \
    --verbose \
    2>&1

  assert_success
  assert_lines_count 4
  assert_line --index 0 --partial "WARN    - ${BATS_TEST_TMPDIR}/upgradeGithubRelease_bin version 1.0.0 is different than required version 1.1.0"
  assert_line --index 1 --partial "INFO    - Using url https://github.com/hadolint/hadolint/releases/download/v1.1.0/hadolint-Linux-x86_64"
  assert_line --index 2 --partial "INFO    - Attempt 1/5:"
  assert_line --index 3 --partial "STATUS  - Version 1.1.0 installed in ${BATS_TEST_TMPDIR}/upgradeGithubRelease_bin"

  [[ "$(cat "${BATS_TEST_TMPDIR}/upgradeGithubRelease_bin")" = "success" ]]
}

function Git::upgradeGithubRelease::filePathExistsExactVersionUpgradeNotNeeded { #@test
  cp "${BATS_TEST_DIRNAME}/testsData/upgradeGithubRelease_bin" "${BATS_TEST_TMPDIR}"

  run "${binDir}/upgradeGithubRelease" \
    "${BATS_TEST_TMPDIR}/upgradeGithubRelease_bin" \
    "https://github.com/hadolint/hadolint/releases/download/v@version@/hadolint-Linux-x86_64" \
    --exact-version "1.0.0" \
    --verbose \
    2>&1

  assert_success
  assert_lines_count 1
  assert_line --index 0 --partial "STATUS  - ${BATS_TEST_TMPDIR}/upgradeGithubRelease_bin version is the exact required version 1.0.0"
}
