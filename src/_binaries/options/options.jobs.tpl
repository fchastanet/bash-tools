%

# shellcheck source=/dev/null
source <(
  optionJobsCallback() { :; }
    # shellcheck disable=SC2116
  Options::generateOption \
    --help "specify the number of db to query in parallel" \
    --help-value-name "jobsCount" \
    --variable-type "String" \
    --default-value "1" \
    --alt "--jobs" \
    --alt "-j" \
    --callback optionJobsCallback \
    --variable-name "optionJobs" \
    --function-name optionJobsFunction

)
options+=(
  optionJobsFunction
)
%

optionJobsCallback() {
  if ! [[ ${optionJobs} =~ ^[0-9]+$ ]]; then
    Log::fatal "number of jobs is incorrect"
  fi

  if [[ ${optionJobs} -lt 1 ]]; then
    Log::fatal "number of jobs must be greater than 0"
  fi
}
