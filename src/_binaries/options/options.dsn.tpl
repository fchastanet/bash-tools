%
# shellcheck source=/dev/null
source <(
  # shellcheck disable=SC2116
  Options::generateOption \
    --help "${defaultFromDsnHelp:-target mysql server}" \
    --variable-type "String" \
    --group groupSourceDbOptionsFunction \
    --alt "--from-dsn" \
    --alt "-f" \
    --variable-name "optionFromDsn" \
    --function-name optionFromDsnFunction

)
options+=(
  optionFromDsnFunction
)
%

# default values
declare optionFromDsn=""
