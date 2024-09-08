#!/usr/bin/env bash

# other configuration
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

declare tableList
tableList="$(Database::query dbFromInstance "${QUERY//@DB@/${fromDbName}}" "information_schema")"

# first table is the biggest one
declare maxTableSize
maxTableSize="$(echo "${tableList}" | head -1 | awk -F ' ' '{print $2}')"

# shellcheck disable=SC2154
(
  echo "#!/usr/bin/env bash"
  echo
  echo "# cat represents the whole list of tables"
  echo "cat |"
  declare -i excludedTablesCount
  ((excludedTablesCount = 0)) || true
  declare tableSize
  declare tableName
  while IFS="" read -r line || [[ -n "${line}" ]]; do
    tableSize="$(echo "${line}" | awk -F ' ' '{print $2}')"
    tableName="$(echo "${line}" | awk -F ' ' '{print $1}')"
    if ((tableSize < maxTableSize * optionRatio / 100)); then
      echo -n '  #'
    else
      excludedTablesCount=$((excludedTablesCount + 1))
    fi
    echo "  grep -v '^${tableName}$' | # table size ${tableSize}MB"
  done < <(echo "${tableList}")
  echo "  cat"
  tablesCount="$(echo "${tableList}" | wc -l)"
  Log::displayInfo "Profile generated - ${excludedTablesCount}/${tablesCount} tables bigger than ${optionRatio}% of max table size (${maxTableSize}MB) automatically excluded"
) >"${HOME_PROFILES_DIR}/${optionProfile}.sh"

Log::displayInfo "File saved in '${HOME_PROFILES_DIR}/${optionProfile}.sh'"
