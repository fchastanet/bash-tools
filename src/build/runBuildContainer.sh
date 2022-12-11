#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/runBuildContainer
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

VENDOR="${VENDOR:-ubuntu}"
BASH_TAR_VERSION="${BASH_TAR_VERSION:-5.1}"
BASH_IMAGE="${BASH_IMAGE:-ubuntu:20.04}"
DOCKER_BUILD_OPTIONS="${DOCKER_BUILD_OPTIONS:-}"

(echo >&2 "run tests using ${VENDOR}:${BASH_TAR_VERSION}")
cd "${ROOT_DIR}" || exit 1

if [[ ! -d "${ROOT_DIR}/vendor" ]]; then
  "${BIN_DIR}/installDevRequirements"
fi

if [[ "${SKIP_BUILD:-0}" = "0" ]]; then
  "${BIN_DIR}/buildPushDockerImages" "${VENDOR}" "${BASH_TAR_VERSION}" "${BASH_IMAGE}"

  # build docker image with user configuration
  # shellcheck disable=SC2086
  DOCKER_BUILDKIT=1 docker build \
    ${DOCKER_BUILD_OPTIONS} \
    --cache-from "scrasnups/build:bash-tools-${VENDOR}-${BASH_TAR_VERSION}" \
    --build-arg "BASH_IMAGE=bash-tools-${VENDOR}-${BASH_TAR_VERSION}:latest" \
    --build-arg USER_ID="$(id -u)" \
    --build-arg GROUP_ID="$(id -g)" \
    -f .docker/DockerfileUser \
    -t "bash-tools-${VENDOR}-${BASH_TAR_VERSION}-user" \
    ".docker"
fi

# run tests
args=()
if tty -s; then
  args=("-it")
fi

docker run \
  --rm \
  "${args[@]}" \
  -w /bash \
  -v "${ROOT_DIR}:/bash" \
  --user "$(id -u):$(id -g)" \
  "bash-tools-${VENDOR}-${BASH_TAR_VERSION}-user" \
  "$@"
