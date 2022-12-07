#!/usr/bin/env bash

toolsDir="$(cd "${BATS_TEST_DIRNAME}/../../bin" && pwd)"
vendorDir="$(cd "${BATS_TEST_DIRNAME}/../../vendor" && pwd)"
load "${vendorDir}/bats-support/load.bash"
load "${vendorDir}/bats-assert/load.bash"

# shellcheck source=bash-framework/Constants.sh
source "$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/bash-framework/Constants.sh" || exit 1

setup() {
  rm -Rf /tmp/gitRepo || true
  mkdir /tmp/gitRepo
  mkdir /tmp/gitRepoFake
  cd /tmp/gitRepo || exit 1
  git init
  git config --local user.email "you@example.com"
  git config --local user.name "Your Name"

  touch f
  git add f
  git commit -m 'test'
  git checkout -b main master
  git checkout -b oldBranch master
}

teardown() {
  rm -Rf /tmp/gitRepo* || true
}

function display_help { #@test
  run "${toolsDir}/gitRenameBranch" --help 2>&1
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "${__HELP_TITLE}Description:${__HELP_NORMAL} rename git local branch, use options to push new branch and delete old branch" ]]
}

function not_a_git_repository { #@test
  cd /tmp/gitRepoFake || exit 1
  run "${toolsDir}/gitRenameBranch" "test" 2>&1
  [[ "${status}" -eq "1" ]]
  # shellcheck disable=SC2154
  [[ ${output} == *"FATAL - not a git repository (or any of the parent directories)"* ]]
}

function master_branch_not_supported { #@test
  git checkout master
  run "${toolsDir}/gitRenameBranch" 2>&1
  [[ "${status}" -eq "1" ]]
  [[ ${output} == *"FATAL - master/main branch not supported by this command, please do it manually"* ]]
}

function main_branch_not_supported { #@test
  git checkout main
  run "${toolsDir}/gitRenameBranch" 2>&1
  [[ "${status}" -eq "1" ]]
  [[ ${output} == *"FATAL - master/main branch not supported by this command, please do it manually"* ]]
}

function master_branch_not_supported_as_argument { #@test
  run "${toolsDir}/gitRenameBranch" master 2>&1
  [[ "${status}" -eq "1" ]]
  [[ ${output} == *"FATAL - master/main branch not supported by this command, please do it manually"* ]]
}

function main_branch_not_supported_as_argument { #@test
  run "${toolsDir}/gitRenameBranch" main 2>&1
  [[ "${status}" -eq "1" ]]
  [[ ${output} == *"FATAL - master/main branch not supported by this command, please do it manually"* ]]
}

function new_branch_name_not_provided { #@test
  run "${toolsDir}/gitRenameBranch" 2>&1
  [[ "${status}" -eq "1" ]]
  [[ ${output} == *"FATAL - new branch name not provided"* ]]
}

function branch_not_provided { #@test
  run "${toolsDir}/gitRenameBranch" 2>&1
  [[ "${status}" -eq "1" ]]
  [[ ${output} == *"FATAL - new branch name not provided"* ]]
}

function branch_master_provided { #@test
  run "${toolsDir}/gitRenameBranch" master 2>&1
  [[ "${status}" -eq "1" ]]
  [[ ${output} == *"FATAL - master/main branch not supported by this command, please do it manually"* ]]
}

function branch_main_provided { #@test
  run "${toolsDir}/gitRenameBranch" main 2>&1
  [[ "${status}" -eq "1" ]]
  [[ ${output} == *"FATAL - master/main branch not supported by this command, please do it manually"* ]]
}

function branch_master_provided_as_oldBranch { #@test
  run "${toolsDir}/gitRenameBranch" newBranch master 2>&1
  [[ "${status}" -eq "1" ]]
  [[ ${output} == *"FATAL - master/main branch not supported by this command, please do it manually"* ]]
}

function too_much_parameters { #@test
  run "${toolsDir}/gitRenameBranch" newBranch oldBranch toomuch 2>&1
  [[ "${status}" -eq "1" ]]
  [[ ${output} == *"FATAL - too much arguments provided"* ]]
}

