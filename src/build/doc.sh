#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/doc
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

if [[ "${IN_BASH_DOCKER:-}" != "You're in docker" ]]; then
  "${BIN_DIR}/runBuildContainer" "/bash/bin/doc" "$@"
  exit $?
fi

replaceTokenByInput() {
  local token="$1"
  local targetFile="$2"

  (
    local tokenFile
    trap 'rm -f "${tokenFile}" || true' ERR EXIT
    tokenFile="$(mktemp "bash-tools.XXXXXXXX")"

    cat - | Filters::escapeColorCodes >"${tokenFile}"

    sed -i \
      -e "/${token}/r ${tokenFile}" \
      -e "/${token}/d" \
      "${targetFile}"
  )
}

generateMdFileFromTemplate() {
  local templateFile="$1"
  local targetFile="$2"
  local fromDir="$3"

  cp "${templateFile}" "${targetFile}"
  (
    while IFS= read -r relativeFile; do
      local token="${relativeFile#./}"
      token="${token///_}"
      if grep -q "@@@${token}_help@@@" "${targetFile}"; then
        Log::displayInfo "generate help for ${token}"
        (cd "${fromDir}" && "${relativeFile}" --help) | replaceTokenByInput "@@@${token}_help@@@" "${targetFile}"
      elif [[ "${token}" != "${SCRIPT_NAME}" ]]; then
        Log::displayWarning "token ${token} not found in ${targetFile}"
      fi
    done < <(cd "${fromDir}" && find . -type f -executable)
  )
}

#-----------------------------
# configure docker environment
#-----------------------------
mkdir -p ~/.bash-tools

(
  cd "${ROOT_DIR}" || exit 1
  cp -R conf/. ~/.bash-tools
  sed -i \
    -e "s@^BASH_TOOLS_FOLDER=.*@BASH_TOOLS_FOLDER=$(pwd)@g" \
    -e "s@^S3_BASE_URL=.*@S3_BASE_URL=s3://example.com/exports/@g" \
    ~/.bash-tools/.env
  # fake docker command
  touch /tmp/docker
  chmod 755 /tmp/docker
)
export PATH=/tmp:${PATH}

#-----------------------------
# doc generation
#-----------------------------

(
  trap 'rm -f "${indexFile}" || true' ERR EXIT
  declare indexFile
  indexFile="$(mktemp "bash-tools-index.XXXXXXXX")"

  Log::displayInfo 'generate doc folder'
  "${BIN_DIR}/generateShellDoc" "${ROOT_DIR}/src" "${ROOT_DIR}/doc" "${indexFile}"

  Log::displayInfo 'generate Commands.md'
  #cp "${ROOT_DIR}/tests/tools/data/mysql2puml.puml" "${TMP_DIR}/mysql2puml_plantuml_diagram"
  generateMdFileFromTemplate \
    "${ROOT_DIR}/Commands.tmpl.md" \
    "${ROOT_DIR}/Commands.md" \
    "${BIN_DIR}"

  sed -i \
    -e "/@@@mysql2puml_plantuml_diagram@@@/r ${ROOT_DIR}/tests/tools/data/mysql2puml.puml" \
    -e "/@@@mysql2puml_plantuml_diagram@@@/d" \
    "${ROOT_DIR}/Commands.md"
  # inject index file
  sed -i \
    -e "/@@@bash_doc_index@@@/r ${indexFile}" \
    -e "/@@@bash_doc_index@@@/d" \
    "${ROOT_DIR}/Commands.md"
)
