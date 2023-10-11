#!/usr/bin/env bash
# BIN_FILE=${FRAMEWORK_ROOT_DIR}/bin/dbImport
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE

.INCLUDE "$(dynamicTemplateDir _binaries/DbImport/dbImport.options.tpl)"

# dump header/footer
read -r -d '\0' DUMP_HEADER <<-EOM
    SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS = 0;
    SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, AUTOCOMMIT = 0;
    SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS = 0;\0
EOM

read -r -d '\0' DUMP_FOOTER <<-EOM2
    COMMIT;
    SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
    SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
    SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;\0
EOM2

declare DUMP_SIZE_QUERY
DUMP_SIZE_QUERY="$(
  cat <<'EOF'
.INCLUDE "${TEMPLATE_DIR}/_binaries/DbImport/dumpSizeQuery.sql"
EOF
)"

dbImportCommand parse "${BASH_FRAMEWORK_ARGV[@]}"

# @require Linux::requireExecutedAsUser
run() {


  # check dependencies
  Assert::commandExists mysql "sudo apt-get install -y mysql-client"
  Assert::commandExists mysqlshow "sudo apt-get install -y mysql-client"
  Assert::commandExists mysqldump "sudo apt-get install -y mysql-client"
  Assert::commandExists pv "sudo apt-get install -y pv"
  Assert::commandExists gawk "sudo apt-get install -y gawk"
  Assert::commandExists awk "sudo apt-get install -y gawk"
  Version::checkMinimal "gawk" "--version" "5.0.1"

  # create db instances
  declare -Agx dbFromInstance dbTargetDatabase

  # shellcheck disable=SC2154
  Database::newInstance dbTargetDatabase "${optionTargetDsn}"
  Database::setQueryOptions dbTargetDatabase "${dbTargetDatabase[QUERY_OPTIONS]} --connect-timeout=5"
  Log::displayInfo "Using target dsn ${dbTargetDatabase['DSN_FILE']}"
  if [[ -z "${optionFromAws}" ]]; then
    # shellcheck disable=SC2154
    Database::newInstance dbFromInstance "${optionFromDsn}"
    Database::setQueryOptions dbFromInstance "${dbFromInstance[QUERY_OPTIONS]} --connect-timeout=5"
    Log::displayInfo "Using from dsn ${dbFromInstance['DSN_FILE']}"
  fi

  local remoteDbDumpTempFile
  local remoteDbStructureDumpTempFile
  if [[ -n "${optionFromAws}" ]]; then
    remoteDbDumpTempFile="${DB_IMPORT_DUMP_DIR}/${optionFromAws}"
  else
    # shellcheck disable=SC2154
    remoteDbDumpTempFile="${DB_IMPORT_DUMP_DIR}/${fromDbName}_${optionProfile}.sql.gz"
    remoteDbStructureDumpTempFile="${DB_IMPORT_DUMP_DIR}/${fromDbName}_${optionProfile}_structure.sql.gz"
  fi

  # check if local dump exists
  local downloadDump=0
  if [[ ! -f "${remoteDbDumpTempFile}" ]]; then
    Log::displayInfo "local dump does not exist"
    downloadDump=1
  fi
  if [[ -z "${optionFromAws}" && ! -f "${remoteDbStructureDumpTempFile}" ]]; then
    Log::displayInfo "local structure dump does not exist"
    downloadDump=1
  fi
  if [[ "${downloadDump}" = "0" ]]; then
    Log::displayInfo "local dump ${remoteDbDumpTempFile} already exists, avoid download"
  fi

  Log::displayInfo "tables list will calculated using profile ${optionProfile} => ${profileCommand}"
  SECONDS=0
  if [[ "${downloadDump}" = "1" ]]; then
    Log::displayInfo "Download dump"

    if [[ -n "${optionFromAws}" ]]; then
      # download dump from s3
      local s3Url="${S3_BASE_URL%/}/${optionFromAws}"
      aws s3 ls --human-readable "${s3Url}" || {
        Log::fatal "Command ${SCRIPT_NAME} - unable to get information on S3 object : ${s3Url}"
      }
      Log::displayInfo "Download dump from ${s3Url} ..."
      TMPDIR="${TMDIR:-/tmp}" aws s3 cp "${s3Url}" "${remoteDbDumpTempFile}" || {
        Log::fatal "Command ${SCRIPT_NAME} - unable to download dump from S3 : ${s3Url}"
      }
    else
      # check if remote db exists
      Database::ifDbExists dbFromInstance "${fromDbName}" || {
        Log::fatal "Command ${SCRIPT_NAME} - Remote Database ${fromDbName} does not exist"
      }

      initializeDefaultTargetMysqlOptions dbFromInstance "${fromDbName}"

      local dumpHeader
      dumpHeader=$(printf "%s\nSET names '%s';\n" "${DUMP_HEADER}" "${optionCharacterSet}")

      # calculate remote db dump size
      local listTables
      local listTablesDumpSize
      local listTablesDump
      listTables="$(Database::query dbFromInstance "show tables" "${fromDbName}" | ${profileCommand} | sort)"
      # shellcheck disable=SC2034 # used by DUMP_SIZE_QUERY
      listTablesDumpSize="$(echo "${listTables}" | awk -v d="," -v q="'" '{s=(NR==1?s:s d)q $0 q}END{print s }')"
      listTablesDump=$(echo "${listTables}" | awk -v d=" " -v q="" '{s=(NR==1?s:s d)q $0 q}END{print s }')

      Log::displayInfo "Calculate dump size for tables ${listTablesDump}"
      local remoteDbDumpSize
      remoteDbDumpSize=$(echo "${DUMP_SIZE_QUERY}" | envsubst | Database::query dbFromInstance)
      if [[ -z "${remoteDbDumpSize}" ]]; then
        # could occur with the none profile
        remoteDbDumpSize="0"
      fi

      # dump db
      Log::displayInfo "Dump the database ${fromDbName} (Size:${remoteDbDumpSize}MB) ..."
      local dumpSizePvEstimation
      dumpSizePvEstimation=$(awk "BEGIN {printf \"%.0f\",${remoteDbDumpSize}/1.5}")
      time (
        echo "${dumpHeader}"
        Database::dump dbFromInstance "${fromDbName}" "${listTablesDump}" \
          --no-create-info --skip-add-drop-table --single-transaction=TRUE |
          pv --progress --size "${dumpSizePvEstimation}m"
        echo "${DUMP_FOOTER}"
      ) | gzip >"${remoteDbDumpTempFile}"

      Log::displayInfo "Dump structure of the database ${fromDbName} ..."
      time (
        echo "${dumpHeader}"
        #shellcheck disable=SC2016
        Database::dump dbFromInstance "${fromDbName}" "" \
          --no-data --skip-add-drop-table --single-transaction=TRUE |
          sed 's/^CREATE TABLE `/CREATE TABLE IF NOT EXISTS `/g'
        echo "${DUMP_FOOTER}"
      ) | gzip >"${remoteDbStructureDumpTempFile}"
    fi
    Log::displayInfo "Dump done."
  fi

  # mark dumps as modified now to avoid them to be garbage collected
  touch -c -m "${remoteDbDumpTempFile}" || true
  touch -c -m "${remoteDbStructureDumpTempFile}" || true

  # TODO Collation and character set should be retrieved from dump files if possible
  # shellcheck disable=SC2154
  local targetCollationName="${optionCollationName:-${defaultTargetCollationName}}"
  # shellcheck disable=SC2154
  local taregtCharacterSet="${optionCharacterSet:-${defaultTargetCharacterSet}}"

  # shellcheck disable=SC2154
  Log::displayInfo "create target database ${targetDbName} if needed"
  #shellcheck disable=SC2016
  Database::query dbTargetDatabase \
    "$(printf 'CREATE DATABASE IF NOT EXISTS `%s` CHARACTER SET "%s" COLLATE "%s"' "${targetDbName}" "${taregtCharacterSet}" "${targetCollationName}")"

  if [[ -z "${optionFromAws}" ]]; then
    Database::setQueryOptions dbTargetDatabase "${dbTargetDatabase['DB_IMPORT_OPTIONS']}"
    Log::displayInfo "Importing remote db '${fromDbName}' to local db '${targetDbName}'"
    # shellcheck disable=SC2154
    if [[ "${optionSkipSchema}" = "1" ]]; then
      Log::displayInfo "avoid to create db structure"
    else
      Log::displayInfo "create db structure from ${remoteDbStructureDumpTempFile}"
      time (
        pv "${remoteDbStructureDumpTempFile}" | zcat |
          Database::query dbTargetDatabase "" "${targetDbName}"
      )
    fi
  fi
  Log::displayInfo "import remote to local from file ${remoteDbDumpTempFile}"
  local -a dbImportStreamOptions=(
    --profile "${optionProfile}" \
    --target-dsn "${optionTargetDsn}" \
    --character-set "${taregtCharacterSet}" \
  )
  if [[ -n "${optionTables:-}" ]]; then
    dbImportStreamOptions+=(
      --tables "${optionTables}" \
    )
  fi
  time (
    "${CURRENT_DIR}/dbImportStream" \
      "${dbImportStreamOptions[@]}" \
      "${remoteDbDumpTempFile}" \
      "${targetDbName}"

  )

  # garbage collect db import dumps
  File::garbageCollect "${DB_IMPORT_DUMP_DIR}" "${DB_IMPORT_GARBAGE_COLLECT_DAYS:-+30}" || true

  Log::displayInfo "Import database duration : $(date -u -d "@${SECONDS}" +"%T")"
}

if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "1" ]]; then
  run &>/dev/null
else
  run
fi
