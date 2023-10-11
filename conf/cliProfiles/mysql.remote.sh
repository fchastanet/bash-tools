#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2154
finalContainerArg="project-mysql8"

# shellcheck disable=SC2034
# shellcheck disable=SC2154
finalUserArg="${userArg:-mysql}"

# shellcheck disable=SC2034
# shellcheck disable=SC2154
finalCommandArg=("${commandArg[@]}")

if [[ -z "${commandArg[*]}" ]]; then
  loadDsn "default.remote"
  finalCommandArg=(//bin/bash -c "mysql -h${HOSTNAME} -u${USER} -p${PASSWORD} -P${PORT}")
fi
