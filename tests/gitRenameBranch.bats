#!/usr/bin/env bash

# shellcheck source=tests/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}" && pwd)/batsHeaders.sh"

load "${FRAMEWORK_DIR}/src/_standalones/Bats/assert_lines_count.sh"

# shellcheck source=vendor/bash-tools-framework/src/Env/load.sh
source "${FRAMEWORK_DIR}/src/Env/load.sh" || exit 1

setup() {
  BATS_TMP_DIR="$(mktemp -d -p "${TMPDIR:-/tmp}" -t bats-$$-XXXXXX)"
  export TMPDIR="${BATS_TMP_DIR}"

  export HOME="${BATS_TMP_DIR}/home"

  mkdir "${BATS_TMP_DIR}/gitRepo"
  mkdir "${BATS_TMP_DIR}/gitRepoFake"

  cd "${BATS_TMP_DIR}/gitRepo" || exit 1
  git init
  git config --local user.email "you@example.com"
  git config --local user.name "Your Name"

  touch f
  git add f
  git commit -m 'test'
  git checkout -b main master
  git checkout -b oldBranch master

  export BASH_FRAMEWORK_ENV_FILEPATH="${rootDir}/tests/data/.env"
}

teardown() {
  cd - || exit 1
  rm -Rf "${BATS_TMP_DIR}" || true
  unstub_all
}

function Git::gitRenameBranch::display_help { #@test
  run "${binDir}/gitRenameBranch" --help 2>&1
  assert_success
  assert_line --index 0 "Description: rename git local branch, use options to push new branch and delete old branch"
}

function Git::gitRenameBranch::not_a_git_repository { #@test
  cd "${BATS_TMP_DIR}/gitRepoFake" || exit 1
  run "${binDir}/gitRenameBranch" "test" 2>&1
  assert_failure
  # shellcheck disable=SC2154
  assert_output "FATAL   - not a git repository (or any of the parent directories)"
}

function Git::gitRenameBranch::master_branch_not_supported { #@test
  git checkout master
  run "${binDir}/gitRenameBranch" 2>&1
  assert_failure
  assert_output "FATAL   - master/main branch not supported by this command, please do it manually"
}

function Git::gitRenameBranch::main_branch_not_supported { #@test
  git checkout main
  run "${binDir}/gitRenameBranch" 2>&1
  assert_failure
  assert_output "FATAL   - master/main branch not supported by this command, please do it manually"
}

function Git::gitRenameBranch::master_branch_not_supported_as_argument { #@test
  run "${binDir}/gitRenameBranch" master 2>&1
  assert_failure
  assert_output "FATAL   - master/main branch not supported by this command, please do it manually"
}

function Git::gitRenameBranch::main_branch_not_supported_as_argument { #@test
  run "${binDir}/gitRenameBranch" main 2>&1
  assert_failure
  assert_output "FATAL   - master/main branch not supported by this command, please do it manually"
}

function Git::gitRenameBranch::new_branch_name_not_provided { #@test
  run "${binDir}/gitRenameBranch" 2>&1
  assert_failure
  assert_output "FATAL   - new branch name not provided"
}

function Git::gitRenameBranch::branch_not_provided { #@test
  run "${binDir}/gitRenameBranch" 2>&1
  assert_failure
  assert_output "FATAL   - new branch name not provided"
}

function Git::gitRenameBranch::branch_master_provided { #@test
  run "${binDir}/gitRenameBranch" master 2>&1
  assert_failure
  assert_output "FATAL   - master/main branch not supported by this command, please do it manually"
}

function Git::gitRenameBranch::branch_main_provided { #@test
  run "${binDir}/gitRenameBranch" main 2>&1
  assert_failure
  assert_output "FATAL   - master/main branch not supported by this command, please do it manually"
}

function Git::gitRenameBranch::branch_master_provided_as_oldBranch { #@test
  run "${binDir}/gitRenameBranch" newBranch master 2>&1
  assert_failure
  assert_output "FATAL   - master/main branch not supported by this command, please do it manually"
}

function Git::gitRenameBranch::too_much_parameters { #@test
  run "${binDir}/gitRenameBranch" newBranch oldBranch tooMuch 2>&1
  assert_failure
  assert_output "FATAL   - too much arguments provided"
}

function Git::gitRenameBranch::rename_local_and_push_branch { #@test
  stub git \
    'rev-parse --git-dir : exit 0' \
    'branch --show-current : echo "oldName"' \
    'branch -m oldName newBranch : exit 0' \
    'push --set-upstream origin newBranch : exit 0'

  testRename5() {
    # shellcheck disable=SC2317
    echo -n 'y' | "${binDir}/gitRenameBranch" newBranch --push 2>&1
  }
  run testRename5

  assert_success
  assert_line -n 0 --partial "INFO    - Renaming branch locally from oldName to newBranch"
  assert_line -n 1 --partial "INFO    - Pushing new branch name newBranch"
  assert_lines_count 2
}

