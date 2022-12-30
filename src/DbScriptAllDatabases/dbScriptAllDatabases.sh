#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/dbScriptAllDatabases
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

Assert::expectNonRootUser

#default values
SCRIPT_NAME=${0##*/}
JOBS_NUMBER=1
MYSQL_OPTIONS=""
OUTPUT_DIR="${HOME}/.bash-tools/output"
DSN="default.local"
LOG_FORMAT="none"
DB_NAME=""
VERBOSE=0

# Usage info
showHelp() {
  local dsnList scriptsList
  dsnList="$(Profiles::getConfMergedList "dsn" "env")"
  scriptsList="$(Profiles::getConfMergedList "dbScripts" "sh")"

  cat <<EOF
${__HELP_TITLE}Description:${__HELP_NORMAL} Allows to execute a script on each database of specified mysql server

${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} [-h|--help] prints this help and exits
${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} [-j|--jobs <numberOfJobs>] [-o|--output <outputDirectory>] [-d|--dsn <dsn>] [-v|--verbose] [-l|--log-format <logFormat>] [--database <dbName>] <scriptToExecute> [optional parameters to pass to the script]
    <scriptToExecute>             the script that will be executed on each databases
    -d|--dsn <dsn>                target mysql server (Default: ${DSN})
    --database <dbName>           if provided will check only this db, otherwise script will be executed on all dbs of mysql server
    -j|--jobs <numberOfJobs>      the number of db to query in parallel (default: ${JOBS_NUMBER})
    -o|--output <outputDirectory> output directory, see log-format option (default : "${OUTPUT_DIR}")
    -l|--log-format <logFormat>   if log provided, will log each db result to log file, can be one of these values (none, log) (default: none)
    -v|--verbose                  display more information

${__HELP_TITLE}Note:${__HELP_NORMAL} the use of output, log-format, verbose options highly depends on the script used

${__HELP_TITLE}Example:${__HELP_NORMAL} script conf/dbScripts/extractData.sh
    executes query databaseSize (see conf/dbQueries/databaseSize.sql) on each db and log the result in log file in default output dir, call it using
    $0 -j 10 extractData databaseSize

    executes query databaseSize on each db and display the result on stdout (2>/dev/null hides information messages)
    $0 -j 10 --log-format none extractData databaseSize

    use --verbose to get some debug information
    $0 -j 10 --log-format none --verbose extractData databaseSize

${__HELP_TITLE}Use cases:${__HELP_NORMAL}
    you can use this script in order to check that each db model conforms with your ORM schema
    simply create a new script in conf/dbQueries that will call your orm schema checker

    update multiple db at once (simple to complex update script)

${__HELP_TITLE}List of available dsn:${__HELP_NORMAL}
${dsnList}
${__HELP_TITLE}list of available scripts (${SCRIPTS_FOLDER}):${__HELP_NORMAL}
${scriptsList}

.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/author.tpl"
EOF
}

# read command parameters
# $@ is all command line parameters passed to the script.
# -o is for short options like -h
# -l is for long options with double dash like --help
# the comma separates different long options
options=$(getopt -l help,log-format:,dsn:,jobs:,database:,output:,verbose -o hd:j:l:o:v -- "$@" 2>/dev/null) || {
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
    --output | -o)
      shift || true
      OUTPUT_DIR="$1"
      ;;
    --verbose | -v)
      VERBOSE=1
      ;;
    --dsn | -d)
      shift || true
      DSN=${1:-:-default.local}
      ;;
    --database)
      shift || true
      DB_NAME="$1"
      ;;
    --log-format | -l)
      shift || true
      LOG_FORMAT="$1"
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

# check dependencies
Assert::commandExists mysql "sudo apt-get install -y mysql-client"
Assert::commandExists mysqlshow "sudo apt-get install -y mysql-client"
Assert::commandExists parallel "sudo apt-get install -y parallel"

# output-dir argument
if ! Array::contains "${LOG_FORMAT}" "none" "log"; then
  Log::fatal "log format '${LOG_FORMAT}' not supported"
fi

# additional arguments
shift $((OPTIND - 1)) || true
SCRIPT="$1"
shift || true
if [[ -z "${SCRIPT}" ]]; then
  Log::fatal "You must provide the script file to be executed"
fi

if [[ "${OUTPUT_DIR:0:1}" != "/" ]]; then
  # relative path
  OUTPUT_DIR="${PWD}/${OUTPUT_DIR}"
fi
mkdir -p "${OUTPUT_DIR}" || Log::fatal "unable to create directory ${OUTPUT_DIR}"
[[ -d "${OUTPUT_DIR}" && -w "${OUTPUT_DIR}" ]] ||
  Log::fatal "output dir is not correct or not writable"

if ! [[ ${JOBS_NUMBER} =~ ^[0-9]+$ ]]; then
  Log::fatal "number of jobs is incorrect"
fi
[[ ${JOBS_NUMBER} -lt 1 ]] && Log::fatal "number of jobs must be greater than 0"

# try script inside script folder
SCRIPT="$(Profiles::getAbsoluteConfFile "dbScripts" "${SCRIPT}" "sh")" || exit 1
[[ "${VERBOSE}" = "1" ]] && Log::displayInfo "Using script ${SCRIPT}"
# create db instance
declare -Agx dbInstance

Database::newInstance dbInstance "${DSN}"
Database::setQueryOptions dbInstance "${dbInstance['QUERY_OPTIONS']} --connect-timeout=5"
[[ "${VERBOSE}" = "1" ]] && Log::displayInfo "Using dsn ${dbInstance['DSN_FILE']}"

# list of all databases
[[ "${VERBOSE}" = "1" ]] && Log::displayInfo "get the list of all databases"
if [[ -z "${DB_NAME}" ]]; then
  allDbs="$(Database::getUserDbList dbInstance)"
else
  allDbs="${DB_NAME}"
fi

[[ "${VERBOSE}" = "1" ]] && Log::displayInfo "processing $(echo "${allDbs}" | wc -l) databases using ${JOBS_NUMBER} jobs"

export selectedQueryFile
export MYSQL_OPTIONS

echo "${allDbs}" | parallel --eta --progress --tag --jobs="${JOBS_NUMBER}" \
  "${SCRIPT}" "${DSN}" "${LOG_FORMAT}" "${VERBOSE}" \
  "${OUTPUT_DIR}" "${PWD}" "$@"
