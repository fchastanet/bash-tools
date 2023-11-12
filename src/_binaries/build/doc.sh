#!/usr/bin/env bash
# BIN_FILE=${FRAMEWORK_ROOT_DIR}/bin/doc
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE
# shellcheck disable=SC2034

DOC_DIR="${BASH_TOOLS_ROOT_DIR}/pages"
declare copyrightBeginYear="2020"
declare -a RUN_CONTAINER_ARGV_FILTERED=()

.INCLUDE "$(dynamicTemplateDir _binaries/build/doc.options.tpl)"

run() {
  if [[ "${IN_BASH_DOCKER:-}" != "You're in docker" ]]; then
    DOCKER_RUN_OPTIONS=$"-e ORIGINAL_DOC_DIR=${DOC_DIR}" \
      "${COMMAND_BIN_DIR}/runBuildContainer" "/bash/bin/doc" \
      "${RUN_CONTAINER_ARGV_FILTERED[@]}"
    return $?
  fi

  #-----------------------------
  # configure docker environment
  #-----------------------------
  mkdir -p "${HOME}/.bash-tools"

  (
    cd "${BASH_TOOLS_ROOT_DIR}" || exit 1
    cp -R conf/. "${HOME}/.bash-tools"
    sed -i \
      -e "s@^S3_BASE_URL=.*@S3_BASE_URL=s3://example.com/exports/@g" \
      "${HOME}/.bash-tools/.env"
    # fake docker command
    touch /tmp/docker
    chmod 755 /tmp/docker
  )
  export PATH=/tmp:${PATH}

  #-----------------------------
  # doc generation
  #-----------------------------

  Log::displayInfo 'generate Commands.md'
  ((TOKEN_NOT_FOUND_COUNT = 0)) || true
  ShellDoc::generateMdFileFromTemplate \
    "${BASH_TOOLS_ROOT_DIR}/Commands.tmpl.md" \
    "${DOC_DIR}/Commands.md" \
    "${BASH_TOOLS_ROOT_DIR}/bin" \
    TOKEN_NOT_FOUND_COUNT \
    '(bash-tpl|plantuml|definitionLint|compile|installFacadeExample)$'

  # inject plantuml diagram source code into command
  sed -E -i \
    -e "/@@@mysql2puml_plantuml_diagram@@@/r ${BASH_TOOLS_ROOT_DIR}/src/_binaries/Converters/testsData/mysql2puml.puml" \
    -e "/@@@mysql2puml_plantuml_diagram@@@/d" \
    "${DOC_DIR}/Commands.md"

  mkdir -p "${DOC_DIR}/src/_binaries/Converters/testsData" || true
  cp "${BASH_TOOLS_ROOT_DIR}/src/_binaries/Converters/testsData/mysql2puml-model.png" "${DOC_DIR}/src/_binaries/Converters/testsData"

  # copy other files
  cp "${BASH_TOOLS_ROOT_DIR}/README.md" "${DOC_DIR}/README.md"
  sed -i -E \
    -e '/<!-- remove -->/,/<!-- endRemove -->/d' \
    -e 's#https://fchastanet.github.io/bash-tools/#/#' \
    -e 's#^> \*\*_TIP:_\*\* (.*)$#> [!TIP|label:\1]#' \
    "${DOC_DIR}/README.md"

  ShellDoc::fixMarkdownToc "${DOC_DIR}/README.md"
  ShellDoc::fixMarkdownToc "${DOC_DIR}/Commands.md"

  if ((TOKEN_NOT_FOUND_COUNT > 0)); then
    return 1
  fi

  Log::displayStatus "Doc generated in ${ORIGINAL_DOC_DIR} folder"
}

if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "1" ]]; then
  run &>/dev/null
else
  run
fi
