#!/usr/bin/env bash

CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# load bash-framework
# shellcheck source=bash-framework/_bootstrap.sh
source "$( cd "${CURRENT_DIR}/.." && pwd )/bash-framework/_bootstrap.sh"

Framework::expectNonRootUser

import bash-framework/Database
import bash-framework/Version
import bash-framework/File

# ensure that Ctrl-C is trapped by this script and not sub mysql process
trap 'exit 130' INT

# default values
SCRIPT_NAME=${0##*/}
PROFILE="default"
TABLES=""
DOWNLOAD_DUMP=0
FROM_AWS=0
SKIP_SCHEMA=0
REMOTE_DB=""
TARGET_DB=""
COLLATION_NAME=""
CHARACTER_SET=""
FROM_DSN=""
DEFAULT_FROM_DSN="default.remote"
TARGET_DSN="default.local"
TIMEFORMAT='time spent : %3R'
# remove last slash
DB_IMPORT_DUMP_DIR=${DB_IMPORT_DUMP_DIR%/}
PROFILES_DIR="$(cd "${CURRENT_DIR}/.." && pwd)/conf/dbImportProfiles"
HOME_PROFILES_DIR="${HOME}/.bash-tools/dbImportProfiles"

showHelp() {
local profilesList=""
local dsnList=""
dsnList="$(Functions::getConfMergedList "dsn" "env")"
profilesList="$(Functions::getConfMergedList "dbImportProfiles" "sh" || true)"

cat << EOF
${__HELP_TITLE}Description:${__HELP_NORMAL} Import source db into target db

${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} --help prints this help and exits
${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} <fromDbName> [<targetDbName>]
${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} -a|--from-aws <fromDbS3Filename> [<targetDbName>]
                        [-a|--from-aws]
                        [-s|--skip-schema] [-p|--profile profileName]
                        [-o|--collation-name utf8_general_ci] [-c|--character-set utf8]
                        [-t|--target-dsn dsn] [-f|--from-dsn dsn]
                        [--tables tableName1,tableName2]

    <fromDbS3Filename>         If option -a is provided
        remoteDBName will represent the name of the s3 file
        Only .gz or tar.gz file are supported
    <fromDbName>               the name of the source/remote database
    <targetDbName>             the name of the target database, use fromDbName(without extension) if not provided
    -s|--skip-schema            avoid to import the schema
    -o|--collation-name         change the collation name used during database creation
        (default value: collation name used by remote db)
    -c|--character-set          change the character set used during database creation
        (default value: character set used by remote db or dump file if aws)
    -p|--profile profileName    the name of the profile to use in order to include or exclude tables
        (if not specified ${HOME_PROFILES_DIR}/default.sh is used if exists otherwise ${PROFILES_DIR}/default.sh)
    -t|--target-dsn dsn         dsn to use for target database (Default: ${TARGET_DSN})
    -f|--from-dsn dsn           dsn to use for source database (Default: ${DEFAULT_FROM_DSN})
        this option is incompatible with -a|--from-aws option
    -a|--from-aws               db dump will be downloaded from s3 instead of using remote db,
        remoteDBName will represent the name of the file
        profile will be calculated against the dump itself
        this option is incompatible with -f|--from-dsn option
    --tables table1,table2      import only table specified in the list
        if aws mode, ignore profile option

    Aws s3 location       : ${S3_BASE_URL}

${__HELP_TITLE}List of available profiles (default profiles dir ${PROFILES_DIR} can be overriden in home profiles ${HOME_PROFILES_DIR}):${__HELP_NORMAL}
${profilesList}
${__HELP_TITLE}List of available dsn:${__HELP_NORMAL}
${dsnList}
EOF
}

# read command parameters
# $@ is all command line parameters passed to the script.
# -o is for short options like -h
# -l is for long options with double dash like --help
# the comma separates different long options
options=$(getopt -l help,tables:,target-dsn:,from-dsn:,from-aws,skip-schema,profile:,collation-name:,character-set: -o aht:f:sp:c:o: -- "$@" 2> /dev/null) || {
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
-a|--from-aws)
    FROM_AWS="1"
    # structure is included in s3 file
    SKIP_SCHEMA="1"
    ;;
--tables)
    shift || true
    TABLES="$1"
    ;;
-t|--target-dsn)
    shift || true
    TARGET_DSN="$1"
    ;;
-f|--from-dsn)
    shift || true
    FROM_DSN="${1:-${DEFAULT_FROM_DSN}}"
    ;;
-s|--skip-schema)
    SKIP_SCHEMA="1"
    ;;
-p|--profile)
    shift || true
    PROFILE="$1"
    ;;
-o|--collation-name)
    shift || true
    COLLATION_NAME="$1"
    ;;
