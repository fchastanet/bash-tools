#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -x

BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )
VENDOR="${VENDOR:-ubuntu}"
BASH_TAR_VERSION="${BASH_TAR_VERSION:-5.1}"
BASH_IMAGE="${BASH_IMAGE:-ubuntu:20.04}"
DOCKER_BUILD_OPTIONS="${DOCKER_BUILD_OPTIONS:-}"  

(>&2 echo "run tests using ${VENDOR}:${BASH_TAR_VERSION}")
cd "${BASE_DIR}" || exit 1

if [[ ! -d "${BASE_DIR}/vendor" ]]; then
  ./.build/installBuildDeps.sh
fi

./.build/buildPushDockerImages.sh "${VENDOR}" "${BASH_TAR_VERSION}" "${BASH_IMAGE}"

# build docker image with user configuration
docker build \
  ${DOCKER_BUILD_OPTIONS} \
  --build-arg "BASH_IMAGE=bash-tools-${VENDOR}-${BASH_TAR_VERSION}" \
  --build-arg USER_ID="$(id -u)" \
  --build-arg GROUP_ID="$(id -g)" \
  -f .docker/DockerfileUser \
  -t "bash-tools-${VENDOR}-${BASH_TAR_VERSION}-user" \
  .docker

# run tests
docker run \
  --rm \
  -it \
  -w /bash \
  -v "${BASE_DIR}:/bash" \
  --user "$(id -u):$(id -g)" \
  "bash-tools-${VENDOR}-${BASH_TAR_VERSION}-user" \
  "$@"
