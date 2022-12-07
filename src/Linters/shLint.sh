#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/shLint
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

if (($# == 0)); then
  set -- --check-sourced -x -f checkstyle
fi

(
  # shellcheck disable=SC2046
  LC_ALL=C.UTF-8 shellcheck "$@" \
    $(find . -type f \
      -not -path './LICENSE' \
      -not -path './vendor/*' \
      -not -path './.git/*' \
      -not -path './bin/hadolint' \
      -not -path './.github/*' \
      -not -path './.docker/*' \
      -not -path './.history/*' \
      -not -path './tests/tools/data/*' \
      -not -path './tests/bash-framework/data/*' \
      -not -path './tests/bash-framework/dataGetList/*' \
      -regextype posix-egrep \
      ! -regex '.*\.(env|log|sql|puml|awk|bats|md|xml|png|iml|query|json)$' ! -name '.*')
)
