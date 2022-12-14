#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/test
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

# use this in order to debug inside the container
# docker build -t bash-tools-ubuntu:5.1 -f .docker/Dockerfile.ubuntu
# docker run --rm -it -v "$(pwd):/bash"  --user "$(id -u):$(id -g)"  bash-tools-ubuntu-5.1-user bash
# docker run --rm -it -v "$(pwd):/bash"  --user "$(id -u):$(id -g)"  bash-tools-alpine-5.1-user bash
#
# to force image rebuilding
# DOCKER_BUILD_OPTIONS=--no-cache ./bin/test
#
# rebuild alpine image
# DOCKER_BUILD_OPTIONS=--no-cache VENDOR=alpine BASH_IMAGE=bash:5.1 BASH_TAR_VERSION=5.1 ./bin/test

if [[ "${IN_BASH_DOCKER:-}" = "You're in docker" ]]; then
  (
    if (($# < 1)); then
      "${VENDOR_DIR}/bats/bin/bats" -r tests
    else
      "${VENDOR_DIR}/bats/bin/bats" "$@"
    fi
  )
else
  "${BIN_DIR}/runBuildContainer" "/bash/bin/test" "$@"
fi
