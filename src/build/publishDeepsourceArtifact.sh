#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/publishDeepsourceArtifact
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE lib/_header.tpl

FILE="$1"
(
  cd "${ROOT_DIR}" || exit 1
  # Install deepsource CLI
  curl https://deepsource.io/cli | sh

  # Report coverage artifact to 'test-coverage' analyzer
  ./bin/deepsource report --analyzer shell --key shellcheck --value-file "${FILE}"
)
