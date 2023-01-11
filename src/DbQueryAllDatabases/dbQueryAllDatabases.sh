#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/dbQueryAllDatabases
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

Assert::expectNonRootUser

#default values
SCRIPT_NAME=${0##*/}
JOBS_NUMBER=1
QUERY=0
DSN="default.local"
QUERIES_DIR="$(cd "${CURRENT_DIR}/.." && pwd)/conf/dbQueries"
HOME_QUERIES_DIR="${HOME}/.bash-tools/dbQueries"

declare -a PARALLEL_OPTIONS

# Usage info
showHelp() {
  local dsnList queriesList
  dsnList="$(Conf::getMergedList "dsn" "env")"
  queriesList="$(Conf::getMergedList "dbQueries" "sql" || true)"

  cat <<EOF
${__HELP_TITLE}Description:${__HELP_NORMAL} Execute a query on multiple databases in order to generate a report with tsv format, query can be parallelized on multiple databases

${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} [-h|--help] prints this help and exits
${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} <query|queryFile> [-d|--dsn <dsn>] [-q|--query] [--jobs|-j <jobsCount>] [--bar|-b]

    -q|--query            implies <query> parameter is a mysql query string
    -d|--dsn <dsn>        to use for target mysql server (Default: ${DSN})
    -j|--jobs <jobsCount> specify the number of db to query in parallel (this needs the use of gnu parallel)
    -b|--bar              Show progress as a progress bar. In the bar is shown: % of jobs completed, estimated seconds left, and number of jobs started.
    <query|queryFile>
        if -q option is provided this parameter is a mysql query string
        else a file must be specified

${__HELP_TITLE}List of available dsn:${__HELP_NORMAL}
${dsnList}
${__HELP_TITLE}List of available queries (default dir ${QUERIES_DIR} can be overridden in home dir ${HOME_QUERIES_DIR}):${__HELP_NORMAL}
${queriesList}

.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/author.tpl"
EOF
}

# read command parameters
# $@ is all command line parameters passed to the script.
# -o is for short options like -h
# -l is for long options with double dash like --help
# the comma separates different long options
options=$(getopt -l help,query,bar,jobs:,dsn: -o hqbj:d: -- "$@" 2>/dev/null) || {
  showHelp
  Log::fatal "invalid options specified"
}

eval set -- "${options}"
while true; do
  case $1 in
    -h | --help)
      showHelp
      exit 0
      ;;
    --jobs | -j)
      shift || true
      JOBS_NUMBER=$1
      ;;
    --bar | -b)
      PARALLEL_OPTIONS+=("--bar")
      ;;
    --query | -q)
      QUERY=1
      ;;
    --dsn | -d)
      shift || true
      DSN=${1:-:-default.local}
      ;;
    --)
      shift || true
      break
      ;;
    *)
      showHelp
      Log::fatal "invalid argument $1"
      ;;
  esac
  shift || true
done

# additional arguments
shift $((OPTIND - 1)) || true

# check dependencies
Assert::commandExists mysql "sudo apt-get install -y mysql-client"
Assert::commandExists mysqlshow "sudo apt-get install -y mysql-client"
Assert::commandExists parallel "sudo apt-get install -y parallel"
Assert::commandExists gawk "sudo apt-get install -y gawk"
Assert::commandExists awk "sudo apt-get install -y gawk"
Version::checkMinimal "gawk" "--version" "5.0.1"

# if -q option provided (QUERY =1), queryFile is supposed to be a file,
# else it is a query string by default
queryFile=$1
if [[ -z "${queryFile}" ]]; then
  if [[ "${QUERY}" = "0" ]]; then
    Log::fatal "You must provide the sql file to be executed"
  else
    Log::fatal "You must provide the sql string to be executed"
  fi
fi

# query contains the sql from queryFile or from query string if -q option is provided
declare query="${queryFile}"
if [[ "${QUERY}" = "0" ]]; then
  declare queryAbsoluteFile
  queryAbsoluteFile="$(Conf::getAbsoluteFile "dbQueries" "${queryFile}" "sql")" ||
    Log::fatal "the file ${queryFile} does not exist"
  query="$(cat "${queryAbsoluteFile}")"
  Log::displayInfo "Using query file ${queryAbsoluteFile}"
fi

if ! [[ ${JOBS_NUMBER} =~ ^[0-9]+$ ]]; then
  Log::fatal "number of jobs is incorrect"
fi

[[ ${JOBS_NUMBER} -lt 1 ]] && Log::fatal "number of jobs must be greater than 0"

declare -Agx dbInstance
Database::newInstance dbInstance "${DSN}"
Database::setQueryOptions dbInstance "${dbInstance['QUERY_OPTIONS']} --connect-timeout=5"
Log::displayInfo "Using dsn ${dbInstance['DSN_FILE']}"
# list of all databases
allDbs="$(Database::getUserDbList dbInstance)"
PARALLEL_OPTIONS+=("--linebuffer" "-j" "${JOBS_NUMBER}")

export query
awkScript="$(
  cat <<'EOF'
.INCLUDE "${TEMPLATE_DIR}/DbQueryAllDatabases/dbQueryAllDatabases.awk"
EOF
)"

echo "${allDbs}" |
  parallel --eta --progress "${PARALLEL_OPTIONS[@]}" \
    "${CURRENT_DIR}/dbQueryOneDatabase" "${DSN}" |
  awk --source "${awkScript}" -
