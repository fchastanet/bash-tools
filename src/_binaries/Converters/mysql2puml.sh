#!/usr/bin/env bash
# BIN_FILE=${FRAMEWORK_ROOT_DIR}/bin/mysql2puml
# VAR_RELATIVE_FRAMEWORK_DIR_TO_CURRENT_DIR=..
# FACADE

.INCLUDE "$(dynamicTemplateDir _binaries/Converters/mysql2puml.options.tpl)"

mysql2pumlCommand parse "${BASH_FRAMEWORK_ARGV[@]}"

declare awkScript
awkScript="$(
  cat <<'EOF'
.INCLUDE "$(dynamicSrcFile _binaries/Converters/mysql2puml.awk)"
EOF
)"

run() {
  # shellcheck disable=SC2154
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
