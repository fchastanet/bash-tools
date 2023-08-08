#!/usr/bin/env bash
# BIN_FILE=${FRAMEWORK_ROOT_DIR}/bin/installRequirements

.INCLUDE "$(dynamicTemplateDir _includes/_header.tpl)"
.INCLUDE "$(dynamicTemplateDir _includes/_load.tpl)"

.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/executedAsUser.sh"

HELP="$(
  cat <<EOF
${__HELP_TITLE}Description:${__HELP_NORMAL} installs requirements(fchastanet/bash-tools-framework)
${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME}

.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/author.tpl"
EOF
)"
Args::defaultHelp "${HELP}" "$@"

mkdir -p "${BASH_TOOLS_ROOT_DIR}/vendor" || true
Git::cloneOrPullIfNoChanges \
  "${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework" \
  "https://github.com/fchastanet/bash-tools-framework.git"

Log::displayInfo "Copying useful binaries from bash-tools-framework"
declare -a externalBinaries=(
  "${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework/bin/awkLint"
  "${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework/bin/buildBinFiles"
  "${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework/bin/frameworkLint"
  "${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework/bin/findShebangFiles"
  "${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework/bin/generateShellDoc"
  "${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework/bin/megalinter"
  "${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework/bin/runBuildContainer"
  "${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework/bin/shellcheckLint"
  "${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework/bin/test"
  "${BASH_TOOLS_ROOT_DIR}/vendor/bash-tools-framework/bin/buildPushDockerImages"
)
cp -v "${externalBinaries[@]}" "${BASH_TOOLS_ROOT_DIR}/bin"
