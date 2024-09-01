#!/usr/bin/env bash

declare -a PARALLEL_OPTIONS

optionProgressBarCallback() {
  PARALLEL_OPTIONS+=(--bar)
}
