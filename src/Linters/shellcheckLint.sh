#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/shellcheckLint
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

# check if command in PATH is already the minimal version needed
if ! Version::checkMinimal "shellcheck" "--version" "0.8.0"; then
  install() {
    local file="$1"
    local targetFile="$2"
    local version="$3"
    local tempDir
    tempDir="$(mktemp -d -p "${TMPDIR:-/tmp}" -t bash-framework-shellcheck-$$-XXXXXX)"
    (
      cd "${tempDir}" || exit 1
      tar -xJvf "${file}"
      mv "shellcheck-v${version}/shellcheck" "${targetFile}"
      chmod +x "${targetFile}"
    )
  }
  Github::upgradeRelease \
    "${VENDOR_BIN_DIR}/shellcheck" \
    "https://github.com/koalaman/shellcheck/releases/download/v@latestVersion@/shellcheck-v@latestVersion@.linux.x86_64.tar.xz" \
    "--version" \
    Version::getCommandVersionFromPlainText \
    install
fi

if (($# == 0)); then
  set -- --check-sourced -x -f checkstyle
fi

(
  # shellcheck disable=SC2046
  LC_ALL=C.UTF-8 shellcheck "$@" \
    $(
      find . -type f -executable \
        -not -path './vendor/*' \
        -not -path './.git/*' \
        -not -path './megalinter-reports/*' \
        -not -path './bin/hadolint' \
        -not -path './bin/shellcheck' \
        -not -path './.docker/*' \
        -not -path './.history/*' \
        -not -path './tests/data/*' \
        -regextype posix-egrep \
        ! -regex '.*\.(awk)$'
    )
)
