#!/usr/bin/env bash

set -o errexit
set -o pipefail

BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )
VENDOR="$1"
BASH_TAR_VERSION="$2"

if [[ -z "${VENDOR}" || -z "${BASH_TAR_VERSION}" ]]; then
  (>&2 echo "please provide these paramters VENDOR, BASH_TAR_VERSION")
  exit 1
fi

(
  cd "${BASE_DIR}"
  # build docker image with user configuration
  docker build \
    --build-arg "BASH_IMAGE=scrasnups/build:bash-tools-${VENDOR}-${BASH_TAR_VERSION}" \
    --build-arg USER_ID="$(id -u)" \
    --build-arg GROUP_ID="$(id -g)" \
    -f .docker/DockerfileUser \
    -t "bash-tools-${VENDOR}-${BASH_TAR_VERSION}-user" \
    .docker
  
  # run tests
  docker run \
    --rm -it -v "${BASE_DIR}:/bash" \
    --user "$(id -u):$(id -g)" \
    --workdir /bash \
    "bash-tools-${VENDOR}-${BASH_TAR_VERSION}-user" \
    /bash/vendor/bats/bin/bats -r tests
)
status=$?
exit ${status}