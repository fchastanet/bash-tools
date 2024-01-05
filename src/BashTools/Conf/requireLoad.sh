#!/bin/bash

bashToolsDefaultConfigTemplate="${bashToolsDefaultConfigTemplate:-$(
  cat <<'EOF'
.INCLUDE "${BASH_TOOLS_ROOT_DIR}/conf/.env"
EOF
)}"

# @description loads ~/.bash-tools/.env if available
# if not creates it from a default template
# else check if new options need to be added
BashTools::Conf::requireLoad() {
  local envFile="${HOME}/.bash-tools/.env"
  if [[ ! -f "${envFile}" ]]; then
    mkdir -p "${HOME}/.bash-tools"
    (
      echo "#!/usr/bin/env bash"
      echo "${bashToolsDefaultConfigTemplate}"
    ) >"${envFile}"
    Log::displayInfo "Configuration file '${envFile}' created"
  else
    if ! grep -q '^POSTMAN_API_KEY=' "${envFile}"; then
      (
        echo '# -----------------------------------------------------'
        echo '# Postman Parameters'
        echo '# -----------------------------------------------------'
        echo 'POSTMAN_API_KEY='
      ) >>"${envFile}"
    fi
  fi
  # shellcheck source=/conf/.env
  source "${envFile}" || {
    Log::displayError "impossible to load '${envFile}'"
    exit 1
  }
}