function Git::gitRenameBranch::rename_local_push_delete_remote_branch { #@test
  stub git \
    'rev-parse --git-dir : exit 0' \
    'branch --show-current : echo "oldName"' \
    'branch -m oldName newBranch : exit 0' \
    'push origin :oldName : exit 0' \
    'push --set-upstream origin newBranch : exit 0'

  testRename() {
    # shellcheck disable=SC2317
    echo -n 'yy' | "${binDir}/gitRenameBranch" newBranch --push --delete 2>&1
  }
  run testRename
  assert_success
  assert_line -n 0 --partial "INFO    - Renaming branch locally from oldName to newBranch"
  assert_line -n 1 --partial "INFO    - Removing eventual old remote branch oldName"
  assert_line -n 2 --partial "INFO    - Pushing new branch name newBranch"
  assert_lines_count 3
}

function Git::gitRenameBranch::rename_local_and_delete_remote_branch { #@test
  stub git \
    'rev-parse --git-dir : exit 0' \
    'branch -m oldName newBranch : exit 0' \
    'push origin :oldName : exit 0'

  testRename4() {
    # shellcheck disable=SC2317
    echo -n 'y' | "${binDir}/gitRenameBranch" newBranch oldName --delete 2>&1
  }

  run testRename4
  assert_success

  assert_line -n 0 --partial "INFO    - Renaming branch locally from oldName to newBranch"
  assert_line -n 1 --partial "INFO    - Removing eventual old remote branch oldName"
  assert_lines_count 2
}

function Git::gitRenameBranch::rename_local_and_delete_remote_branch_without_oldName { #@test
  stub git \
    'rev-parse --git-dir : exit 0' \
    'branch --show-current : echo "oldName"' \
    'branch -m oldName newBranch : exit 0' \
    'push origin :oldName : exit 0'

  testRename6() {
    # shellcheck disable=SC2317
    echo -n 'y' | "${binDir}/gitRenameBranch" newBranch --delete 2>&1
  }
  run testRename6

  assert_success
  assert_line -n 0 --partial "INFO    - Renaming branch locally from oldName to newBranch"
  assert_line -n 1 --partial "INFO    - Removing eventual old remote branch oldName"
  assert_lines_count 2
}

function Git::gitRenameBranch::rename_local_and_push_branch_assume_yes { #@test
  stub git \
    'rev-parse --git-dir : exit 0' \
    'branch --show-current : echo "oldName"' \
    'branch -m oldName newBranch : exit 0' \
    'push --set-upstream origin newBranch : exit 0'

  testRename7() {
    # shellcheck disable=SC2317
    "${binDir}/gitRenameBranch" newBranch --push --assume-yes 2>&1
  }
  run testRename7

  assert_success
  assert_line -n 0 --partial "INFO    - Renaming branch locally from oldName to newBranch"
  assert_line -n 1 --partial "INFO    - Pushing new branch name newBranch"
  assert_lines_count 2
}

function Git::gitRenameBranch::rename_local_push_delete_remote_branch_assume_yes { #@test
  stub git \
    'rev-parse --git-dir : exit 0' \
    'branch --show-current : echo "oldName"' \
    'branch -m oldName newBranch : exit 0' \
    'push origin :oldName : exit 0' \
    'push --set-upstream origin newBranch : exit 0'

  testRename8() {
    # shellcheck disable=SC2317
    echo -n 'yy' | "${binDir}/gitRenameBranch" newBranch --push --delete --assume-yes 2>&1
  }
  run testRename8

  assert_success
  assert_line -n 0 --partial "INFO    - Renaming branch locally from oldName to newBranch"
  assert_line -n 1 --partial "INFO    - Removing eventual old remote branch oldName"
  assert_line -n 2 --partial "INFO    - Pushing new branch name newBranch"
  assert_lines_count 3
}

function Git::gitRenameBranch::rename_local_and_delete_remote_branch_assume_yes { #@test
  stub git \
    'rev-parse --git-dir : echo "git rev-parse --git-dir"' \
    'branch -m oldName newBranch : echo "git branch -m oldName newBranch"' \
    'push origin :oldName : echo "git push origin :oldName"'

  runRename3() {
    # shellcheck disable=SC2317
    echo -n 'y' | "${binDir}/gitRenameBranch" newBranch oldName --delete --assume-yes 2>&1
  }
  run runRename3

  assert_success
  assert_line -n 1 "git branch -m oldName newBranch"
  assert_line -n 3 "git push origin :oldName"
  assert_lines_count 4
}

function Git::gitRenameBranch::rename_local_and_delete_remote_branch_without_oldName_assume_yes { #@test
  stub git \
    'rev-parse --git-dir : exit 0' \
    'branch --show-current : echo "oldName"' \
    'branch -m oldName newBranch : echo "git branch -m oldName newBranch"' \
    'push origin :oldName : echo "git push origin :oldName"'

  runRename2() {
    # shellcheck disable=SC2317
    echo -n 'y' | "${binDir}/gitRenameBranch" newBranch --delete --assume-yes 2>&1
  }
  run runRename2

  assert_success
  assert_line -n 1 "git branch -m oldName newBranch"
  assert_line -n 3 "git push origin :oldName"
  assert_lines_count 4
}
