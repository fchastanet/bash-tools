#!/usr/bin/env bash

CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
DEBUG_ARGS=()
DOCKER_DEBUG_ARGS=()
set -x
if [ "${DEBUG:-0}" = "1" ]; then
  DEBUG_ARGS=(--no-tempdir-cleanup)
  mkdir -p tmp
  DOCKER_DEBUG_ARGS=(-v "$(pwd)/tmp:/tmp")
fi
if [ "${IN_BASH_DOCKER:-}" = "You're in docker" ]; then
  (
    cd "${CURRENT_DIR}" || exit 1
    if (( $# < 1)); then
      "${CURRENT_DIR}/vendor/bats/bin/bats" -r tests
    else
      "${CURRENT_DIR}/vendor/bats/bin/bats" "$@"
    fi
  )
else
  if [[ ! -d "${CURRENT_DIR}/vendor" ]]; then
    ./.build/installBuildDeps.sh
  fi
  docker build \
    --build-arg "BASH_IMAGE=scrasnups/build:bash-tools-ubuntu-5.1" \
    --build-arg USER_ID="$(id -u)" \
    --build-arg GROUP_ID="$(id -g)" \
    -f .docker/DockerfileUser \
    -t bash-tools-ubuntu:5.1 \
    .docker
  docker run --rm \
    -it \
    -v "$(pwd):/bash" \
    "${DOCKER_DEBUG_ARGS[@]}" \
    --user "$(id -u):$(id -g)" \
    bash-tools-ubuntu:5.1 /bash/test.sh "${DEBUG_ARGS[@]}" "$@"
fi