#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/waitForMysql
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

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
