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

deduceDumpKindFromFilename() {
  local dumpFile="$1"
  Log::displayInfo "Deducing dump file format from filename ${dumpFile}"
  if [[ "${dumpFile}" =~ \.sql$ ]]; then
    echo "sql"
  elif [[ "${dumpFile}" =~ \.tar$ ]]; then
    echo "tar"
  elif [[ "${dumpFile}" =~ (\.tar\.gz|\.tgz)$ ]]; then
    echo "tar.gz"
  elif [[ "${dumpFile}" =~ \.tar\.individual\.sql\.gz$ ]]; then
    echo "tar.individual.sql.gz"
  elif [[ "${dumpFile}" =~ \.gz$ ]]; then
    echo "gz"
  else
    Log::displayError "Unable to deduce dump file format from filename ${dumpFile} - use --dump-kind option to specify the format"
    return 1
  fi
}

isAlpine() {
  [[ "$(Linux::getDistributorId)" =~ alpine ]]
}

loadTarDumpFile() {
  local dumpFile="$1"
  tar xf "${dumpFile}"
}

loadGzipDumpFile() {
  local dumpFile="$1"
  zcat "${dumpFile}"
}

# alpine tar does not support --wildcards,
# so we need to extract all files and cat them
alpineTarWildcardsAlternative() {
  local dumpFile="$1"
  local tarOptions="$2"
  local tempDir
  tempDir="$(mktemp -d)"
  (
    trap 'rm -rf "${tempDir}"' EXIT
    cd "${tempDir}" || exit 1
    tar "${tarOptions}" "${dumpFile}"
    ls -al
    cat ./*.sql
  )
}

loadTgzIndividualSql() {
  local dumpFile="$1"
  if isAlpine; then
    alpineTarWildcardsAlternative "${dumpFile}" "xzf"
  else
    tar xOzf "${dumpFile}" --wildcards --no-anchored '*.sql'
  fi
}

loadTarIndividualSql() {
  local dumpFile="$1"
  if isAlpine; then
    alpineTarWildcardsAlternative "${dumpFile}" "xf"
  else
    tar xOf "${dumpFile}" --wildcards --no-anchored '*.sql'
  fi
}

loadTarIndividualSqlGz() {
  local dumpFile="$1"
  local sqlGzFile
  local -a sqlGzFiles
  mapfile -t sqlGzFiles < <(tar tf "${dumpFile}" | sort | grep -E '\.sql\.gz$')
  for sqlGzFile in "${sqlGzFiles[@]}"; do
    LOG_LAST_LOG_DATE_INIT=1 Log::computeDuration
    tar xOf "${dumpFile}" "${sqlGzFile}" | zcat || {
      if [[ $? = 141 ]]; then
        return 0
      fi
      # fail if any error during mysql or awk
      return $?
    }
    DISPLAY_DURATION=1 Log::displayInfo "Processed ${sqlGzFile}" >&2
  done
  return 0
}

loadDumpFile() {
  local dumpFile="$1"
  local dumpKind="$2"
  if [[ "${dumpKind}" == "sql" ]]; then
    cat "${dumpFile}"
  elif [[ "${dumpKind}" == "tar" ]]; then
    loadTarDumpFile "${dumpFile}"
  elif [[ "${dumpKind}" == "gz" ]]; then
    loadGzipDumpFile "${dumpFile}"
  elif [[ "${dumpKind}" == "tar" ]]; then
    loadTarIndividualSql "${dumpFile}"
  elif [[ "${dumpKind}" == "tar.gz" ]]; then
    loadTgzIndividualSql "${dumpFile}"
  elif [[ "${dumpKind}" == "tar.individual.sql.gz" ]]; then
    loadTarIndividualSqlGz "${dumpFile}"
  else
    Log::displayError "Unsupported dump file format for file ${dumpFile}"
    exit 1
  fi
  return 0
}

# shellcheck disable=SC2154
if [[ "${optionDumpKind}" = "auto" ]]; then
  # shellcheck disable=SC2154
  optionDumpKind="$(deduceDumpKindFromFilename "${argDumpFile}")"
  Log::displayInfo "Deduced dump file format is ${optionDumpKind}"
fi
# try process substitution to avoid SIGPIPE
# https://oneuptime.com/blog/post/2026-01-24-bash-broken-pipe/view
Log::displayInfo "Loading dump file ${argDumpFile} with format ${optionDumpKind}"
# shellcheck disable=2086,2154
(
  loadDumpFile "${argDumpFile}" "${optionDumpKind}" || {
    if [[ $? = 141 ]]; then
      return 0
    fi
    # fail if any error during mysql or awk
    return $?
  }
) | (
  awk \
    -v PROFILE_COMMAND="${profileCommandFile}" \
    -v RESET="${optionReset}" \
    -v CHARACTER_SET="${remoteCharacterSet}" \
    -f "${embed_file_dbImportStreamScript}" \
    -
) | (
  mysql \
    "--defaults-extra-file=${dbTargetInstance['AUTH_FILE']}" \
    ${dbTargetInstance['DB_IMPORT_OPTIONS']} \
    "${argTargetDbName}"
) || {
  # we detect this case because zcat will return code 141 because pipe closed
  Bash::handlePipelineFailure status pipeStatus
}
