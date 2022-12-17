#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/doc
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"
DOC_DIR="${ROOT_DIR}/jekyll"

if [[ "${IN_BASH_DOCKER:-}" != "You're in docker" ]]; then
  "${BIN_DIR}/runBuildContainer" "/bash/bin/doc" "$@"
  exit $?
fi

Args::defaultHelp "Generate Jekyll documentation" "$@"

((TOKEN_NOT_FOUND_COUNT = 0)) || true

replaceTokenByInput() {
  local token="$1"
  local targetFile="$2"

  (
    local tokenFile
    tokenFile="$(Framework::createTempFile "replaceTokenByInput")"

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

  while IFS= read -r relativeFile; do
    local token="${relativeFile#./}"
    token="${token////_}"
    if grep -q "@@@${token}_help@@@" "${targetFile}"; then
      Log::displayInfo "generate help for ${token}"
      ( #
        (cd "${fromDir}" && "${relativeFile}" --help) |
          replaceTokenByInput "@@@${token}_help@@@" "${targetFile}"
      ) || Log::displayError "$(realpath "${fromDir}/${relativeFile}" --relative-to="${ROOT_DIR}") --help error caught"
    else
      ((++TOKEN_NOT_FOUND_COUNT))
      Log::displayWarning "token ${token} not found in ${targetFile}"
    fi
  done < <(cd "${fromDir}" && find . -type f -executable)
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

Log::displayInfo 'generate Commands.md'
generateMdFileFromTemplate \
  "${ROOT_DIR}/Commands.tmpl.md" \
  "${DOC_DIR}/Commands.md" \
  "${BIN_DIR}"

# inject plantuml diagram source code into command
sed -i \
  -e "/@@@mysql2puml_plantuml_diagram@@@/r ${ROOT_DIR}/tests/data/mysql2puml.puml" \
  -e "/@@@mysql2puml_plantuml_diagram@@@/d" \
  "${DOC_DIR}/Commands.md"

mkdir -p "${DOC_DIR}/tests/data" || true
cp "${ROOT_DIR}/tests/data/mysql2puml-model.png" "${DOC_DIR}/tests/data"

# copy other files
cp "${ROOT_DIR}/README.md" "${DOC_DIR}/README.md"

if ((TOKEN_NOT_FOUND_COUNT > 0)); then
  exit 1
fi
