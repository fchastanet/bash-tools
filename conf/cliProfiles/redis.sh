#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2154
finalContainerArg="project-redis"

# shellcheck disable=SC2034
# shellcheck disable=SC2154
finalUserArg="${userArg:-redis}"

# shellcheck disable=SC2034
# shellcheck disable=SC2154
finalCommandArg="${commandArg:-redis-cli}"