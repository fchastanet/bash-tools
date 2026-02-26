#!/usr/bin/env bash

# shellcheck disable=SC2034,SC2154

Linux::requireExecutedAsUser

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

generateGenericCommand() {
  local commandName="$1"
  (
    echo "#!/bin/bash"
    echo "${commandName} command is not available in doc generation container, it is only used for tests data generation"
  ) >"${binTempDir}/${commandName}"
  chmod +x "${binTempDir}/${commandName}"
}

configureContainer() {
  mkdir -p "${HOME}/.bash-tools"
  local binTempDir="$1"

  (
    cd "${BASH_TOOLS_ROOT_DIR}" || exit 1
    cp -R conf/. "${HOME}/.bash-tools"
    sed -i \
      -e "s@^S3_BASE_URL=.*@S3_BASE_URL=s3://example.com/exports/@g" \
      "${HOME}/.bash-tools/.env"
    # fake docker command
    touch "${binTempDir}/docker"
    chmod 755 "${binTempDir}/docker"
  )

  generateGenericCommand "yq"
  generateGenericCommand "mysql"
  generateGenericCommand "mysqldump"
  generateGenericCommand "mysqlshow"

  export PATH="${binTempDir}:${PATH}"
}

generateDoc() {
  local ROOT_DIR=/bash
  local DOC_DIR="${ROOT_DIR}/content/docs"
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
    -e "/@@@mysql2puml_plantuml_diagram@@@/r ${BASH_TOOLS_ROOT_DIR}/src/_binaries/Converters/mysql2puml/testsData/mysql2puml.puml" \
    -e "/@@@mysql2puml_plantuml_diagram@@@/d" \
    "${DOC_DIR}/Commands.md"

  if ((TOKEN_NOT_FOUND_COUNT > 0)); then
    return 1
  fi

  Log::displayStatus "Doc generated in ${ORIGINAL_DOC_DIR} folder"
}

if [[ "${IN_BASH_DOCKER:-}" != "You're in docker" ]]; then
  Git::requireGitCommand
  installRequirements
  if [[ "${optionContinuousIntegrationMode}" = "1" ]]; then
    chmod -R 777 content/docs
  fi
  runContainer
  if [[ "${optionContinuousIntegrationMode}" = "1" ]]; then
    # restore previous rights
    find content/docs -type d -exec chmod 755 {} ';'
    find content/docs -type f -exec chmod 644 {} ';'
  fi
else
  tmpDir=$(mktemp -d)
  trap 'rm -rf "${tmpDir}"' EXIT
  configureContainer "${tmpDir}"
  generateDoc
fi
