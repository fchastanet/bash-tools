%
declare versionNumber="1.0"
declare commandFunctionName="installCommand"
declare help="Install dependent softwares and configuration needed to use bash-tools
- GNU parallel
- Install default configuration files"
%

.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"

%
Options::generateCommand "${options[@]}"
%
