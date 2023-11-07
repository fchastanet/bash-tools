%
declare defaultTargetCollationName="utf8_general_ci"

# shellcheck source=/dev/null
source <(

    # shellcheck disable=SC2116
  Options::generateOption \
    --help "$(echo \
      "change the collation name used during database creation" \
      "(default value: ${defaultTargetCollationName})" \
    )" \
    --variable-type "String" \
    --group groupTargetOptionsFunction \
    --alt "--collation-name" \
    --alt "-o" \
      --variable-name "optionCollationName" \
    --function-name optionCollationNameFunction

  )
  options+=(
    optionCollationNameFunction
  )
%

declare optionCollationName=""
declare defaultTargetCollationName="<% ${defaultTargetCollationName} %>"
