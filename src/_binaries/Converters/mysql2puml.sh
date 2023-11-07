#!/usr/bin/env bash
# BIN_FILE=${FRAMEWORK_ROOT_DIR}/bin/mysql2puml
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE
# shellcheck disable=SC2034

declare copyrightBeginYear="2020"
declare optionBashFrameworkConfig="${BASH_TOOLS_ROOT_DIR}/.framework-config"
declare optionSkin="default"

.INCLUDE "$(dynamicTemplateDir _binaries/Converters/mysql2puml.options.tpl)"
declare awkScript
awkScript="$(
  cat <<'EOF'
.INCLUDE "$(dynamicSrcFile _binaries/Converters/mysql2puml.awk)"
EOF
)"

run() {
  absSkinFile="$(Conf::getAbsoluteFile "mysql2pumlSkins" "${optionSkin}" "puml")" ||
    Log::fatal "the skin ${optionSkin} does not exist"

  if [[ -n "${inputSqlFile}" ]]; then
    exec 3<"${inputSqlFile}"
  elif [[ ! -t 0 ]]; then
    exec 3<&0
  fi

  awk --source "${awkScript}" "${absSkinFile}" - <&3 | Filters::trimEmptyLines
}

if [[ "${BASH_FRAMEWORK_QUIET_MODE:-0}" = "1" ]]; then
  run &>/dev/null
else
  run
fi
