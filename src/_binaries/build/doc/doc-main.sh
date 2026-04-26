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
    -e ORIGINAL_DOC_DIR="${BASH_TOOLS_ROOT_DIR}/content"
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
  local binTempDir="$1"
  local commandName="$2"
  (
    echo "#!/usr/bin/env bash"
    echo "${commandName} command is not available in doc generation container"
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

  generateGenericCommand "${binTempDir}" "yq"
  generateGenericCommand "${binTempDir}" "mysql"
  generateGenericCommand "${binTempDir}" "mysqldump"
  generateGenericCommand "${binTempDir}" "mysqlshow"

  export PATH="${binTempDir}:${PATH}"
}

replaceToken() {
  local targetFile="$1"
  local command="$2"
  ( #
    Log::displayInfo "generate help for ${command}"
    "${ROOT_DIR}/${command}" --help |
      File::replaceTokenByInput "@@@${command}_help@@@" "${targetFile}"
  ) || Log::displayError "generate help for ${command} --help error caught"
}

generateDoc() {
  local ROOT_DIR=/bash
  local DOC_DIR="${ROOT_DIR}/content"
  ((TOKEN_NOT_FOUND_COUNT = 0)) || true

  local templateFile
  local templateBaseName
  for templateFile in "${BASH_TOOLS_ROOT_DIR}/assets/templates/Commands-"*.tmpl.md; do
    templateBaseName=$(basename "${templateFile}")
    local token="${templateBaseName#Commands-}"
    token="${token%.tmpl.md}"
    local targetFile="${DOC_DIR}/commands/${templateBaseName%.tmpl.md}.md"
    cp "${templateFile}" "${targetFile}"
    local binaryPath="${ROOT_DIR}/bin/${token}"
    if [[ "${token}" = "install" ]]; then
      # install command is in root folder
      binaryPath="${ROOT_DIR}/${token}"
    fi
    if [[ ! -x "${binaryPath}" || ! -f "${binaryPath}" ]]; then
      Log::displayError "No executable file found for ${token} command (${binaryPath})"
      ((TOKEN_NOT_FOUND_COUNT++))
      continue
    fi
    Log::displayInfo "generate help for ${token} command"
    "${binaryPath}" --help |
      File::replaceTokenByInput "@@@${token}_help@@@" "${targetFile}"
  done

  # check if all binaries have their associated template file
  local command
  local commandBaseName
  for command in "${ROOT_DIR}/bin/"*; do
    if [[ -x "${command}" && -f "${command}" ]]; then
      commandBaseName=$(basename "${command}")
      local expectedTemplateFile="${BASH_TOOLS_ROOT_DIR}/assets/templates/Commands-${commandBaseName}.tmpl.md"
      if [[ ! -f "${expectedTemplateFile}" ]]; then
        Log::displayError "No template file found for ${commandBaseName} command (${expectedTemplateFile})"
        ((TOKEN_NOT_FOUND_COUNT++))
      fi
    fi
  done

  if ((TOKEN_NOT_FOUND_COUNT > 0)); then
    return 1
  fi

  Log::displayInfo "inject plantuml diagram source code into command"
  sed -E -i \
    -e "/@@@mysql2puml_plantuml_diagram@@@/r ${BASH_TOOLS_ROOT_DIR}/src/_binaries/Converters/mysql2puml/testsData/mysql2puml.puml" \
    -e "/@@@mysql2puml_plantuml_diagram@@@/d" \
    "${DOC_DIR}/commands/Commands-mysql2puml.md"

  Log::displayInfo "copy plantuml images"
  mkdir -p "${DOC_DIR}/commands/assets"
  cp "${ROOT_DIR}/src/_binaries/Converters/mysql2puml/testsData/mysql2puml-model.png" \
    "${DOC_DIR}/commands/assets"

  Log::displayStatus "Doc generated in ${ORIGINAL_DOC_DIR} folder"
}

if [[ "${IN_BASH_DOCKER:-}" != "You're in docker" ]]; then
  Git::requireGitCommand
  installRequirements
  if [[ "${optionContinuousIntegrationMode}" = "1" ]]; then
    chmod -R 777 content
  fi
  runContainer
  if [[ "${optionContinuousIntegrationMode}" = "1" ]]; then
    # restore previous rights
    find content -type d -exec chmod 755 {} ';'
    find content -type f -exec chmod 644 {} ';'
  fi
else
  tmpDir=$(mktemp -d)
  trap 'rm -rf "${tmpDir}"' EXIT
  configureContainer "${tmpDir}"
  generateDoc
fi
