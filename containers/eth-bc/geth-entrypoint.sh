#!/bin/sh

set -e

FIRST_ARG="${1}"

ETH_BC_DATA_WORK_DIR="${ETH_BC_DATA_DIR}/geth"

assert_required_variable() {
  CHVAR_VALUE="${1}"
  CHVAR_NAME="${2}"
  if [ -z "${CHVAR_VALUE}" ]; then
    echo "ERROR: Environment variable ${CHVAR_NAME} is required."
    exit 1
  fi
}

if [ "${FIRST_ARG}" = "run-geth" ]; then
  echo "RUN geth cmd passed"

  assert_required_variable "${ETH_BC_CORS}" "ETH_BC_CORS"
  assert_required_variable "${ETH_BC_HOST_ADDRESS}" "ETH_BC_HOST_ADDRESS"
  assert_required_variable "${ETH_BC_MINER_ADDRESS}" "ETH_BC_MINER_ADDRESS"
  assert_required_variable "${ETH_BC_NETWORK_PORT}" "ETH_BC_NETWORK_PORT"
  assert_required_variable "${ETH_BC_DATA_DIR}" "ETH_BC_DATA_DIR"
  assert_required_variable "${ETH_BC_GENESIS_BLOCK_FILE}" "ETH_BC_GENESIS_BLOCK_FILE"
  assert_required_variable "${ETH_BC_CONFIG_FILE}" "ETH_BC_CONFIG_FILE"
  assert_required_variable "${ETH_BC_MINER_KEY_PASSWORD_FILE}" "ETH_BC_MINER_KEY_PASSWORD_FILE"
  assert_required_variable "${ETH_BC_MINER_KEY_FILE}" "ETH_BC_MINER_KEY_FILE"
  assert_required_variable "${ETH_BC_MINER_THREADS}" "ETH_BC_MINER_THREADS"
  assert_required_variable "${ETH_BC_NETWORK_ID}" "ETH_BC_NETWORK_ID"
  assert_required_variable "${ETH_BC_BLOCK_PERIOD}" "ETH_BC_BLOCK_PERIOD"
  assert_required_variable "${ETH_BC_BLOCK_GAS_LIMIT}" "ETH_BC_BLOCK_GAS_LIMIT"
  assert_required_variable "${ETH_BC_NODE_MODE}" "ETH_BC_NODE_MODE"
  assert_required_variable "${ETH_BC_NODE_NAME}" "ETH_BC_NODE_NAME"
  assert_required_variable "${ETH_BC_HTTP_API}" "ETH_BC_HTTP_API"
  assert_required_variable "${ETH_BC_WS_API}" "ETH_BC_WS_API"
  assert_required_variable "${ETH_BC_VERBOSITY}" "ETH_BC_VERBOSITY"
  assert_required_variable "${ETH_BC_VMODULE_VERBOSITY}" "ETH_BC_VMODULE_VERBOSITY"
  assert_required_variable "${ETH_BC_INIT_GENESIS_BLOCK}" "ETH_BC_INIT_GENESIS_BLOCK"

  ETH_BC_INIT_ACCOUNT="${ETH_BC_INIT_ACCOUNT:-false}"

  if [ ! -d "${ETH_BC_DATA_WORK_DIR}" ]; then
    ETH_BC_INIT_GENESIS_BLOCK="true"
    ETH_BC_INIT_ACCOUNT="true"
  fi

  if [ $ETH_BC_INIT_GENESIS_BLOCK = "true" ]; then
    echo "Initialize geth configuration..."
    geth init --datadir "${ETH_BC_DATA_DIR}" "${ETH_BC_GENESIS_BLOCK_FILE}"
  else
    echo "Configuration already initialized."
  fi

  if [ $ETH_BC_INIT_ACCOUNT = "true" ]; then
    echo "Import miner account..."
    geth account import --datadir "${ETH_BC_DATA_DIR}" --password "${ETH_BC_MINER_KEY_PASSWORD_FILE}" "${ETH_BC_MINER_KEY_FILE}"
  else
    echo "Miner account already imported."
  fi

  echo "========================== ENVS"
  printenv
  echo "========================== END ENVS"

  echo "Start geth..."
  exec geth --datadir "${ETH_BC_DATA_DIR}" --config "${ETH_BC_CONFIG_FILE}" \
    --http --http.corsdomain "${ETH_BC_CORS}" --http.addr "${ETH_BC_HOST_ADDRESS}" --http.vhosts "${ETH_BC_CORS}" \
    --http.api "${ETH_BC_HTTP_API}" \
    --ws --ws.origins "${ETH_BC_CORS}" --ws.addr "${ETH_BC_HOST_ADDRESS}" --ws.api "${ETH_BC_WS_API}" \
    --graphql --graphql.corsdomain "${ETH_BC_CORS}" --graphql.vhosts "${ETH_BC_CORS}" \
    --mine --miner.threads "${ETH_BC_MINER_THREADS}" --miner.etherbase "${ETH_BC_MINER_ADDRESS}" \
    --port "${ETH_BC_NETWORK_PORT}" --nodiscover \
    --password "${ETH_BC_MINER_KEY_PASSWORD_FILE}" --unlock "${ETH_BC_MINER_ADDRESS}" \
    --gcmode "${ETH_BC_NODE_MODE}" \
    --allow-insecure-unlock \
    --dev --dev.period "${ETH_BC_BLOCK_PERIOD}" \
    --dev.gaslimit "${ETH_BC_BLOCK_GAS_LIMIT}" \
    --networkid "${ETH_BC_NETWORK_ID}" \
    --identity "${ETH_BC_NODE_NAME}" \
    --verbosity "${ETH_BC_VERBOSITY}" \
    --vmodule "${ETH_BC_VMODULE_VERBOSITY}"
else
  echo "NON run geth cmd passed, executing: exec $*"
  exec "$@"
fi
