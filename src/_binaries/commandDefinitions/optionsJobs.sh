#!/usr/bin/env bash

declare -a PARALLEL_OPTIONS

optionProgressBarCallback() {
  PARALLEL_OPTIONS+=(--bar)
}

optionJobsCallback() {
  # shellcheck disable=SC2154
  if ! [[ "${optionJobs}" =~ ^[0-9]+$ ]]; then
    Log::fatal "number of jobs is incorrect"
  fi

  if [[ ${optionJobs} -lt 1 ]]; then
    Log::fatal "number of jobs must be greater than 0"
  fi
}
