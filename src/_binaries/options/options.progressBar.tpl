%

# shellcheck source=/dev/null
source <(
  optionProgressBarCallback() { :; }
    # shellcheck disable=SC2116
  Options::generateOption \
    --help "Show progress as a progress bar. In the bar is shown: % of jobs completed, estimated seconds left, and number of jobs started." \
    --variable-type "Boolean" \
    --alt "--bar" \
    --alt "-b" \
    --callback optionProgressBarCallback \
    --variable-name "optionProgressBar" \
    --function-name optionProgressBarFunction

)
options+=(
  optionProgressBarFunction
)
%

declare -a PARALLEL_OPTIONS

optionProgressBarCallback() {
  PARALLEL_OPTIONS+=(--bar)
}
