#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/installRequirements
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "$(dynamicTemplateDir _header.tpl)"

.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/executedAsUser.sh"

HELP="$(
  cat <<EOF
${__HELP_TITLE}Description:${__HELP_NORMAL} installs requirements(fchastanet/bash-tools-framework)
${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME}

.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/author.tpl"
EOF
)"
Args::defaultHelp "${HELP}" "$@"

mkdir -p "${ROOT_DIR}/vendor" || true
Git::cloneOrPullIfNoChanges \
  "${ROOT_DIR}/vendor/bash-tools-framework" \
  "https://github.com/fchastanet/bash-tools-framework.git"

Log::displayInfo "Copying useful binaries from bash-tools-framework"
declare -a externalBinaries=(
  "${FRAMEWORK_DIR}/bin/awkLint"
  "${FRAMEWORK_DIR}/bin/buildBinFiles"
  "${FRAMEWORK_DIR}/bin/frameworkLint"
  "${FRAMEWORK_DIR}/bin/findShebangFiles"
  "${FRAMEWORK_DIR}/bin/generateShellDoc"
  "${FRAMEWORK_DIR}/bin/megalinter"
  "${FRAMEWORK_DIR}/bin/runBuildContainer"
  "${FRAMEWORK_DIR}/bin/shellcheckLint"
  "${FRAMEWORK_DIR}/bin/test"
  "${FRAMEWORK_DIR}/bin/buildPushDockerImages"
)
cp -v "${externalBinaries[@]}" "${ROOT_DIR}/bin"
