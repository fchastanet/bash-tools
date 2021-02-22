#!/usr/bin/env bash
set -x
set -o errexit
set -o pipefail

BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )
VENDOR="$1"
BASH_TAR_VERSION="$2"
BASH_BASE_IMAGE="$3"

if [[ -z "${DOCKER_PASSWORD}" || -z "${DOCKER_USERNAME}" ]]; then
  (>&2 echo "please export DOCKER_PASSWORD and DOCKER_USERNAME before using this script")
  exit 1
fi

if [[ -z "${VENDOR}" || -z "${BASH_TAR_VERSION}" || -z "${BASH_BASE_IMAGE}" ]]; then
  (>&2 echo "please provide these parameters VENDOR, BASH_TAR_VERSION, BASH_BASE_IMAGE")
  exit 1
fi

# build image and push it ot registry
docker pull "scrasnups/build:bash-tools-${VENDOR}-${BASH_TAR_VERSION}" || true 
docker build \
  -f "${BASE_DIR}/.docker/Dockerfile.${VENDOR}" \
  --pull \
  --cache-from "scrasnups/build:bash-tools-${VENDOR}-${BASH_TAR_VERSION}" \
  --build-arg BASH_TAR_VERSION="${BASH_TAR_VERSION}" \
  --build-arg BASH_IMAGE="${BASH_BASE_IMAGE}"  \
  -t "bash-tools-${VENDOR}-${BASH_TAR_VERSION}" \
  -t "scrasnups/build:bash-tools-${VENDOR}-${BASH_TAR_VERSION}" \
  .docker
docker run "bash-tools-${VENDOR}-${BASH_TAR_VERSION}" bash --version

echo "${DOCKER_PASSWORD}" | docker login --username "$DOCKER_USERNAME" --password-stdin
docker push "scrasnups/build:bash-tools-${VENDOR}-${BASH_TAR_VERSION}"