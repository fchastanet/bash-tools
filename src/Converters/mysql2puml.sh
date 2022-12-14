#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/mysql2puml
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

#default values
SCRIPT_VERSION="0.1"
SKIN="default"

# Usage info
showHelp() {
  local skinList=""
  skinList="$(Profiles::getConfMergedList "mysql2pumlSkins" ".puml")"

  cat <<EOF
${__HELP_TITLE}Description:${__HELP_NORMAL} convert mysql dump sql schema to plantuml format

${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} [-h|--help] prints this help and exits
${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} [-v|--version] prints the version and exits
${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} [-s|--skin skin] inputSqlFile

  --help,-h      : prints this help and exits
  --version,-v   : display version and exit
  --skin,-s skin : (optional) header configuration of the plant uml file (default: default)
  inputSqlFile   : sql filepath to parse

${__HELP_TITLE}Examples${__HELP_NORMAL}
mysql2puml dump.dql

mysqldump --skip-add-drop-table --skip-add-locks --skip-disable-keys --skip-set-charset --user=root --password=root --no-data skills | mysql2puml

${__HELP_TITLE}List of available skins:${__HELP_NORMAL}
${skinList}

EOF
}

showVersion() {
  echo "$(basename "$0") Version: ${SCRIPT_VERSION}"
}

# read command parameters
# $@ is all command line parameters passed to the script.
# -o is for short options like -h
# -l is for long options with double dash like --help
# the comma separates different long options
options=$(getopt -l help,version,skin: -o hvs: -- "$@" 2>/dev/null) || {
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
    --version | -v)
      showVersion
      exit 0
      ;;
    --skin | -s)
      shift
      SKIN="$1"
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
shift $((OPTIND - 1)) || true

sqlFile="${1:-}"
shift || true
if (($# > 0)); then
  showHelp
  Log::fatal "too much arguments provided"
fi

absSkinFile="$(Profiles::getAbsoluteConfFile "mysql2pumlSkins" "${SKIN}" "puml")" ||
  Log::fatal "the skin ${SKIN} does not exist"

if [[ -n "${sqlFile}" ]]; then
  if [[ ! -f "${sqlFile}" ]]; then
    Log::fatal "file ${sqlFile} does not exist"
  fi
  exec 3<"${sqlFile}"
elif [[ ! -t 0 ]]; then
  exec 3<&0
else
  Log::fatal "No sql file provided..."
fi

awkScript="$(
  cat <<'EOF'
.INCLUDE "$(cd "$(dirname ${SRC_FILE_PATH})" && pwd -P)/mysql2puml.awk"
EOF
)"
awk --source "${awkScript}" "${absSkinFile}" - <&3