-c|--character-set)
    shift || true
    CHARACTER_SET="$1"
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

# check dependencies
Functions::checkCommandExists mysql "sudo apt-get install -y mysql-client"
Functions::checkCommandExists mysqlshow "sudo apt-get install -y mysql-client"
Functions::checkCommandExists mysqldump "sudo apt-get install -y mysql-client"
Functions::checkCommandExists pv "sudo apt-get install -y pv"
Functions::checkCommandExists gawk "sudo apt-get install -y gawk"
Functions::checkCommandExists awk "sudo apt-get install -y gawk"
Version::checkMinimal "gawk" "gawk --version" "5.0.1"

# additional arguments
shift $(( OPTIND - 1 )) || true
while true; do
    if [[ -z "$1" ]]; then
        # last argument
        break
    fi
    if [[ -z "${REMOTE_DB}" ]]; then
        REMOTE_DB="$1"
    else
        TARGET_DB="$1"
    fi
    shift || true
done

if [[ -z "${REMOTE_DB}" ]]; then
    showHelp
    Log::fatal "you must provide remoteDbName"
fi

if [[ -z "${TARGET_DB}" ]]; then
    # remove eventual file extension
    TARGET_DB="${REMOTE_DB%%.*}"
fi

# check s3 parameter
[[ "${FROM_AWS}" = "1" ]] &&
    Functions::checkCommandExists aws "missing aws, please check https://docs.aws.amazon.com/fr_fr/cli/latest/userguide/install-cliv2.html"
[[ "${FROM_AWS}" = "1" && -n "${FROM_DSN}" ]] &&
    Log::fatal "you cannot use from-dsn and from-aws at the same time"
[[ "${FROM_AWS}" = "1" && -z "${S3_BASE_URL}" ]] &&
    Log::fatal "missing S3_BASE_URL, please provide a value in .env file"

# default value for FROM_DSN if from-aws not set
if [[ "${FROM_AWS}" = "0" && -z "${FROM_DSN}" ]]; then
    FROM_DSN="${DEFAULT_FROM_DSN}"
fi

# load the profile
if [[ -z "${PROFILE}" ]]; then
    showHelp
    Log::fatal "you should specify a profile"
fi

[[ "${PROFILE}" != "default" && -n "${TABLES}" ]] &&
    Log::fatal "you cannot use table and profile options at the same time"

# Profile selection
PROFILE_COMMAND="$(Functions::getAbsoluteConfFile "dbImportProfiles" "${PROFILE}" "sh")" || exit 1
PROFILE_MSG_INFO="Using profile ${PROFILE_COMMAND}"
if [[ -n "${TABLES}" ]]; then
    [[ ${TABLES} =~ ^[A-Za-z0-9_]+(,[A-Za-z0-9_]+)*$ ]] || {
        Log::fatal "Table list is not valid : ${TABLES}"
    }
fi

if [[ "${PROFILE}" = 'default' && -n "${TABLES}" ]]; then
    PROFILE_COMMAND=$(mktemp -p "${TMPDIR:-/tmp}" -t "profileCmd.XXXXXXXXXXXX")
    chmod +x "${PROFILE_COMMAND}"
    Functions::trapAdd "rm -f \"${PROFILE_COMMAND}\" 2>/dev/null || true" ERR EXIT
    PROFILE_MSG_INFO="only ${TABLES} will be imported"
    (
        echo '#!/usr/bin/env bash'
        if [[ -n "${TABLES}" ]]; then
            echo "${TABLES}" | sed -E 's/([A-Za-z0-9_]+),?/echo "\1"\n/g'
        else
            # tables option not specified, we will import all tables of the profile
            echo 'cat'
        fi
    ) > "${PROFILE_COMMAND}"
fi
Log::displayInfo "${PROFILE_MSG_INFO}"

[[ -z "${DB_IMPORT_DUMP_DIR}" ]] &&
    Log::fatal "you have to specify a value for DB_IMPORT_DUMP_DIR env variable"

if [[ ! -d "${DB_IMPORT_DUMP_DIR}" ]]; then
    mkdir -p "${DB_IMPORT_DUMP_DIR}" ||
        Log::fatal "impossible to create directory ${DB_IMPORT_DUMP_DIR} specified by DB_IMPORT_DUMP_DIR env variable"
fi

# create db instances
declare -Agx dbFromInstance dbTargetDatabase

Database::newInstance dbTargetDatabase "${TARGET_DSN}"
Database::setQueryOptions dbTargetDatabase "${dbTargetDatabase[QUERY_OPTIONS]} --connect-timeout=5"
Log::displayInfo "Using target dsn ${dbTargetDatabase['DSN_FILE']}"
if [[ "${FROM_AWS}" = "0" ]]; then
    Database::newInstance dbFromInstance "${FROM_DSN}"
    Database::setQueryOptions dbFromInstance "${dbFromInstance[QUERY_OPTIONS]} --connect-timeout=5"
    Log::displayInfo "Using from dsn ${dbFromInstance['DSN_FILE']}"
