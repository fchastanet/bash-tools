#!/bin/bash

REAL_SCRIPT_FILE="$(readlink -e "$(realpath "${BASH_SOURCE[0]}")")"
CURRENT_DIR="${REAL_SCRIPT_FILE%/*}"

set -o errexit
set -o pipefail

declare image="$1"
shift || true

if [[ -z "${image}" || "${image}" = "" ]]; then
  echo "try : ./test.sh scrasnups/build:bash-tools-alpine-5.0 -r src -j 30"
  echo "or  : ./test.sh scrasnups/build:bash-tools-ubuntu-5.3 -r src -j 30"
  echo "display bats help : ./test.sh scrasnups/build:bash-tools-ubuntu-5.3 --help"
  echo 'run container in wait mode : docker run -d --name bash-alpine --rm -e KEEP_TEMP_FILES=0 -e BATS_FIX_TEST=0 -e USER_ID=1000 -e GROUP_ID=1000 --user www-data:www-data -w /bash -v /home/wsl/fchastanet/bash-tools:/bash -v /home/wsl/fchastanet/bash-dev-env/vendor/bash-tools-framework:/bash/vendor/bash-tools-framework --entrypoint /usr/local/bin/bash -v /tmp:/tmp scrasnups/build:bash-tools-alpine-5.0 -c "while [ true ]; do echo 1 & sleep 3; done;"'
  exit 0
fi

# build docker image
if [[ "${CI_MODE:-0}" = "1" ]] || ! docker inspect --type=image "${image}" &>/dev/null; then
  docker pull "${image}"
fi

# run docker image
declare -a localDockerRunArgs=(
  --rm
  -e KEEP_TEMP_FILES="${KEEP_TEMP_FILES:-0}"
  -e BATS_FIX_TEST="${BATS_FIX_TEST:-0}"
  -e USER_ID="${USER_ID:-1000}"
  -e GROUP_ID="${GROUP_ID:-1000}"
  --user "www-data:www-data"
  -w /bash
  -v "${CURRENT_DIR}:/bash"
  --entrypoint /usr/local/bin/bash
)

if [[ -d "${CURRENT_DIR}/vendor/bash-tools-framework" ]]; then
  FRAMEWORK_ROOT_DIR="$(cd "${CURRENT_DIR}/vendor/bash-tools-framework" && pwd -P)"
  localDockerRunArgs+=(
    -v "${FRAMEWORK_ROOT_DIR}:/bash/vendor/bash-tools-framework"
  )
fi
if [[ "${CI_MODE:-0}" = "0" ]]; then
  localDockerRunArgs+=(-v "/tmp:/tmp")
  localDockerRunArgs+=(-it)
fi

set -x
docker run \
  "${localDockerRunArgs[@]}" \
  "${image}" \
  /bash/vendor/bash-tools-framework/vendor/bats/bin/bats \
  "$@"
