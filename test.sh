#!/usr/bin/env bash

set -x

if [ "${IN_BASH_DOCKER:-}" = "You're in docker" ]; then
  (
    if (( $# < 1)); then
      "./vendor/bats/bin/bats" -r tests
    else
      "./vendor/bats/bin/bats" "$@"
    fi
  )
else
  ./.build/runTests.sh "$@"
fi

# use this in order to debug inside the container
# docker build -t bash-tools-ubuntu:5.1 -f .docker/Dockerfile.ubuntu
# docker run --rm -it -v "$(pwd):/bash"  --user "$(id -u):$(id -g)"  bash-tools-ubuntu-5.1-user bash
# docker run --rm -it -v "$(pwd):/bash"  --user "$(id -u):$(id -g)"  bash-tools-alpine-5.1-user bash
#
# to force image rebuilding
# DOCKER_BUILD_OPTIONS=--no-cache ./test.sh 
#
# rebuild alpine image
# DOCKER_BUILD_OPTIONS=--no-cache VENDOR=alpine ./test.sh 