fi

if [[ "${FROM_AWS}" = "1" ]]; then
    REMOTE_DB_DUMP_TEMP_FILE="${DB_IMPORT_DUMP_DIR}/${REMOTE_DB}"
else
    REMOTE_DB_DUMP_TEMP_FILE="${DB_IMPORT_DUMP_DIR}/${REMOTE_DB}_${PROFILE}.sql.gz"
    REMOTE_DB_STRUCTURE_DUMP_TEMP_FILE="${DB_IMPORT_DUMP_DIR}/${REMOTE_DB}_${PROFILE}_structure.sql.gz"
fi

# check if local dump exists
if [[ ! -f "${REMOTE_DB_DUMP_TEMP_FILE}" ]]; then
    Log::displayInfo "local dump does not exist"
    DOWNLOAD_DUMP=1
fi
if [[ "${FROM_AWS}" = "0" && ! -f "${REMOTE_DB_STRUCTURE_DUMP_TEMP_FILE}" ]]; then
    Log::displayInfo "local structure dump does not exist"
    DOWNLOAD_DUMP=1
fi
if [[ "${DOWNLOAD_DUMP}" = "0" ]]; then
    Log::displayInfo "local dump ${REMOTE_DB_DUMP_TEMP_FILE} already exists, avoid download"
fi

# dump header/footer
read -r -d '\0' DUMP_HEADER <<- EOM
    SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS = 0;
    SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, AUTOCOMMIT = 0;
    SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS = 0;\0
EOM

read -r -d '\0' DUMP_FOOTER <<- EOM2
    COMMIT;
    SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
    SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
    SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;\0
EOM2

Log::displayInfo "tables list will calculated using profile ${PROFILE} => ${PROFILE_COMMAND}"
chmod +x "${PROFILE_COMMAND}"
SECONDS=0
if [[ "${DOWNLOAD_DUMP}" = "1" ]]; then
    Log::displayInfo "Download dump"

    if [[ "${FROM_AWS}" = "1" ]]; then
        # download dump from s3
        S3_URL="${S3_BASE_URL%/}/${REMOTE_DB}"
        aws s3 ls --human-readable "${S3_URL}" || {
            Log::fatal "unable to get information on S3 object : ${S3_URL}"
        }
        Log::displayInfo "Download dump from ${S3_URL} ...";
        TMPDIR="${TEMP_FOLDER:-/tmp}" aws s3 cp "${S3_URL}" "${REMOTE_DB_DUMP_TEMP_FILE}" || {
            Log::fatal "unable to download dump from S3 : ${S3_URL}"
        }
    else
        # check if remote db exists
        Database::ifDbExists dbFromInstance "${REMOTE_DB}" || {
            Log::fatal "Remote Database ${REMOTE_DB} does not exist"
        }

        # get remote db collation name
        if [[ -z "${COLLATION_NAME}" ]]; then
            COLLATION_NAME=$(Database::query dbFromInstance \
                "SELECT default_collation_name FROM information_schema.SCHEMATA WHERE schema_name = \"${REMOTE_DB}\";" "information_schema")
        fi

        # get remote db character set
        if [[ -z "${CHARACTER_SET}" ]]; then
            CHARACTER_SET=$(Database::query dbFromInstance \
                "SELECT default_character_set_name FROM information_schema.SCHEMATA WHERE schema_name = \"${REMOTE_DB}\";" "information_schema")
        fi

        DUMP_HEADER=$(printf "%s\nSET names '%s';\n" "${DUMP_HEADER}" "${CHARACTER_SET}")

        # calculate remote db dump size
        LIST_TABLES="$(Database::query dbFromInstance "show tables" "${REMOTE_DB}" | ${PROFILE_COMMAND} | sort)"
        LIST_TABLES_DUMP_SIZE="$(echo "${LIST_TABLES}" | awk -v d="," -v q="'" '{s=(NR==1?s:s d)q $0 q}END{print s }')"
        LIST_TABLES_DUMP=$(echo "${LIST_TABLES}" | awk -v d=" " -v q="" '{s=(NR==1?s:s d)q $0 q}END{print s }')
        Log::displayInfo "Calculate dump size for tables ${LIST_TABLES_DUMP}"
        DUMP_SIZE_QUERY="SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 0) AS size FROM information_schema.TABLES WHERE table_schema=\"${REMOTE_DB}\""
        DUMP_SIZE_QUERY+=" AND table_name IN(${LIST_TABLES_DUMP_SIZE}, 'dummy') "
        DUMP_SIZE_QUERY+=" GROUP BY table_schema"
        REMOTE_DB_DUMP_SIZE=$(echo "${DUMP_SIZE_QUERY}" | Database::query dbFromInstance )
        if [[ -z "${REMOTE_DB_DUMP_SIZE}" ]]; then
            # could occur with the none profile
            REMOTE_DB_DUMP_SIZE="0"
        fi

        # dump db
        Log::displayInfo "Dump the database $REMOTE_DB (Size:${REMOTE_DB_DUMP_SIZE}MB) ...";
        DUMP_SIZE_PV_ESTIMATION=$(awk "BEGIN {printf \"%.0f\",${REMOTE_DB_DUMP_SIZE}/1.5}")
        time (
            echo "${DUMP_HEADER}"
            Database::dump dbFromInstance "${REMOTE_DB}" "${LIST_TABLES_DUMP}" \
                --no-create-info --skip-add-drop-table --single-transaction=TRUE | \
                pv --progress --size "${DUMP_SIZE_PV_ESTIMATION}m"
            echo "${DUMP_FOOTER}"
        ) | gzip > "${REMOTE_DB_DUMP_TEMP_FILE}"

        Log::displayInfo "Dump structure of the database ${REMOTE_DB} ..."
        time (
            echo "${DUMP_HEADER}"
            #shellcheck disable=SC2016
            Database::dump dbFromInstance "${REMOTE_DB}" "" \
                --no-data --skip-add-drop-table --single-transaction=TRUE | \
                sed 's/^CREATE TABLE `/CREATE TABLE IF NOT EXISTS `/g'
            echo "${DUMP_FOOTER}"
        ) | gzip > "${REMOTE_DB_STRUCTURE_DUMP_TEMP_FILE}"
    fi
    Log::displayInfo "Dump done.";
