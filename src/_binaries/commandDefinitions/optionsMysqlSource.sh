#!/usr/bin/env bash

dsnHelpFunction() {
  echo "    target mysql server"
}

mysqlSourceLongDescription() {
  fromDsnOptionLongDescription
  echo
  echo -e "    ${__HELP_TITLE}Aws s3 location:${__HELP_NORMAL}"
  echo -e "      ${S3_BASE_URL}"
}
