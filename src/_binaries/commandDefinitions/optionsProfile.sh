#!/usr/bin/env bash

profileOptionHelpFunction() {
  Array::wrap2 " " 80 4 \
    "    The name of the profile to use in order to include or exclude tables."
  echo
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

profileOptionCallback() {
  local -a profilesArray
  readarray -t profilesArray < <(Conf::getMergedList "dbImportProfiles" "sh" "" || true)
  if ! Array::contains "$2" "${profilesArray[@]}"; then
    Log::displayError "${SCRIPT_NAME} - invalid profile '$2' provided"
    return 1
  fi
}

optionTablesCallback() {
  if [[ ! ${optionTables} =~ ^[A-Za-z0-9_]+(,[A-Za-z0-9_]+)*$ ]]; then
    Log::fatal "Command ${SCRIPT_NAME} - Table list is not valid : ${optionTables}"
  fi
}
