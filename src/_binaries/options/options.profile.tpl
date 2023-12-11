%
# shellcheck source=/dev/null
source <(
  Options::generateGroup \
    --title "PROFILE OPTIONS:" \
    --function-name groupProfileOptionsFunction

  profileOptionHelpCallback() { :; }
  Options::generateOption \
    --variable-type String \
    --group groupProfileOptionsFunction \
    --help profileOptionHelpCallback \
    --alt "--profile" \
    --alt "-p" \
    --callback "profileOptionCallback" \
    --variable-name "optionProfile" \
    --function-name optionProfileFunction

  # shellcheck disable=SC2116
  Options::generateOption \
    --help-value-name "tablesSeparatedByComma" \
    --help "$(echo \
      "import only table specified in the list. " \
      "If aws mode, ignore profile option" \
    )" \
    --group groupProfileOptionsFunction \
    --alt "--tables" \
    --callback optionTablesCallback \
    --variable-type "String" \
    --variable-name "optionTables" \
    --function-name optionTablesFunction

)
options+=(
  optionProfileFunction
  optionTablesFunction
  --callback initProfileCommandCallback
)
%

# default values
declare optionProfile="default"
declare optionTables=""
declare profileCommandFile=""

profileOptionHelpCallback() {
  echo "the name of the profile to use in order to include or exclude tables"
  echo "(if not specified in default.sh from 'User profiles directory' if exists or 'Default profiles directory')"
}

optionTablesCallback() {
  if [[ ! ${optionTables} =~ ^[A-Za-z0-9_]+(,[A-Za-z0-9_]+)*$ ]]; then
    Log::fatal "Command ${SCRIPT_NAME} - Table list is not valid : ${optionTables}"
  fi
}

profileOptionCallback() {
  local -a profilesArray
  readarray -t profilesArray < <(Conf::getMergedList "dbImportProfiles" "sh" "" || true)
  if ! Array::contains "$2" "${profilesArray[@]}"; then
    Log::displayError "${SCRIPT_NAME} - invalid profile '$2' provided"
    return 1
  fi
}
initProfileCommandCallback() {
  if [[ "${optionProfile}" != "default" && -n "${optionTables}" ]]; then
    Log::fatal "Command ${SCRIPT_NAME} - you cannot use table and profile options at the same time"
  fi

  # Profile selection
  local profileMsgInfo
  # shellcheck disable=SC2154
  if [[ "${optionProfile}" = 'default' && -n "${optionTables}" ]]; then
    profileCommandFile=$(Framework::createTempFile "profileCmd.XXXXXXXXXXXX")
    profileMsgInfo="only ${optionTables} will be imported"
    (
      echo '#!/usr/bin/env bash'
      if [[ -n "${optionTables}" ]]; then
        echo "${optionTables}" | sed -E 's/([A-Za-z0-9_]+),?/echo "\1"\n/g'
      else
        # tables option not specified, we will import all tables of the profile
        echo 'cat'
      fi
    ) >"${profileCommandFile}"
  else
    profileCommandFile="$(Conf::getAbsoluteFile "dbImportProfiles" "${optionProfile}" "sh")" || exit 1
    profileMsgInfo="Using profile ${profileCommandFile}"
  fi
  chmod +x "${profileCommandFile}"
  Log::displayInfo "${profileMsgInfo}"
}
