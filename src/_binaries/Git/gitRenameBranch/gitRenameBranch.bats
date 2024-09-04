#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)/batsHeaders.sh"

load "${FRAMEWORK_ROOT_DIR}/src/_standalone/Bats/assert_lines_count.sh"

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"

  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}/.bash-tools"
  cp "${rootDir}/conf/.env" "${HOME}/.bash-tools/.env"

  mkdir "${BATS_TEST_TMPDIR}/gitRepo"
  mkdir "${BATS_TEST_TMPDIR}/gitRepoFake"

  cd "${BATS_TEST_TMPDIR}/gitRepo" || exit 1
  git init
  git config --local user.email "you@example.com"
  git config --local user.name "Your Name"

  touch f
  git add f
  git commit -m 'test'
  git checkout -b main master
  git checkout -b oldBranch master

  export BASH_FRAMEWORK_ENV_FILEPATH="${BATS_TEST_DIRNAME}/testsData/.env"
  export INTERACTIVE=1
}

teardown() {
  cd - || exit 1
  unstub_all
}

function Git::gitRenameBranch::display_help { #@test
  testCommand "${binDir}/gitRenameBranch" gitRenameBranch.help.txt
}

function Git::gitRenameBranch::not_a_git_repository { #@test
  cd "${BATS_TEST_TMPDIR}/gitRepoFake" || exit 1
  run "${binDir}/gitRenameBranch" "test" --verbose 2>&1
  assert_failure 1

  # shellcheck disable=SC2154
  assert_output --partial "ERROR   - not a git repository (or any of the parent directories)"
}

function Git::gitRenameBranch::master_branch_not_supported_checkout_master { #@test
  git checkout master
  run "${binDir}/gitRenameBranch" --verbose master -vvv 2>&1
  assert_failure 3
  assert_lines_count 4
  assert_line --index 0 "+ git rev-parse --git-dir"
  assert_line --index 1 "+ git branch --show-current"
  assert_line --index 2 --partial "ERROR   - master/main branch not supported by this command, please do it manually"
  assert_line --index 3 --partial "DEBUG   - KEEP_TEMP_FILES=0 removing temp files"
}

function Git::gitRenameBranch::main_branch_not_supported { #@test
  git checkout main
  run "${binDir}/gitRenameBranch" --verbose main 2>&1
  assert_failure 3
  assert_output --partial "ERROR   - master/main branch not supported by this command, please do it manually"
}

function Git::gitRenameBranch::master_branch_not_supported_as_argument { #@test
  run "${binDir}/gitRenameBranch" master --verbose 2>&1
  assert_failure 3
  assert_output --partial "ERROR   - master/main branch not supported by this command, please do it manually"
}

function Git::gitRenameBranch::main_branch_not_supported_as_argument { #@test
  run "${binDir}/gitRenameBranch" main --verbose 2>&1
  assert_failure 3
  assert_output --partial "ERROR   - master/main branch not supported by this command, please do it manually"
}

function Git::gitRenameBranch::new_branch_name_not_provided { #@test
  run "${binDir}/gitRenameBranch" --verbose 2>&1
  assert_failure 1
  assert_output --partial "ERROR   - Command gitRenameBranch - Argument 'newBranchName' should be provided at least 1 time(s)"
}

function Git::gitRenameBranch::branch_master_provided_as_oldBranch { #@test
  run "${binDir}/gitRenameBranch" newBranch master --verbose 2>&1
  assert_failure 3
  assert_output --partial "ERROR   - master/main branch not supported by this command, please do it manually"
}

function Git::gitRenameBranch::too_much_parameters { #@test
  run "${binDir}/gitRenameBranch" newBranch oldBranch tooMuch 2>&1
  assert_failure
  assert_output --partial "ERROR   - Command gitRenameBranch - Argument - too much arguments provided: tooMuch"
}

function Git::gitRenameBranch::rename_local_and_push_branch { #@test
  stub git \
    'rev-parse --git-dir : exit 0' \
    'branch --show-current : echo "oldName"' \
    'branch -m oldName newBranch : exit 0' \
    'push --set-upstream origin newBranch : exit 0'

  run "${binDir}/gitRenameBranch" newBranch --push --verbose 2>&1 <<<'y'

  assert_success
  assert_lines_count 6
  assert_line -n 0 "+ git rev-parse --git-dir"
  assert_line -n 1 "+ git branch --show-current"
  assert_line -n 2 --partial "INFO    - Renaming branch locally from oldName to newBranch"
  assert_line -n 3 "+ git branch -m oldName newBranch"
  assert_line -n 4 --partial "INFO    - Pushing new branch name newBranch"
  assert_line -n 5 "+ git push --set-upstream origin newBranch"
}

function Git::gitRenameBranch::rename_local_push_delete_remote_branch { #@test
  stub git \
    'rev-parse --git-dir : exit 0' \
    'branch --show-current : echo "oldName"' \
    'branch -m oldName newBranch : exit 0' \
    'push origin :oldName : exit 0' \
    'push --set-upstream origin newBranch : exit 0'

  run "${binDir}/gitRenameBranch" newBranch --push --delete --verbose 2>&1 <<<'yy'
  assert_success
  assert_lines_count 8
  assert_line -n 0 "+ git rev-parse --git-dir"
  assert_line -n 1 "+ git branch --show-current"
  assert_line -n 2 --partial "INFO    - Renaming branch locally from oldName to newBranch"
  assert_line -n 3 "+ git branch -m oldName newBranch"
  assert_line -n 4 --partial "INFO    - Removing eventual old remote branch oldName"
  assert_line -n 5 "+ git push origin :oldName"
  assert_line -n 6 --partial "INFO    - Pushing new branch name newBranch"
  assert_line -n 7 "+ git push --set-upstream origin newBranch"
}

