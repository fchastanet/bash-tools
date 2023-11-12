%
declare -a externalBinaries=(
  bin/runBuildContainer
  bin/test
)
declare versionNumber="1.0"
declare commandFunctionName="installRequirementsCommand"
declare help="installs requirements"
declare longDescription="""
${__HELP_TITLE}INSTALLS REQUIREMENTS:${__HELP_NORMAL}
- fchastanet/bash-tools-framework
- and fchastanet/bash-tools-framework useful binaries:
  $(Array::join ', ' "${externalBinaries[@]}")
"""
%

.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"

%
Options::generateCommand "${options[@]}"
declare -p externalBinaries
%

<% ${commandFunctionName} %> parse "${BASH_FRAMEWORK_ARGV[@]}"
