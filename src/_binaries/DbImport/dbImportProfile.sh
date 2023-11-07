#!/usr/bin/env bash
# BIN_FILE=${FRAMEWORK_ROOT_DIR}/bin/dbImportProfile
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE
# shellcheck disable=SC2034

# default values
declare optionProfile=""
declare fromDbName=""
declare optionFromDsn="default.remote"
declare optionRatio=70

# other configuration
declare copyrightBeginYear="2020"
declare PROFILES_DIR="${BASH_TOOLS_ROOT_DIR}/conf/dbImportProfiles"
declare HOME_PROFILES_DIR="${HOME}/.bash-tools/dbImportProfiles"

.INCLUDE "$(dynamicTemplateDir _binaries/DbImport/dbImportProfile.options.tpl)"

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

# @require Linux::requireExecutedAsUser
run() {

  # check dependencies
  Assert::commandExists mysql "sudo apt-get install -y mysql-client"
  Assert::commandExists mysqlshow "sudo apt-get install -y mysql-client"

  # create db instance
  declare -Agx dbFromInstance

  Database::newInstance dbFromInstance "${optionFromDsn}"
  Database::setQueryOptions dbFromInstance "${dbFromInstance[QUERY_OPTIONS]} --connect-timeout=5"
  Log::displayInfo "Using from dsn ${dbFromInstance['DSN_FILE']}"

  # check if from db exists
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
