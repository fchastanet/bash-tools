#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/doc

.INCLUDE "$(dynamicTemplateDir _includes/_headerNoRootDir.tpl)"
ROOT_DIR="$(cd "${CURRENT_DIR}/.." && pwd -P)"
DOC_DIR="${ROOT_DIR}/pages"
HELP="$(
  cat <<EOF
${__HELP_TITLE}Description:${__HELP_NORMAL} generate markdown documentation
${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME}

.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/author.tpl"
EOF
)"
Args::defaultHelp "${HELP}" "$@"

if [[ "${IN_BASH_DOCKER:-}" != "You're in docker" ]]; then
  DOCKER_RUN_OPTIONS=$"-e ORIGINAL_DOC_DIR=${DOC_DIR}" \
    "${BIN_DIR}/runBuildContainer" "/bash/bin/doc" "$@"
  exit $?
fi

#-----------------------------
# configure docker environment
#-----------------------------
mkdir -p "${HOME}/.bash-tools"

(
  cd "${ROOT_DIR}" || exit 1
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
  "${ROOT_DIR}/Commands.tmpl.md" \
  "${DOC_DIR}/Commands.md" \
  "${BIN_DIR}" \
  TOKEN_NOT_FOUND_COUNT

# inject plantuml diagram source code into command
sed -E -i \
  -e "/@@@mysql2puml_plantuml_diagram@@@/r ${ROOT_DIR}/src/_binaries/Converters/testsData/mysql2puml.puml" \
  -e "/@@@mysql2puml_plantuml_diagram@@@/d" \
  "${DOC_DIR}/Commands.md"

mkdir -p "${DOC_DIR}/src/_binaries/Converters/testsData" || true
cp "${ROOT_DIR}/src/_binaries/Converters/testsData/mysql2puml-model.png" "${DOC_DIR}/src/_binaries/Converters/testsData"

# copy other files
cp "${ROOT_DIR}/README.md" "${DOC_DIR}/README.md"
sed -i -E \
  -e '/<!-- remove -->/,/<!-- endRemove -->/d' \
  -e 's#https://fchastanet.github.io/bash-tools/#/#' \
  -e 's#^> \*\*_TIP:_\*\* (.*)$#> [!TIP|label:\1]#' \
  "${DOC_DIR}/README.md"

ShellDoc::fixMarkdownToc "${DOC_DIR}/README.md"
ShellDoc::fixMarkdownToc "${DOC_DIR}/Commands.md"

if ((TOKEN_NOT_FOUND_COUNT > 0)); then
  exit 1
fi

Log::displayStatus "Doc generated in ${ORIGINAL_DOC_DIR} folder"
