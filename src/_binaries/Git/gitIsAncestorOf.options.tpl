%
declare versionNumber="1.0"
declare commandFunctionName="gitIsAncestorOfCommand"
declare help="check if commit is inside a given branch"
declare longDescription='''
${__HELP_TITLE}EXIT CODES:${__HELP_NORMAL}
${__HELP_OPTION_COLOR}1${__HELP_NORMAL}: if commit does not exists
${__HELP_OPTION_COLOR}2${__HELP_NORMAL}: if commit is not included in given branch
'''
%

.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"

%
# shellcheck source=/dev/null
source <(
 containerArgHelpCallback() { :; }
  Options::generateArg \
    --help "the branch in which the commit will be searched" \
    --min 1 \
    --max 1 \
    --name "claimedBranch" \
    --variable-name "claimedBranchArg" \
    --function-name claimedBranchArgFunction

  userArgHelpCallback() { :; }
  Options::generateArg \
    --help "the commit oid to check" \
    --min 1 \
    --max 1 \
    --name "commit" \
    --variable-name "commitArg" \
    --function-name commitArgFunction
)
options+=(
  claimedBranchArgFunction
  commitArgFunction
)
Options::generateCommand "${options[@]}"
%
declare copyrightBeginYear="2020"
declare claimedBranchArg=""
declare commitArg=""
