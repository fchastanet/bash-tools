#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/install
# ROOT_DIR_RELATIVE_TO_BIN_DIR=

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/executedAsUser.sh"

HELP="$(
  cat <<EOF
${__HELP_TITLE}Description:${__HELP_NORMAL}
Install dependent softwares (GNU parallel)
Install configuration files

${__HELP_TITLE}Usage:${__HELP_NORMAL} ${SCRIPT_NAME}

.INCLUDE "${ORIGINAL_TEMPLATE_DIR}/_includes/author.tpl"
EOF
)"
Args::defaultHelp "${HELP}" "$@"

if ! command -v parallel 2>/dev/null; then
  Log::displayInfo "We will install GNU parallel software, please enter you sudo password"
  sudo apt update || true
  if sudo apt install -y parallel; then
    # remove parallel nagware
    mkdir -p ~/.parallel
    touch ~/.parallel/will-cite
  else
    Log::displayWarning "Impossible to install GNU parallel, please install it manually"
  fi
fi

if [[ -d "${HOME}/.bash-tools" ]]; then
  # update
  cp -R --no-clobber "${ROOT_DIR}/conf/." "${HOME}/.bash-tools"
  [[ "${BASE_DIR}/conf/.env" -nt "${HOME}/.bash-tools/.env" ]] && {
    Log::displayWarning "${BASE_DIR}/conf/.env is newer than ${HOME}/.bash-tools/.env, compare the files to check if some updates need to be applied"
  }
else
  mkdir -p ~/.bash-tools
  cp -R conf/. ~/.bash-tools
fi
