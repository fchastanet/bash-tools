%
declare versionNumber="1.1"
declare commandFunctionName="docCommand"
declare help="generate markdown documentation"
%

.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"
.INCLUDE "$(dynamicTemplateDir _binaries/options/options.ci.tpl)"

%
Options::generateCommand "${options[@]}"
%

<% ${commandFunctionName} %> parse "${BASH_FRAMEWORK_ARGV[@]}"