fi

# mark dumps as modified now to avoid them to be garbage collected
touch -c -m "${REMOTE_DB_DUMP_TEMP_FILE}" || true
touch -c -m "${REMOTE_DB_STRUCTURE_DUMP_TEMP_FILE}" || true

# TODO Collation and character set should be retrieved from dump files if possible
COLLATION_NAME="${COLLATION_NAME:-utf8_general_ci}"
CHARACTER_SET="${CHARACTER_SET:-utf8}"

Log::displayInfo "create target database ${TARGET_DB} if needed";
#shellcheck disable=SC2016
Database::query dbTargetDatabase \
   "$(printf 'CREATE DATABASE IF NOT EXISTS `%s` CHARACTER SET "%s" COLLATE "%s"' "${TARGET_DB}" "${CHARACTER_SET}" "${COLLATION_NAME}")"

if [[ "${FROM_AWS}" = "1" ]]; then
    "${CURRENT_DIR}/dbImportStream" \
        "${REMOTE_DB_DUMP_TEMP_FILE}" \
        "${TARGET_DB}" \
        "${PROFILE_COMMAND}" \
        "${dbTargetDatabase['AUTH_FILE']}" \
        "${CHARACTER_SET}" \
        "${dbTargetDatabase['DB_IMPORT_OPTIONS']}"
else
    Database::setQueryOptions dbTargetDatabase "${dbTargetDatabase['DB_IMPORT_OPTIONS']}"
    Log::displayInfo "Importing remote db '${REMOTE_DB}' to local db '${TARGET_DB}'"
    if [[ "${SKIP_SCHEMA}" = "1" ]]; then
        Log::displayInfo "avoid to create db structure";
    else
        Log::displayInfo "create db structure from ${REMOTE_DB_STRUCTURE_DUMP_TEMP_FILE}";
        time ( \
            pv "${REMOTE_DB_STRUCTURE_DUMP_TEMP_FILE}" | zcat | \
                Database::query dbTargetDatabase "" "${TARGET_DB}"
        )
    fi

    Log::displayInfo "import remote to local from file ${REMOTE_DB_DUMP_TEMP_FILE}"
    time ( \
        "${CURRENT_DIR}/dbImportStream" \
            "${REMOTE_DB_DUMP_TEMP_FILE}" \
            "${TARGET_DB}" \
            "${PROFILE_COMMAND}" \
            "${dbTargetDatabase['AUTH_FILE']}" \
            "${CHARACTER_SET}" \
            "${dbTargetDatabase['DB_IMPORT_OPTIONS']}"
    )
fi

# garbage collect db import dumps
File::garbageCollect "${DB_IMPORT_DUMP_DIR}" "${DB_IMPORT_GARBAGE_COLLECT_DAYS:-+30}" || true

Log::displayInfo "Import database duration : $(date -u -d @${SECONDS} +"%T")"
