#!/usr/bin/env bash
# BIN_FILE=${FRAMEWORK_ROOT_DIR}/bin/dbImportStream
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE
# shellcheck disable=SC2034

# default values
declare optionProfile=""
declare argTargetDbName=""
declare argDumpFile=""
declare optionTargetDsn=""
declare optionCharacterSet=""
declare defaultTargetCharacterSet=""
declare profileCommandFile=""

# other configuration
declare copyrightBeginYear="2020"
declare PROFILES_DIR="${BASH_TOOLS_ROOT_DIR}/conf/dbImportProfiles"
declare HOME_PROFILES_DIR="${HOME}/.bash-tools/dbImportProfiles"

.INCLUDE "$(dynamicTemplateDir _binaries/DbImport/dbImportStream.options.tpl)"

declare awkScript
awkScript="$(
  cat <<'EOF'
.INCLUDE "$(dynamicSrcFile "_binaries/DbImport/dbImportStream.awk")"
EOF
)"

# @require Linux::requireExecutedAsUser
run() {

  # check dependencies
  Assert::commandExists mysql "sudo apt-get install -y mysql-client"
  Assert::commandExists gawk "sudo apt-get install -y gawk"
  Assert::commandExists awk "sudo apt-get install -y gawk"
  Version::checkMinimal "gawk" "--version" "5.0.1"

  # create db instances
  declare -Agx dbTargetInstance

  Database::newInstance dbTargetInstance "${optionTargetDsn}"
  Database::setQueryOptions dbTargetInstance "${dbTargetInstance[QUERY_OPTIONS]} --connect-timeout=5"
  Log::displayInfo "Using target dsn ${dbTargetInstance['DSN_FILE']}"

  initializeDefaultTargetMysqlOptions dbTargetInstance "${argTargetDbName}"

  # TODO character set should be retrieved from dump files if possible
  declare remoteCharacterSet="${optionCharacterSet:-${defaultRemoteCharacterSet}}"

  # shellcheck disable=2086
  (
    if [[ "${argDumpFile}" =~ \.tar.gz$ ]]; then
      tar xOfz "${argDumpFile}"
    elif [[ "${argDumpFile}" =~ \.gz$ ]]; then
      zcat "${argDumpFile}"
    fi
    # zcat will continue to write to stdout whereas awk has finished if table has been found
    # we detect this case because zcat will return code 141 because pipe closed
    status=$?
    if [[ "${status}" -eq "141" ]]; then true; else exit "${status}"; fi
  ) |
    awk \
      -v PROFILE_COMMAND="${profileCommandFile}" \
      -v CHARACTER_SET="${remoteCharacterSet}" \
      --source "${awkScript}" \
      - | mysql \
    "--defaults-extra-file=${dbTargetInstance['AUTH_FILE']}" \
    ${dbTargetInstance['DB_IMPORT_OPTIONS']} \
    "${argTargetDbName}" || exit $?
}

if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "1" ]]; then
  run &>/dev/null
else
  run
fi
