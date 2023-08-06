#!/usr/bin/env bash

rootDir="$(cd "$(readlink -e "${BASH_SOURCE[0]%/*}")/.." && pwd -P)"
# shellcheck disable=SC2034
binDir="${rootDir}/bin"
vendorDir="${rootDir}/vendor"
FRAMEWORK_DIR="$(cd "$(readlink -e "${vendorDir}/bash-tools-framework")" && pwd -P)"
export FRAMEWORK_DIR

load "${FRAMEWORK_DIR}/vendor/bats-support/load.bash"
load "${FRAMEWORK_DIR}/vendor/bats-assert/load.bash"
load "${FRAMEWORK_DIR}/vendor/bats-mock-Flamefire/load.bash"

# shellcheck source=vendor/bash-tools-framework/src/_standalone/Bats/assert_lines_count.sh
source "${FRAMEWORK_DIR}/src/_standalone/Bats/assert_lines_count.sh"
# shellcheck source=vendor/bash-tools-framework/src/Env/load.sh
source "${FRAMEWORK_DIR}/src/Env/load.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/_.sh
source "${FRAMEWORK_DIR}/src/Log/_.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/displayDebug.sh
source "${FRAMEWORK_DIR}/src/Log/displayDebug.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/displayError.sh
source "${FRAMEWORK_DIR}/src/Log/displayError.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/displayHelp.sh
source "${FRAMEWORK_DIR}/src/Log/displayHelp.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/displayInfo.sh
source "${FRAMEWORK_DIR}/src/Log/displayInfo.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/displaySkipped.sh
source "${FRAMEWORK_DIR}/src/Log/displaySkipped.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/displaySuccess.sh
source "${FRAMEWORK_DIR}/src/Log/displaySuccess.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/displayWarning.sh
source "${FRAMEWORK_DIR}/src/Log/displayWarning.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/logMessage.sh
source "${FRAMEWORK_DIR}/src/Log/logMessage.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/fatal.sh
source "${FRAMEWORK_DIR}/src/Log/fatal.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/logFatal.sh
source "${FRAMEWORK_DIR}/src/Log/logFatal.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/logDebug.sh
source "${FRAMEWORK_DIR}/src/Log/logDebug.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/logError.sh
source "${FRAMEWORK_DIR}/src/Log/logError.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/logHelp.sh
source "${FRAMEWORK_DIR}/src/Log/logHelp.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/logInfo.sh
source "${FRAMEWORK_DIR}/src/Log/logInfo.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/logSkipped.sh
source "${FRAMEWORK_DIR}/src/Log/logSkipped.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/logSuccess.sh
source "${FRAMEWORK_DIR}/src/Log/logSuccess.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/logWarning.sh
source "${FRAMEWORK_DIR}/src/Log/logWarning.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/rotate.sh
source "${FRAMEWORK_DIR}/src/Log/rotate.sh"
# shellcheck source=vendor/bash-tools-framework/src/Log/load.sh
source "${FRAMEWORK_DIR}/src/Log/load.sh"

export BASH_FRAMEWORK_LOG_FILE="${BATS_TEST_TMPDIR}/logFile"
export BASH_FRAMEWORK_DISPLAY_LEVEL="${__LEVEL_INFO}"
Env::load
Log::load