function Git::gitRenameBranch::rename_local_and_delete_remote_branch { #@test
  stub git \
    'rev-parse --git-dir : exit 0' \
    'branch -m oldName newBranch : exit 0' \
    'push origin :oldName : exit 0'

  run "${binDir}/gitRenameBranch" newBranch oldName --delete --verbose 2>&1 <<<'y'
  assert_success
  assert_lines_count 5
  assert_line -n 0 "+ git rev-parse --git-dir"
  assert_line -n 1 --partial "INFO    - Renaming branch locally from oldName to newBranch"
  assert_line -n 2 "+ git branch -m oldName newBranch"
  assert_line -n 3 --partial "INFO    - Removing eventual old remote branch oldName"
  assert_line -n 4 "+ git push origin :oldName"
}

function Git::gitRenameBranch::rename_local_and_delete_remote_branch_without_oldName { #@test
  stub git \
    'rev-parse --git-dir : exit 0' \
    'branch --show-current : echo "oldName"' \
    'branch -m oldName newBranch : exit 0' \
    'push origin :oldName : exit 0'

  run "${binDir}/gitRenameBranch" newBranch --delete --verbose 2>&1 <<<'y'

  assert_success
  assert_lines_count 6
  assert_line -n 0 "+ git rev-parse --git-dir"
  assert_line -n 1 "+ git branch --show-current"
  assert_line -n 2 --partial "INFO    - Renaming branch locally from oldName to newBranch"
  assert_line -n 3 "+ git branch -m oldName newBranch"
  assert_line -n 4 --partial "INFO    - Removing eventual old remote branch oldName"
  assert_line -n 5 "+ git push origin :oldName"
}

function Git::gitRenameBranch::rename_local_and_push_branch_assume_yes { #@test
  stub git \
    'rev-parse --git-dir : exit 0' \
    'branch --show-current : echo "oldName"' \
    'branch -m oldName newBranch : exit 0' \
    'push --set-upstream origin newBranch : exit 0'

  run "${binDir}/gitRenameBranch" newBranch --push --assume-yes --verbose 2>&1

  assert_success
  assert_lines_count 6
  assert_line -n 0 "+ git rev-parse --git-dir"
  assert_line -n 1 "+ git branch --show-current"
  assert_line -n 2 --partial "INFO    - Renaming branch locally from oldName to newBranch"
  assert_line -n 3 "+ git branch -m oldName newBranch"
  assert_line -n 4 --partial "INFO    - Pushing new branch name newBranch"
  assert_line -n 5 "+ git push --set-upstream origin newBranch"
}

function Git::gitRenameBranch::rename_local_push_delete_remote_branch_assume_yes { #@test
  stub git \
    'rev-parse --git-dir : exit 0' \
    'branch --show-current : echo "oldName"' \
    'branch -m oldName newBranch : exit 0' \
    'push origin :oldName : exit 0' \
    'push --set-upstream origin newBranch : exit 0'

  run "${binDir}/gitRenameBranch" newBranch --push --delete --assume-yes --verbose 2>&1 <<<'yy'

  assert_success
  assert_lines_count 8
  assert_line -n 0 "+ git rev-parse --git-dir"
  assert_line -n 1 "+ git branch --show-current"
  assert_line -n 2 --partial "INFO    - Renaming branch locally from oldName to newBranch"
  assert_line -n 3 "+ git branch -m oldName newBranch"
  assert_line -n 4 --partial "INFO    - Removing eventual old remote branch oldName"
  assert_line -n 5 "+ git push origin :oldName"
  assert_line -n 6 --partial "INFO    - Pushing new branch name newBranch"
  assert_line -n 7 "+ git push --set-upstream origin newBranch"
}

function Git::gitRenameBranch::rename_local_and_delete_remote_branch_assume_yes { #@test
  stub git \
    'rev-parse --git-dir : echo "git rev-parse --git-dir"' \
    'branch -m oldName newBranch : echo "git branch -m oldName newBranch"' \
    'push origin :oldName : echo "git push origin :oldName"'

  run "${binDir}/gitRenameBranch" newBranch oldName --delete --assume-yes --verbose 2>&1 <<<'y'
  assert_success
  assert_lines_count 5
  assert_line -n 0 "+ git rev-parse --git-dir"
  assert_line -n 1 --partial "INFO    - Renaming branch locally from oldName to newBranch"
  assert_line -n 2 "+ git branch -m oldName newBranch"
  assert_line -n 3 --partial "INFO    - Removing eventual old remote branch oldName"
  assert_line -n 4 "+ git push origin :oldName"
}

function Git::gitRenameBranch::rename_local_and_delete_remote_branch_without_oldName_assume_yes { #@test
  stub git \
    'rev-parse --git-dir : exit 0' \
    'branch --show-current : echo "oldName"' \
    'branch -m oldName newBranch : echo "git branch -m oldName newBranch"' \
    'push origin :oldName : echo "git push origin :oldName"'

  run "${binDir}/gitRenameBranch" newBranch --delete --assume-yes --verbose 2>&1 <<<'y'

  assert_success
  assert_lines_count 6
  assert_line -n 0 "+ git rev-parse --git-dir"
  assert_line -n 1 "+ git branch --show-current"
  assert_line -n 2 --partial "INFO    - Renaming branch locally from oldName to newBranch"
  assert_line -n 3 "+ git branch -m oldName newBranch"
  assert_line -n 4 --partial "INFO    - Removing eventual old remote branch oldName"
  assert_line -n 5 "+ git push origin :oldName"

}
