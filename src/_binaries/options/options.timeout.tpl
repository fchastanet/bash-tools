%
declare defaultTimeout="15"
# shellcheck source=/dev/null
source <(
  optionTimeoutCallback() { :; }
  Options::generateOption \
    --help-value-name "timeout" \
    --help "Timeout in seconds, zero for no timeout." \
    --default-value "${defaultTimeout}" \
    --alt "--timeout" \
    --alt "-t" \
    --variable-type "String" \
    --variable-name "optionTimeout" \
    --function-name optionTimeoutFunction \
    --callback optionTimeoutCallback
)
options+=(
  optionTimeoutFunction
)
%

optionTimeoutCallback() {
  if [[ ! "${optionTimeout}" =~ ^[0-9]+$ ]]; then
    Log::fatal "${SCRIPT_NAME} - invalid timeout option - must be greater or equal to 0"
  fi
}
