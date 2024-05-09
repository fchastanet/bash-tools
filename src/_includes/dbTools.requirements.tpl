checkRequirements() {
  if [[ "${SKIP_REQUIREMENTS_CHECKS:-0}" = "1" ]]; then
    return 0
  fi
  local -i failures=0
  echo
  Assert::commandExists mysql "sudo apt-get install -y mysql-client" || ((++failures))
  Assert::commandExists mysqlshow "sudo apt-get install -y mysql-client" || ((++failures))
  Assert::commandExists mysqldump "sudo apt-get install -y mysql-client" || ((++failures))
  Assert::commandExists pv "sudo apt-get install -y pv" || ((++failures))
  Assert::commandExists gawk "sudo apt-get install -y gawk" || ((++failures))
  Assert::commandExists awk "sudo apt-get install -y gawk" || ((++failures))
  Version::checkMinimal "gawk" "--version" "5.0.1" || ((++failures))
  return "${failures}"
}

optionVersionCallback() {
  echo "${SCRIPT_NAME} version <% ${versionNumber} %>"
  checkRequirements
  exit 0
}
