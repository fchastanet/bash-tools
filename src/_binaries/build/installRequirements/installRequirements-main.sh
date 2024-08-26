#!/usr/bin/env bash

# shellcheck disable=SC2034,SC2154

Linux::requireExecutedAsUser
Git::requireGitCommand

mkdir -p "${BASH_TOOLS_ROOT_DIR}/vendor" || true
Git::cloneOrPullIfNoChanges \
  "${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework" \
  "https://github.com/fchastanet/bash-tools-framework.git"
