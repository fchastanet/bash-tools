%
declare defaultTargetDsn="default.local"
declare defaultTargetCharacterSet="utf8"

# shellcheck source=/dev/null
source <(
  Options::generateGroup \
    --title "TARGET OPTIONS:" \
    --function-name groupTargetOptionsFunction


  Options::generateOption \
    --help "dsn to use for target database (Default: ${defaultTargetDsn})" \
    --help-value-name "targetDsn" \
    --variable-type "String" \
    --group groupTargetOptionsFunction \
    --alt "--target-dsn" \
    --alt "-t" \
    --variable-name "optionTargetDsn" \
    --function-name optionTargetDsnFunction

  # shellcheck disable=SC2116
  Options::generateOption \
    --help "$(echo \
      "change the character set used during database creation" \
      "(default value: ${defaultTargetCharacterSet})" \
    )" \
    --variable-type "String" \
    --group groupTargetOptionsFunction \
    --alt "--character-set" \
    --alt "-c" \
    --variable-name "optionCharacterSet" \
    --function-name optionCharacterSetFunction
)
options+=(
  optionTargetDsnFunction
  optionCharacterSetFunction
)
%

declare optionTargetDsn="<% ${defaultTargetDsn} %>" # old TARGET_DSN
declare optionCharacterSet="" # old CHARACTER_SET
declare defaultTargetCharacterSet="<% ${defaultTargetCharacterSet} %>"


initializeDefaultTargetMysqlOptions() {
  local -n dbFromInstanceTargetMysql=$1
  local fromDbName="$2"

  # get remote db collation name
  if [[ -n ${optionCollationName+x} && -z "${optionCollationName}" ]]; then
    optionCollationName=$(Database::query dbFromInstanceTargetMysql \
      "SELECT default_collation_name FROM information_schema.SCHEMATA WHERE schema_name = \"${fromDbName}\";" "information_schema")
  fi

  # get remote db character set
  if [[ -z "${optionCharacterSet}" ]]; then
    optionCharacterSet=$(Database::query dbFromInstanceTargetMysql \
      "SELECT default_character_set_name FROM information_schema.SCHEMATA WHERE schema_name = \"${fromDbName}\";" "information_schema")
  fi
}
