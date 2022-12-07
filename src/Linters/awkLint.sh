#!/usr/bin/env bash
# BIN_FILE=${ROOT_DIR}/bin/awkLint
# ROOT_DIR_RELATIVE_TO_BIN_DIR=..

.INCLUDE "${TEMPLATE_DIR}/_includes/_header.tpl"

awkLintScript="$(
  cat <<'EOF'
.INCLUDE "${CURRENT_DIR}/awkLint.awk"
EOF
)"

FROM_DIR="${1:-${ROOT_DIR}}"

(
  cd "${FROM_DIR}" || exit 1
  # <?xml version='1.0' encoding='UTF-8'?>
  # <checkstyle version='4.3'>
  # <file name='./tests/bash&#45;framework/ManualTest.sh' >
  # <error line='9' column='8' severity='warning' message='Can&#39;t follow non&#45;constant source. Use a directive to specify location.' source='ShellCheck.SC1090' />
  # <error line='17' column='5' severity='warning' message='Use &#39;cd ... &#124;&#124; exit&#39; or &#39;cd ... &#124;&#124; return&#39; in case cd fails.' source='ShellCheck.SC2164' />
  # <error line='27' column='5' severity='warning' message='Use &#39;cd ... &#124;&#124; exit&#39; or &#39;cd ... &#124;&#124; return&#39; in case cd fails.' source='ShellCheck.SC2164' />
  # </file>
  # </checkstyle>
  echo "<?xml version='1.0' encoding='UTF-8'?>"
  echo "<checkstyle>"
  find . -type f -name '*.awk' -not -path './.history/*' | while IFS='' read -r file; do
    echo "<file name='${file}'>"
    awk --source "BEGIN { exit(0) } END { exit(0) }" --lint=no-ext -f "${file}" 2>&1 </dev/null |
      awk --source "${awkLintScript}" -
    echo "</file>"
  done
  echo "</checkstyle>"
)
