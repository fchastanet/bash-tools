#!/usr/bin/env bash

profileOptionLongDescription() {
  local profilesList=""
  profilesList="$(Conf::getMergedList "dbImportProfiles" "sh" "      - " || true)"

  echo -e "  ${__HELP_TITLE}Profiles${__HELP_NORMAL}"
  echo -e "    ${__HELP_TITLE}Default profiles directory:${__HELP_NORMAL}"
  echo -e "      ${PROFILES_DIR-configuration error}"
  echo
  echo -e "    ${__HELP_TITLE}User profiles directory:${__HELP_NORMAL}"
  echo -e "      ${HOME_PROFILES_DIR-configuration error}"
  echo -e '      Allows to override profiles defined in "Default profiles directory"'
  echo
  echo -e "    ${__HELP_TITLE}List of available profiles:${__HELP_NORMAL}"
  echo -e "${profilesList}"
}

profileOptionHelpFunction() {
  echo "    The name of the profile to use in order to"
  echo "    include or exclude tables."
}

initOptionProfileIfNotSet() {
  if [[ -z "${optionProfile}" ]]; then
    optionProfile="${defaultOptionProfile}"
  fi
  local -a profilesArray
  readarray -t profilesArray < <(Conf::getMergedList "dbImportProfiles" "sh" "" || true)
  if ! Array::contains "${optionProfile}" "${profilesArray[@]}"; then
    Log::displayError "${SCRIPT_NAME} - invalid profile '${optionProfile}' provided"
    return 1
  fi
}

declare defaultOptionProfile="default"
initProfileCommandCallback() {
  initOptionProfileIfNotSet

  # shellcheck disable=SC2154
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
