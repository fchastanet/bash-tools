%
declare versionNumber="1.0"
declare commandFunctionName="gitIsBranchCommand"
declare help="show an error if branchName is not a known branch"
%

.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"

%
# shellcheck source=/dev/null
source <(
 containerArgHelpCallback() { :; }
  Options::generateArg \
    --help "the branch name to check" \
    --min 1 \
    --max 1 \
    --name "branchName" \
    --variable-name "branchNameArg" \
    --function-name branchNameArgFunction

)
options+=(
  branchNameArgFunction
)
Options::generateCommand "${options[@]}"
%
declare copyrightBeginYear="2020"
declare branchNameArg=""
