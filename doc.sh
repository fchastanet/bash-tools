#!/usr/bin/env bash

set -o errexit
set -o pipefail

CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ "${IN_BASH_DOCKER:-}" != "You're in docker" ]; then
  "${CURRENT_DIR}/.build/runBuildContainer.sh" "/bash/doc.sh" "$@"
  exit $?
fi

INDEX_FILE="/tmp/Index.md"

generateShDoc() {
  local file="$1"
  local currentDir="$2"
  local indexFile="$3"
  local relativeFile="${file#"${currentDir}/"}"
  local basename="${file##*/}"
  local basenameNoExtension="${basename%.*}"

  cd "${currentDir}" || exit 1
  echo "generate markdown doc for ${relativeFile} in doc/${basenameNoExtension}.md"

  local doc
  doc="$("./vendor/fchastanet.tomdoc.sh/tomdoc.sh" "${relativeFile}")"
  if [[ -n "${doc}" ]]; then
    echo "${doc}" > "${currentDir}/doc/${basenameNoExtension}.md"

    # add reference to index file
    echo "* [${relativeFile}](doc/${basenameNoExtension}.md)" >> "${indexFile}"
  else
    # empty doc
    rm -f "${currentDir}/doc/${basenameNoExtension}.md" || true
  fi
}
export -f generateShDoc

escapeColorCodes() {
  cat - | sed $'s/\e\\[[0-9;:]*[a-zA-Z]//g'
}

generateReadme() {
  # generate README.md
  export gitRenameBranch_help="$(/bash/bin/gitRenameBranch --help | escapeColorCodes)"
  export dbQueryAllDatabases_help="$(/bash/bin/dbQueryAllDatabases --help | escapeColorCodes)"
  export dbScriptAllDatabases_help="$(/bash/bin/dbScriptAllDatabases --help | escapeColorCodes)"
  export dbImport_help="$(/bash/bin/dbImport --help | escapeColorCodes)"
  export dbImportProfile_help="$(/bash/bin/dbImportProfile --help | escapeColorCodes)"
  export gitIsAncestorOf_help="$(/bash/bin/gitIsAncestorOf --help | escapeColorCodes)"
  export gitIsBranch_help="$(/bash/bin/gitIsBranch --help | escapeColorCodes)"
  export cli_help="$(/bash/bin/cli --help | escapeColorCodes)"
  export bash_doc_index="$(cat "${INDEX_FILE}")"

  envsubst < "${CURRENT_DIR}/README.tmpl.md" > "${CURRENT_DIR}/README.md"
}

#-----------------------------
# configure environment
#-----------------------------
mkdir -p ~/.bash-tools
cp -R conf/. ~/.bash-tools
sed -i \
  -e "s@^BASH_TOOLS_FOLDER=.*@BASH_TOOLS_FOLDER=$(pwd)@g" \
  -e "s@^S3_BASE_URL=.*@S3_BASE_URL=s3://example.com/exports/@g" \
  ~/.bash-tools/.env
# fake docker command
touch /tmp/docker
chmod 755 /tmp/docker
export PATH=/tmp:$PATH

#-----------------------------
# doc generation
#-----------------------------
# generate doc + index
mkdir -p "${CURRENT_DIR}/doc"
declare -a cmd
cmd=(generateShDoc '{}' "${CURRENT_DIR}" "${INDEX_FILE}")
find "${CURRENT_DIR}/bash-framework" -name "*.sh" -exec bash -c "${cmd[*]}" \;

# generate readme
echo "generate README.md"
generateReadme

# cleaning
rm -f "${INDEX_FILE}"