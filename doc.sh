#!/usr/bin/env bash

CURRENT_DIR=$( cd "$( readlink -f "${BASH_SOURCE[0]%/*}" )" && pwd )

TOMDOC_VERSION="master"
[[ ! -f "${CURRENT_DIR}/vendor/fchastanet.tomdoc.sh/tomdoc.sh" ]] && (
    rm -Rf "${CURRENT_DIR}/vendor/fchastanet.tomdoc.sh"
    git clone github.com:fchastanet/tomdoc.sh.git "${CURRENT_DIR}/vendor/fchastanet.tomdoc.sh"
    cd "${CURRENT_DIR}/vendor/fchastanet.tomdoc.sh"
    git checkout ${TOMDOC_VERSION}
)

INDEX_FILE="${CURRENT_DIR}/doc/Index.md"
echo "# Documentation Index" > "${INDEX_FILE}"

generateShDoc() {
  local file="$1"
  local currentDir="$2"
  local indexFile="$3"
  local relativeFile="${file#"${currentDir}/"}"
  local basename="${file##*/}"
  local basenameNoExtension="${basename%.*}"

  cd "${currentDir}"
  echo "generate markdown doc for ${relativeFile} in doc/${basenameNoExtension}.md"

  local doc=$("./vendor/fchastanet.tomdoc.sh/tomdoc.sh" "${relativeFile}")
  if [[ -n "${doc}" ]]; then
    echo "${doc}" > "${currentDir}/doc/${basenameNoExtension}.md"

    # add reference to index file
    echo "[${relativeFile}](${basenameNoExtension}.md)" >> "${indexFile}"
    echo >> "${indexFile}"
  else
    # empty doc
    rm -f "${currentDir}/doc/${basenameNoExtension}.md" || true
  fi
}
export -f generateShDoc

mkdir -p "${CURRENT_DIR}/doc"

find "${CURRENT_DIR}/bash-framework" -name "*.sh" -exec bash -c "generateShDoc '{}' '${CURRENT_DIR}' '${INDEX_FILE}'" \;