function rename_local_and_push_branch { #@test
  git() {
    if [ "$2" = "--show-current" ]; then
      echo "oldBranch"
    else
      echo "git $*"
    fi
  }
  export -f git
  IFS=$'\n'
  mapfile -t lines < <(echo -n 'y' | "${toolsDir}/gitRenameBranch" newBranch --push 2>&1)
  status="$?"

  [[ "${status}" -eq 0 ]]
  assert_line -n 1 "git branch -m oldBranch newBranch"
  assert_line -n 3 "git push --set-upstream origin newBranch"
  [ ${#lines[@]} -eq 4 ]
}

function rename_local_push_delete_remote_branch { #@test
  git() {
    if [ "$2" = "--show-current" ]; then
      echo "oldBranch"
    else
      echo "git $*"
    fi
  }
  export -f git
  IFS=$'\n'
  mapfile -t lines < <(echo -n 'yy' | "${toolsDir}/gitRenameBranch" newBranch --push --delete 2>&1)
  status="$?"

  [[ "${status}" -eq 0 ]]
  assert_line -n 1 "git branch -m oldBranch newBranch"
  assert_line -n 3 "git push origin :oldBranch"
  assert_line -n 5 "git push --set-upstream origin newBranch"
  [[ ${#lines[@]} -eq 6 ]]
}

function rename_local_and_delete_remote_branch { #@test
  git() {
    if [ "$2" = "--show-current" ]; then
      # should not call this as oldBranch provided
      exit 1
    else
      echo "git $*"
    fi
  }
  export -f git
  IFS=$'\n'
  mapfile -t lines < <(echo -n 'y' | "${toolsDir}/gitRenameBranch" newBranch oldName --delete 2>&1)
  status="$?"

  [[ "${status}" -eq 0 ]]

  assert_line -n 1 "git branch -m oldName newBranch"
  assert_line -n 3 "git push origin :oldName"
  [[ ${#lines[@]} -eq 4 ]]
}

function rename_local_and_delete_remote_branch_without_oldName { #@test
  git() {
    if [ "$2" = "--show-current" ]; then
      echo "oldBranch"
    else
      echo "git $*"
    fi
  }
  export -f git
  IFS=$'\n'
  mapfile -t lines < <(echo -n 'y' | "${toolsDir}/gitRenameBranch" newBranch --delete 2>&1)
  status="$?"

  [[ "${status}" -eq 0 ]]
  assert_line -n 1 "git branch -m oldBranch newBranch"
  assert_line -n 3 "git push origin :oldBranch"
  [[ ${#lines[@]} -eq 4 ]]
}

function rename_local_and_push_branch_assume_yes { #@test
  git() {
    if [ "$2" = "--show-current" ]; then
      echo "oldBranch"
    else
      echo "git $*"
    fi
  }
  export -f git
  IFS=$'\n'
  mapfile -t lines < <("${toolsDir}/gitRenameBranch" newBranch --push --assume-yes 2>&1)
  status="$?"

  [[ "${status}" -eq 0 ]]
  assert_line -n 1 "git branch -m oldBranch newBranch"
  assert_line -n 3 "git push --set-upstream origin newBranch"
  [[ ${#lines[@]} -eq 4 ]]
}

function rename_local_push_delete_remote_branch_assume_yes { #@test
  git() {
    if [ "$2" = "--show-current" ]; then
      echo "oldBranch"
    else
      echo "git $*"
    fi
  }
  export -f git
  IFS=$'\n'
  mapfile -t lines < <(echo -n 'yy' | "${toolsDir}/gitRenameBranch" newBranch --push --delete --assume-yes 2>&1)
  status="$?"

  [[ "${status}" -eq 0 ]]
  assert_line -n 1 "git branch -m oldBranch newBranch"
  assert_line -n 3 "git push origin :oldBranch"
  assert_line -n 5 "git push --set-upstream origin newBranch"
  [[ ${#lines[@]} -eq 6 ]]
}

function rename_local_and_delete_remote_branch_assume_yes { #@test
  git() {
    if [ "$2" = "--show-current" ]; then
      # should not call this as oldBranch provided
      exit 1
    else
      echo "git $*"
    fi
  }
  export -f git
  IFS=$'\n'
  mapfile -t lines < <(echo -n 'y' | "${toolsDir}/gitRenameBranch" newBranch oldName --delete --assume-yes 2>&1)
  status="$?"

  [[ "${status}" -eq 0 ]]

  assert_line -n 1 "git branch -m oldName newBranch"
  assert_line -n 3 "git push origin :oldName"
  [[ ${#lines[@]} -eq 4 ]]
}

function rename_local_and_delete_remote_branch_without_oldName_assume_yes { #@test
  git() {
    if [ "$2" = "--show-current" ]; then
      echo "oldBranch"
    else
      echo "git $*"
    fi
  }
  export -f git
  IFS=$'\n'
  mapfile -t lines < <(echo -n 'y' | "${toolsDir}/gitRenameBranch" newBranch --delete --assume-yes 2>&1)
  status="$?"

  [[ "${status}" -eq 0 ]]
  assert_line -n 1 "git branch -m oldBranch newBranch"
  assert_line -n 3 "git push origin :oldBranch"
  [[ ${#lines[@]} -eq 4 ]]
}
