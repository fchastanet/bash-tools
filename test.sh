#!/usr/bin/env bash

CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ "${IN_BASH_DOCKER:-}" != "You're in docker" ]; then
  docker build --build-arg BASH_IMAGE=amd64/bash:4.4 -t git-amd64/bash:4.4 .docker
  docker run -it --rm -v "$(pwd):/bash" --user "$(id -u):$(id -g)" git-amd64/bash:4.4 /bash/test.sh $@
  exit 0
fi
(
  cd "${CURRENT_DIR}" || exit 1
  if (( $# < 1)); then
    "${CURRENT_DIR}/vendor/bats/bin/bats" -r tests
  else
    "${CURRENT_DIR}/vendor/bats/bin/bats" "$@"
  fi
)