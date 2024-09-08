#!/usr/bin/env bash

fromDsnOptionLongDescription() {
  local dsnList=""
  dsnList="$(Conf::getMergedList "dsn" "env" "      - ")"

  echo -e "  ${__HELP_TITLE}Data Source Name (DSN)${__HELP_NORMAL}"
  echo -e "    ${__HELP_TITLE}Default dsn directory:${__HELP_NORMAL}"
  echo -e "      ${BASH_TOOLS_ROOT_DIR}/conf/dsn"
  echo
  echo -e "    ${__HELP_TITLE}User dsn directory:${__HELP_NORMAL}"
  echo -e "      ${HOME}/.bash-tools/dsn"
  echo -e '      Allows to override dsn defined in "Default dsn directory"'
  echo
  echo -e "    ${__HELP_TITLE}List of available dsn:${__HELP_NORMAL}"
  echo -e "${dsnList}"
}
