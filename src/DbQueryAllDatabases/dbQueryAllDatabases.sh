#!/usr/bin/env bash

CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# load bash-framework
# shellcheck source=bash-framework/_bootstrap.sh
source "$( cd "${CURRENT_DIR}/.." && pwd )/bash-framework/_bootstrap.sh"

Framework::expectNonRootUser

import bash-framework/Database
import bash-framework/Functions
import bash-framework/Version

# ensure that Ctrl-C is trapped by this script and not sub mysql process
trap 'exit 130' INT

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
dsnList="$(Functions::getConfMergedList "dsn" "env")"
queriesList="$(Functions::getConfMergedList "dbQueries" "sql" || true)"

cat << EOF
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
${__HELP_TITLE}List of available queries (default dir ${QUERIES_DIR} can be overriden in home dir ${HOME_QUERIES_DIR}):${__HELP_NORMAL}
${queriesList}
EOF
}

# read command parameters
# $@ is all command line parameters passed to the script.
# -o is for short options like -h
# -l is for long options with double dash like --help
# the comma separates different long options
options=$(getopt -l help,query,bar,jobs:,dsn: -o hqbj:d: -- "$@" 2> /dev/null) || {
    showHelp
    Log::fatal "invalid options specified"
}

eval set -- "${options}"
while true
do
case $1 in
-h|--help)
    showHelp
    exit 0
    ;;
--jobs|-j)
    shift || true
    JOBS_NUMBER=$1
    ;;
--bar|-b)
    PARALLEL_OPTIONS+=("--bar")
    ;;
--query|-q)
    QUERY=1
    ;;
--dsn|-d)
    shift || true
    DSN=${1:-:-default.local}
    ;;
--)
    shift || true
    break;;
*)
    showHelp
    Log::fatal "invalid argument $1"
esac
shift || true
done

# additional arguments
shift $(( OPTIND - 1 )) || true

# check dependencies
Functions::checkCommandExists mysql "sudo apt-get install -y mysql-client"
Functions::checkCommandExists mysqlshow "sudo apt-get install -y mysql-client"
Functions::checkCommandExists parallel "sudo apt-get install -y parallel"
Functions::checkCommandExists gawk "sudo apt-get install -y gawk"
Functions::checkCommandExists awk "sudo apt-get install -y gawk"
Version::checkMinimal "gawk" "gawk --version" "5.0.1"

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
    queryAbsoluteFile="$(Functions::getAbsoluteConfFile "dbQueries" "${queryFile}" "sql")" ||
        Log::fatal "the file ${queryFile} does not exist"
    query="$(cat "${queryAbsoluteFile}")"
    Log::displayInfo "Using query file ${queryAbsoluteFile}"
fi

if ! [[ ${JOBS_NUMBER} =~ ^[0-9]+$ ]] ; then
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
echo "${allDbs}" |
    parallel --eta --progress "${PARALLEL_OPTIONS[@]}" \
        "${CURRENT_DIR}/_dbQueryOneDatabase.sh" "${DSN}" \
        | awk -f "${CURRENT_DIR}/dbQueryAllDatabases.awk" -
