#!/usr/bin/env bash

CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
DEBUG_ARGS=""
DOCKER_DEBUG_ARGS=()
set -x
if [ "${DEBUG:-0}" = "1" ]; then
  DEBUG_ARGS=(--no-tempdir-cleanup)
  mkdir -p tmp
  DOCKER_DEBUG_ARGS=(-v "$(pwd)/tmp:/tmp")
fi
if [ "${IN_BASH_DOCKER:-}" != "You're in docker" ]; then
  docker build \
    --build-arg "BASH_IMAGE=ubuntu:20.04" \
    --build-arg BASH_TAR_VERSION="5.1" \
    -f .docker/Dockerfile.ubuntu \
    -t git-ubuntu:5.1 \
    .docker
  docker run --rm \
    -v "$(pwd):/bash" \
    "${DOCKER_DEBUG_ARGS[@]}" \
    --user "$(id -u):$(id -g)" \
    git-ubuntu:5.1 /bash/test.sh ${DEBUG_ARGS[@]} "$@"
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