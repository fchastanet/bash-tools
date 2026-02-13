#!/usr/bin/env bash
# @embed "${BASH_TOOLS_ROOT_DIR}/src/_binaries/Database/dbImportStream/dbImportStream.awk" AS dbImportStreamScript
# @embed "${BASH_TOOLS_ROOT_DIR}/src/_binaries/Database/dbImportStream/dbImportStreamMultipleTables.awk" AS dbImportStreamMultipleTablesScript

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
declare awkScriptFile="${embed_file_dbImportStreamScript}"

# shellcheck disable=2086,2154
if [[ "${optionAwsFileType}" == "tar.multiple.tables.gz" ]]; then
  awkScriptFile="${embed_file_dbImportStreamMultipleTablesScript}"
  # Process each table individually - this matches the AWK script's design
  while read -r tableDumpFile; do
    if [[ -n "${tableDumpFile}" ]]; then
      Log::displayInfo "Processing table dump file ${tableDumpFile} from ${argDumpFile}"
      (
        tar xOf "${argDumpFile}" "${tableDumpFile}" | zcat
      ) | (
        awk \
          -v PROFILE_COMMAND="${profileCommandFile}" \
          -v CHARACTER_SET="${remoteCharacterSet}" \
          -f "${embed_file_dbImportStreamMultipleTablesScript}" \
          -
      ) | (
        mysql \
          "--defaults-extra-file=${dbTargetInstance['AUTH_FILE']}" \
          ${dbTargetInstance['DB_IMPORT_OPTIONS']} \
          "${argTargetDbName}"
      )

      pipeStatus=("${PIPESTATUS[@]}")
      if [[ "${pipeStatus[0]}" -ne 0 || "${pipeStatus[1]}" -ne 0 || "${pipeStatus[2]}" -ne 0 ]]; then
        Log::displayError "Failed processing ${tableDumpFile}: tar=${pipeStatus[0]}, awk=${pipeStatus[1]}, mysql=${pipeStatus[2]}"
        Bash::handlePipelineFailure status pipeStatus
        break
      fi
    fi
  done < <(tar tf "${argDumpFile}" 2>/dev/null | grep '\.sql\.gz$' || true)
else
  (
    if [[ "${optionAwsFileType}" == "auto" ]]; then
      if [[ "${argDumpFile}" =~ \.tar.gz$ || "${argDumpFile}" =~ \.tgz$ ]]; then
        optionAwsFileType="tar.gz"
      elif [[ "${argDumpFile}" =~ \.tar$ ]]; then
        optionAwsFileType="tar"
      elif [[ "${argDumpFile}" =~ \.gz$ ]]; then
        optionAwsFileType="gz"
      fi
    fi
    if [[ "${optionAwsFileType}" == "tar.gz" ]]; then
      tar xOfz "${argDumpFile}"
    elif [[ "${optionAwsFileType}" == "tar" ]]; then
      tar xOf "${argDumpFile}"
    elif [[ "${optionAwsFileType}" == "gz" ]]; then
      zcat "${argDumpFile}"
    else
      cat "${argDumpFile}"
    fi
  ) | (
    awk \
      -v PROFILE_COMMAND="${profileCommandFile}" \
      -v CHARACTER_SET="${remoteCharacterSet}" \
      -f "${awkScriptFile}" \
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
fi
