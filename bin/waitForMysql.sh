#!/usr/bin/env bash

declare mysqlHost="$1"
declare mysqlPort="$2"
declare mysqlUser="$3"
declare mysqlPass="$4"

echo "Waiting for mysql"
until (echo "select 1" | mysql -h"${mysqlHost}" -P"${mysqlPort}" -u"${mysqlUser}" -p"${mysqlPass}" &> /dev/null)
do
  printf "."
  sleep 1
done

echo -e "\nmysql ready"