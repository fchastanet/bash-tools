#!/usr/bin/env bash
# @embed "${BASH_TOOLS_ROOT_DIR}/src/_binaries/Converters/mysql2puml/mysql2puml.awk" AS mysql2pumlScript

Linux::requireRealpathCommand

# shellcheck disable=SC2154
absSkinFile="$(Conf::getAbsoluteFile "mysql2pumlSkins" "${optionSkin}" "puml")" ||
  Log::fatal "the skin ${optionSkin} does not exist"

if [[ -n "${inputSqlFile}" ]]; then
  exec 3<"${inputSqlFile}"
elif [[ ! -t 0 ]]; then
  exec 3<&0
fi

# shellcheck disable=SC2154
awk -f "${embed_file_mysql2pumlScript}" "${absSkinFile}" - <&3 | Filters::trimEmptyLines
