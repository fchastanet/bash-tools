#!/usr/bin/env bash
# BIN_FILE=${BASH_TOOLS_ROOT_DIR}/bin/doc
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE
# shellcheck disable=SC2034

declare copyrightBeginYear="2020"

.INCLUDE "$(dynamicTemplateDir _binaries/build/doc.options.tpl)"

installRequirements() {
  ShellDoc::installRequirementsIfNeeded
}

runContainer() {
  local image="scrasnups/build:bash-tools-ubuntu-5.3"
  local -a dockerRunCmd=(
    "/bash/bin/doc"
    "${BASH_FRAMEWORK_ARGV_FILTERED[@]}"
  )

  if ! docker inspect --type=image "${image}" &>/dev/null; then
    docker pull "${image}"
  fi
  # run docker image
  local -a localDockerRunArgs=(
    --rm
    -e KEEP_TEMP_FILES="${KEEP_TEMP_FILES:-0}"
    -e BATS_FIX_TEST="${BATS_FIX_TEST:-0}"
    -e ORIGINAL_DOC_DIR="${BASH_TOOLS_ROOT_DIR}/pages"
    -e SKIP_REQUIREMENTS_CHECKS=1
    --user "www-data:www-data"
    -w /bash
    -v "${BASH_TOOLS_ROOT_DIR}:/bash"
    --entrypoint /usr/local/bin/bash
  )

  # shellcheck disable=SC2154
  if [[ "${optionContinuousIntegrationMode}" = "0" ]]; then
    localDockerRunArgs+=(
      -v "/tmp:/tmp"
      -it
    )
  fi
  if [[ -d "${FRAMEWORK_ROOT_DIR}" ]]; then
    localDockerRunArgs+=(
      -v "$(cd "${FRAMEWORK_ROOT_DIR}" && pwd -P):/bash/vendor/bash-tools-framework"
    )
  fi

  # shellcheck disable=SC2154
  if [[ "${optionTraceVerbose}" = "1" ]]; then
    set -x
  fi
  docker run \
    "${localDockerRunArgs[@]}" \
    "${image}" \
    "${dockerRunCmd[@]}"
  set +x
}

configureContainer() {
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
}

generateDoc() {
  local ROOT_DIR=/bash
  local DOC_DIR="${ROOT_DIR}/pages"
  Log::displayInfo 'generate Commands.md'
  ((TOKEN_NOT_FOUND_COUNT = 0)) || true
  ShellDoc::generateMdFileFromTemplate \
    "${BASH_TOOLS_ROOT_DIR}/Commands.tmpl.md" \
    "${DOC_DIR}/Commands.md" \
    "${BASH_TOOLS_ROOT_DIR}/bin" \
    TOKEN_NOT_FOUND_COUNT \
    '(test|buildBinFiles)$'

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

run() {
  if [[ "${IN_BASH_DOCKER:-}" != "You're in docker" ]]; then
    installRequirements
    if [[ "${optionContinuousIntegrationMode}" = "1" ]]; then
      chmod -R 777 pages
    fi
    runContainer
    if [[ "${optionContinuousIntegrationMode}" = "1" ]]; then
      # restore previous rights
      find pages -type d -exec chmod 755 {} ';'
      find pages -type f -exec chmod 644 {} ';'
    fi
  else
    configureContainer
    generateDoc
  fi
}

if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "1" ]]; then
  run &>/dev/null
else
  run
fi
