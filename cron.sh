#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ENV_FILE="${DIR}/.env"

if [ -f "${ENV_FILE}" ]; then
  set -a
  source "${ENV_FILE}"
  set +a
  echo -e "\n\e[32m${ENV_FILE} file was read\e[0m\n"
fi
cd "${DIR}"
truffle exec scripts/mock-asset-management.js --network docker
echo -e "END"