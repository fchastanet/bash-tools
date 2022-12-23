#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/installRequirements
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/executedAsUser.sh"

HELP="$(
  cat <<EOF
${__HELP_TITLE}Description:${__HELP_NORMAL} installs requirements(fchastanet/bash-tools-framework)
${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME}

.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/author.tpl"
EOF
)"
Args::defaultHelp "${HELP}" "$@"

Git::cloneOrPullIfNoChanges \
  "${ROOT_DIR}/vendor/bash-tools-framework" \
  "https://github.com/fchastanet/bash-tools-framework.git"

declare -a externalBinaries=(
  awkLint
  buildPushDockerImages
  dockerLint
  generateShellDoc
  runBuildContainer
  shellcheckLint
  "test"
)

declare bin
for bin in "${externalBinaries[@]}"; do
  Log::displayInfo "Creating symlink to bash-tools-framework/bin/${bin} in bin directory"
  ln -srf "${VENDOR_DIR}/bash-tools-framework/bin/${bin}" "${ROOT_DIR}/bin/${bin}"
done
