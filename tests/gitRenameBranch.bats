#!/usr/bin/env bash
rootDir="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
binDir="${rootDir}/bin"
vendorDir="${rootDir}/vendor"

load "${vendorDir}/bash-tools-framework/src/Bats/assert_lines_count.sh"
load "${vendorDir}/bats-support/load.bash"
load "${vendorDir}/bats-assert/load.bash"
load "${vendorDir}/bats-mock-Flamefire/load.bash"

# shellcheck source=vendor/bash-tools-framework/src/Env/load.sh
source "${vendorDir}/bash-tools-framework/src/Env/load.sh" || exit 1
# shellcheck source=vendor/bash-tools-framework/src/Log/_all.sh
FRAMEWORK_DIR="${vendorDir}/bash-tools-framework" source "${vendorDir}/bash-tools-framework/src/Log/__all.sh" || exit 1

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
  git() {
    if [[ "$2" = "--show-current" ]]; then
      echo "oldBranch"
    else
      echo "git $*"
    fi
  }
  export -f git

  testRename5() {
    echo -n 'y' | "${binDir}/gitRenameBranch" newBranch --push 2>&1
  }
  run testRename5

  assert_success
  assert_line -n 1 "git branch -m oldBranch newBranch"
  assert_line -n 3 "git push --set-upstream origin newBranch"
  assert_lines_count 4
}

function Git::gitRenameBranch::rename_local_push_delete_remote_branch { #@test
  git() {
    if [[ "$2" = "--show-current" ]]; then
      echo "oldBranch"
    else
      echo "git $*"
    fi
  }
  export -f git
  testRename() {
    echo -n 'yy' | "${binDir}/gitRenameBranch" newBranch --push --delete 2>&1
  }
  run testRename

  assert_success
  assert_line -n 1 "git branch -m oldBranch newBranch"
  assert_line -n 3 "git push origin :oldBranch"
  assert_line -n 5 "git push --set-upstream origin newBranch"
  assert_lines_count 6
}

function Git::gitRenameBranch::rename_local_and_delete_remote_branch { #@test
  git() {
    if [[ "$2" = "--show-current" ]]; then
      # should not call this as oldBranch provided
      exit 1
    else
      echo "git $*"
    fi
  }
  export -f git

  testRename4() {
    echo -n 'y' | "${binDir}/gitRenameBranch" newBranch oldName --delete 2>&1
  }

  run testRename4
  assert_success

  assert_line -n 1 "git branch -m oldName newBranch"
  assert_line -n 3 "git push origin :oldName"
  assert_lines_count 4
}

function Git::gitRenameBranch::rename_local_and_delete_remote_branch_without_oldName { #@test
  git() {
    if [[ "$2" = "--show-current" ]]; then
      echo "oldBranch"
    else
      echo "git $*"
    fi
  }
  export -f git
  testRename6() {
    echo -n 'y' | "${binDir}/gitRenameBranch" newBranch --delete 2>&1
  }
  run testRename6

  assert_success
  assert_line -n 1 "git branch -m oldBranch newBranch"
  assert_line -n 3 "git push origin :oldBranch"
  assert_lines_count 4
}

function Git::gitRenameBranch::rename_local_and_push_branch_assume_yes { #@test
  git() {
    if [[ "$2" = "--show-current" ]]; then
      echo "oldBranch"
    else
      echo "git $*"
    fi
  }
  export -f git
  testRename7() {
    "${binDir}/gitRenameBranch" newBranch --push --assume-yes 2>&1
  }
  run testRename7

  assert_success
  assert_line -n 1 "git branch -m oldBranch newBranch"
  assert_line -n 3 "git push --set-upstream origin newBranch"
  assert_lines_count 4
}

function Git::gitRenameBranch::rename_local_push_delete_remote_branch_assume_yes { #@test
  git() {
    if [[ "$2" = "--show-current" ]]; then
      echo "oldBranch"
    else
      echo "git $*"
    fi
  }
  export -f git
  testRename8() {
    echo -n 'yy' | "${binDir}/gitRenameBranch" newBranch --push --delete --assume-yes 2>&1
  }
  run testRename8

  assert_success
  assert_line -n 1 "git branch -m oldBranch newBranch"
  assert_line -n 3 "git push origin :oldBranch"
  assert_line -n 5 "git push --set-upstream origin newBranch"
  assert_lines_count 6
}

function Git::gitRenameBranch::rename_local_and_delete_remote_branch_assume_yes { #@test
  git() {
    if [[ "$2" = "--show-current" ]]; then
      # should not call this as oldBranch provided
      exit 1
    else
      echo "git $*"
    fi
  }
  export -f git
  runRename3() {
    echo -n 'y' | "${binDir}/gitRenameBranch" newBranch oldName --delete --assume-yes 2>&1
  }
  run runRename3

  assert_success
  assert_line -n 1 "git branch -m oldName newBranch"
  assert_line -n 3 "git push origin :oldName"
  assert_lines_count 4
}

function Git::gitRenameBranch::rename_local_and_delete_remote_branch_without_oldName_assume_yes { #@test
  git() {
    if [[ "$2" = "--show-current" ]]; then
      echo "oldBranch"
    else
      echo "git $*"
    fi
  }
  export -f git
  runRename2() {
    echo -n 'y' | "${binDir}/gitRenameBranch" newBranch --delete --assume-yes 2>&1
  }
  run runRename2

  assert_success
  assert_line -n 1 "git branch -m oldBranch newBranch"
  assert_line -n 3 "git push origin :oldBranch"
  assert_lines_count 4
}
