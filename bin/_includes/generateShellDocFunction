#!/usr/bin/env bash

# extract shDoc from file
#
# @param {String} $1 currentDir
# @param {String} $2 relativeFile
# @output the shell documentation in markdown format
generateShellDoc() {
  local currentDir="$1"
  local relativeFile="$2"

  (
    cd "${currentDir}" || exit 1
    "${ROOT_DIR}/vendor/fchastanet.tomdoc.sh/tomdoc.sh" "${relativeFile}"
  )
}

# generate shell doc file
#
# @param {String} $1 currentDir
# @param {String} $2 relativeFile the file from which the markdown file will be generated
# @param {String} $3 targetDocFile the markdown file generated using tomdoc
# @return 0 if file has been generated, 1 if file is empty or error
# if generated doc is empty, targetDocFile is deleted if it was existing
generateShellDocFile() {
  local currentDir="$1"
  local relativeFile="$2"
  local targetDocFile="$3"

  (
    local doc
    doc="$(generateShellDoc "${currentDir}" "${relativeFile}")"
    if [[ -n "${doc}" ]]; then
      echo "${doc}" >"${targetDocFile}"
      return 0
    else
      # empty doc
      rm -f "${targetDocFile}" || true
      return 1
    fi
  )
}

# add reference to index file
# @param {String} $1 indexFile
# @param {String} $2 title
# @param {String} $3 mdRelativeFile
appendDocToIndex() {
  local indexFile="$1"
  local title="$2"
  local mdRelativeFile="$3"

  echo "* [${relativeFile}](doc/${basenameNoExtension}.md)" >>"${indexFile}"
  echo "* [${title}](${mdRelativeFile})" >>"${indexFile}"
}

# generate doc + index
# @param {String} $1 fromDir
# @param {String} $2 docDir
# @param {String} $3 indexFile
generateShellDocsFromDir() {
  local fromDir="$1"
  local docDir="$2"
  local indexFile="$3"

  while IFS= read -r relativeFile; do
    relativeFile="${relativeFile#./}"
    local basenameNoExtension="${relativeFile%.*}"
    local targetDocFile="${docDir}/${basenameNoExtension}.md"
    local targetDocDir

    # create target doc dir
    targetDocDir="$(dirname "${targetDocFile}")"
    mkdir -p "${targetDocDir}" || {
      Log::displayError "unable to create target doc directory ${targetDocDir}"
      return 1
    }

    # generate markdown file from shell file
    Log::displayInfo "generate markdown doc for ${relativeFile} in ${targetDocFile}"

    if generateShellDocFile "${fromDir}" "${relativeFile}" "${targetDocFile}"; then
      appendDocToIndex "${indexFile}" "${relativeFile}" "${basenameNoExtension}"
    fi
  done < <(cd "${fromDir}" && find . -name "*.sh" | sort)
}
