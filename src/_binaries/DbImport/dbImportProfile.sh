#!/usr/bin/env bash
# BIN_FILE=${FRAMEWORK_ROOT_DIR}/bin/dbImportProfile
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE

.INCLUDE "$(dynamicTemplateDir _binaries/DbImport/dbImportProfile.options.tpl)"

# shellcheck disable=SC2154
read -r -d '' QUERY <<EOM2 || true
SELECT
  TABLE_NAME AS tableName,
  ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024) as maxSize
FROM information_schema.TABLES
WHERE
  TABLE_SCHEMA = '@DB@'
  AND TABLE_TYPE NOT IN('VIEW')
ORDER BY maxSize DESC
EOM2

dbImportProfileCommand parse "${BASH_FRAMEWORK_ARGV[@]}"

# @require Linux::requireExecutedAsUser
run() {

  # check dependencies
  Assert::commandExists mysql "sudo apt-get install -y mysql-client"
  Assert::commandExists mysqlshow "sudo apt-get install -y mysql-client"

  # create db instance
  declare -Agx dbFromInstance

  # shellcheck disable=SC2154
  Database::newInstance dbFromInstance "${optionFromDsn}"
  Database::setQueryOptions dbFromInstance "${dbFromInstance[QUERY_OPTIONS]} --connect-timeout=5"
  Log::displayInfo "Using from dsn ${dbFromInstance['DSN_FILE']}"

  # check if from db exists
  # shellcheck disable=SC2154
  Database::ifDbExists dbFromInstance "${fromDbName}" || {
    Log::fatal "From Database ${fromDbName} does not exist !"
  }
  local tableList
  tableList="$(Database::query dbFromInstance "${QUERY//@DB@/${fromDbName}}" "information_schema")"
  # first table is the biggest one
  local maxTableSize
  maxTableSize="$(echo "${tableList}" | head -1 | awk -F ' ' '{print $2}')"
  (
    echo "#!/usr/bin/env bash"
    echo
    echo "# cat represents the whole list of tables"
    echo "cat |"
    local -i excludedTablesCount
    ((excludedTablesCount = 0)) || true
    local tableSize
    local tableName
    while IFS="" read -r line || [[ -n "${line}" ]]; do
      tableSize="$(echo "${line}" | awk -F ' ' '{print $2}')"
      tableName="$(echo "${line}" | awk -F ' ' '{print $1}')"
      # shellcheck disable=SC2154
      if ((tableSize < maxTableSize * optionRatio / 100)); then
        echo -n '#'
      else
        excludedTablesCount=$((excludedTablesCount + 1))
      fi
      echo "   grep -v '^${tableName}$' | # table size ${tableSize}MB"
    done < <(echo "${tableList}")
    echo "cat"
    tablesCount="$(echo "${tableList}" | wc -l)"
    Log::displayInfo "Profile generated - ${excludedTablesCount}/${tablesCount} tables bigger than ${optionRatio}% of max table size (${maxTableSize}MB) automatically excluded"
  ) >"${HOME_PROFILES_DIR}/${optionProfile}"

  Log::displayInfo "File saved in '${HOME_PROFILES_DIR}/${optionProfile}'"
}

if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "1" ]]; then
  run &>/dev/null
else
  run
fi
