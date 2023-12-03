%
declare versionNumber="1.0"
declare commandFunctionName="docCommand"
declare help="generate markdown documentation"
%

.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.skipDockerBuild.tpl)"

%
Options::generateCommand "${options[@]}"
%

<% ${commandFunctionName} %> parse "${BASH_FRAMEWORK_ARGV[@]}"
