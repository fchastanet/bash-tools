#!/usr/bin/env bash

CURRENT_DIR=$( cd "$( readlink -e "${BASH_SOURCE[0]%/*}" )" && pwd )

TOMDOC_VERSION="cut_by_declaration_types"
[[ ! -f "${CURRENT_DIR}/vendor/fchastanet.tomdoc.sh/tomdoc.sh" ]] && (
    rm -Rf "${CURRENT_DIR}/vendor/fchastanet.tomdoc.sh"
    git clone git://github.com/tests-always-included/tomdoc.sh.git "${CURRENT_DIR}/vendor/fchastanet.tomdoc.sh"
    cd "${CURRENT_DIR}/vendor/fchastanet.tomdoc.sh"
    git checkout ${TOMDOC_VERSION}
)

generateShDoc() {
  local file="$1"
  local currentDir="$2"
  local relativeFile="${file#"${currentDir}/"}"
  local basename="${file##*/}"
  local basenameNoExtension="${basename%.*}"

  cd "${currentDir}"
  echo "generate markdown doc for ${relativeFile} in doc/${basenameNoExtension}.md"
  "./vendor/fchastanet.tomdoc.sh/tomdoc.sh" --markdown "${relativeFile}" > "${currentDir}/doc/${basenameNoExtension}.md"
}
export -f generateShDoc

mkdir -p "${CURRENT_DIR}/doc"

find "${CURRENT_DIR}/bash-framework" -name "*.sh" -exec bash -c "generateShDoc '{}' '${CURRENT_DIR}'" \;

