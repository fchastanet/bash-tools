%
declare versionNumber="1.0"
declare commandFunctionName="gitRenameBranchCommand"
declare help="rename git local branch, push new branch and delete old branch"
declare longDescription='''
${__HELP_TITLE}EXIT CODES:${__HELP_NORMAL}
${__HELP_OPTION_COLOR}1${__HELP_NORMAL} : if current directory is not a git repository
    or if invalid or missing arguments
${__HELP_OPTION_COLOR}2${__HELP_NORMAL} : if impossible to compute current branch name
${__HELP_OPTION_COLOR}3${__HELP_NORMAL} : master/main branch not supported by this command,
    please do it manually
${__HELP_OPTION_COLOR}5${__HELP_NORMAL} : New and old branch names are the same
${__HELP_OPTION_COLOR}6${__HELP_NORMAL} : You can use this tool in non interactive mode only
    if --assume-yes option is provided
${__HELP_OPTION_COLOR}7${__HELP_NORMAL} : if failed to rename local branch
${__HELP_OPTION_COLOR}8${__HELP_NORMAL} : if remote branch deletion failed
${__HELP_OPTION_COLOR}9${__HELP_NORMAL} : if failed to push the new branch'''
%

.INCLUDE "$(dynamicTemplateDir _binaries/options/options.base.tpl)"

%
# shellcheck source=/dev/null
source <(
  Options::generateArg \
    --help "the branch name to check" \
    --min 1 \
    --max 1 \
    --name "newBranchName" \
    --variable-name "newBranchNameArg" \
    --function-name newBranchNameArgFunction

  Options::generateArg \
    --help "the name of the old branch if not current one" \
    --min 0 \
    --max 1 \
    --name "oldBranchName" \
    --variable-name "oldBranchNameArg" \
    --function-name oldBranchNameArgFunction

  assumeYesHelpCallback() { :; }
  # shellcheck disable=SC2116
  Options::generateOption \
    --help assumeYesHelpCallback \
    --alt "--assume-yes" \
    --alt "--yes" \
    --alt "-y" \
    --variable-name "optionAssumeYes" \
    --function-name optionAssumeYesFunction

  Options::generateOption \
    --help "push the new branch" \
    --alt "--push" \
    --alt "-p" \
    --variable-name "optionPush" \
    --function-name optionPushFunction

  Options::generateOption \
    --help "delete the old remote branch" \
    --alt "--delete" \
    --alt "-d" \
    --variable-name "optionDelete" \
    --function-name optionDeleteFunction
)
options+=(
  newBranchNameArgFunction
  oldBranchNameArgFunction
  optionAssumeYesFunction
  optionPushFunction
  optionDeleteFunction
  --callback commandCallback
)
Options::generateCommand "${options[@]}"
%
declare copyrightBeginYear="2020"

#default values
declare optionPush="0"
declare optionDelete="0"
declare optionAssumeYes="0"
declare newBranchNameArg=""
declare oldBranchNameArg=""

assumeYesHelpCallback() {
  echo "do not ask for confirmation (use with caution)" $'\n'
  echo '  Automatic yes to prompts; assume "y" as answer to all prompts' $'\n'
  echo '  and run non-interactively.'
}

commandCallback() {
  if ! Assert::tty && [[ "${optionAssumeYes}" != "1" ]]; then
    Log::displayError "You can use this tool in non interactive mode only if --assume-yes option is provided"
    exit 6
  fi
}
