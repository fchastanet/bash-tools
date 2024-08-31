#!/usr/bin/env bash
# @embed "${BASH_TOOLS_ROOT_DIR}/src/_binaries/Database/dbImportStream/dbImportStream.awk" AS dbImportStreamScript

# create db instances
declare -Agx dbTargetInstance

# shellcheck disable=SC2154
Database::newInstance dbTargetInstance "${optionTargetDsn}"
Database::setQueryOptions dbTargetInstance "${dbTargetInstance[QUERY_OPTIONS]} --connect-timeout=5"
Log::displayInfo "Using target dsn ${dbTargetInstance['DSN_FILE']}"

# shellcheck disable=SC2154
initializeDefaultTargetMysqlOptions dbTargetInstance "${argTargetDbName}"

# TODO character set should be retrieved from dump files if possible
declare remoteCharacterSet="${optionCharacterSet:-${defaultRemoteCharacterSet}}"

# shellcheck disable=SC2034
declare status=0
# shellcheck disable=SC2034
declare -a pipeStatus=()

# shellcheck disable=2086,2154
(
  if [[ "${argDumpFile}" =~ \.tar.gz$ ]]; then
    tar xOfz "${argDumpFile}"
  elif [[ "${argDumpFile}" =~ \.gz$ ]]; then
    zcat "${argDumpFile}"
  fi
) | (
  awk \
    -v PROFILE_COMMAND="${profileCommandFile}" \
    -v CHARACTER_SET="${remoteCharacterSet}" \
    -f "${embed_file_dbImportStreamScript}" \
    -
) | (
  mysql \
    "--defaults-extra-file=${dbTargetInstance['AUTH_FILE']}" \
    ${dbTargetInstance['DB_IMPORT_OPTIONS']} \
    "${argTargetDbName}"
) || (
  # zcat will continue to write to stdout whereas awk has finished if table has been found
  # we detect this case because zcat will return code 141 because pipe closed
  Bash::handlePipelineFailure status pipeStatus
)
