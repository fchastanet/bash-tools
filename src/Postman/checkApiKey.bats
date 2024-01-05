#!/usr/bin/env bash

# shellcheck source=src/batsHeaders.sh
source "$(cd "${BATS_TEST_DIRNAME}/.." && pwd)/batsHeaders.sh"
# shellcheck source=src/Postman/checkApiKey.sh
source "${rootDir}/src/Postman/checkApiKey.sh"

function Postman::checkApiKey::fileNotFound { #@test
  run Postman::checkApiKey "fileNotFound" 2>&1
  assert_output "WARN    - Please update POSTMAN_API_KEY in 'fileNotFound'"
  assert_success
}

function Postman::checkApiKey::keyNotFound { #@test
  run Postman::checkApiKey \
    "${BATS_TEST_DIRNAME}/testsData/.env.keyNotFound" 2>&1
  assert_output "WARN    - Please update POSTMAN_API_KEY in '${BATS_TEST_DIRNAME}/testsData/.env.keyNotFound'"
  assert_success
}

function Postman::checkApiKey::keyEmpty { #@test
  run Postman::checkApiKey \
    "${BATS_TEST_DIRNAME}/testsData/.env.keyEmpty" 2>&1
  assert_output "WARN    - Please update POSTMAN_API_KEY in '${BATS_TEST_DIRNAME}/testsData/.env.keyEmpty'"
  assert_success
}

function Postman::checkApiKey::keyFound { #@test
  run Postman::checkApiKey \
    "${BATS_TEST_DIRNAME}/testsData/.env.keyFound" 2>&1
  assert_output ""
  assert_success
}
