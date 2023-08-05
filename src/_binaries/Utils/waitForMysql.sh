#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/waitForMysql
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "$(dynamicTemplateDir _header.tpl)"

HELP="$(
  cat <<EOF
${__HELP_TITLE}Description:${__HELP_NORMAL} wait for mysql to be ready

${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME} <host> <port> <user> <pass>

.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/author.tpl"
EOF
)"
Args::defaultHelp "${HELP}" "$@"

declare mysqlHost="$1"
declare mysqlPort="$2"
declare mysqlUser="$3"
declare mysqlPass="$4"

(echo >&2 "Waiting for mysql")
until (echo "select 1" | mysql -h"${mysqlHost}" -P"${mysqlPort}" -u"${mysqlUser}" -p"${mysqlPass}" &>/dev/null); do
  (printf >&2 ".")
  sleep 1
done

(echo >&2 -e "\nmysql ready")
