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

updateOptionSkipDockerBuildCallback() {
  if [[ "${IN_BASH_DOCKER:-}" != "You're in docker" ]]; then
    BASH_FRAMEWORK_ARGV_FILTERED+=("$1")
    RUN_CONTAINER_ARGV_FILTERED+=("$1")
  fi
}
# shellcheck disable=SC2317 # if function is overridden
updateArgListInfoVerboseCallback() {
  RUN_CONTAINER_ARGV_FILTERED+=(--verbose)
  BASH_FRAMEWORK_ARGV_FILTERED+=(--verbose)
}
# shellcheck disable=SC2317 # if function is overridden
updateArgListDebugVerboseCallback() {
  RUN_CONTAINER_ARGV_FILTERED+=(-vv)
  BASH_FRAMEWORK_ARGV_FILTERED+=(-vv)
}
# shellcheck disable=SC2317 # if function is overridden
updateArgListTraceVerboseCallback() {
  RUN_CONTAINER_ARGV_FILTERED+=(-vvv)
  BASH_FRAMEWORK_ARGV_FILTERED+=(-vvv)
}