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
    assert_required_variable "${ETH_BC_NODE_MODE}" "ETH_BC_NODE_MODE"
    assert_required_variable "${ETH_BC_NODE_NAME}" "ETH_BC_NODE_NAME"
    assert_required_variable "${ETH_BC_HTTP_API}" "ETH_BC_HTTP_API"
    assert_required_variable "${ETH_BC_WS_API}" "ETH_BC_WS_API"

    if [ ! -d "${ETH_BC_DATA_WORK_DIR}" ]; then
        echo "Initialize geth configuration..."
        geth --datadir "${ETH_BC_DATA_DIR}" init "${ETH_BC_GENESIS_BLOCK_FILE}"
        geth --datadir "${ETH_BC_DATA_DIR}" account import --password "${ETH_BC_MINER_KEY_PASSWORD_FILE}" "${ETH_BC_MINER_KEY_FILE}"
    else
        echo "Configuration already initialized."
    fi

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
        --networkid "${ETH_BC_NETWORK_ID}" \
        --identity "${ETH_BC_NODE_NAME}" \
        --verbosity ${ETH_BC_VERBOSITY} \
        --vmodule "${ETH_BS_VMODULE_VERBOSITY}"
else
    echo "NON run geth cmd passed, executing: exec $*"
    exec "$@"
fi
