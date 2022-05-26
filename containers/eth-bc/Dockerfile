# FROM TAG: alltools-v1.10.15
FROM ethereum/client-go@sha256:bf38e772f2cc68565241a8f3ddb12d857d4e0e422f36018f84681608285e269c

HEALTHCHECK --interval=1m --timeout=3s \
  CMD curl -X POST -s --data \
  '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' \
  -H 'Content-Type: application/json' 'http://localhost:8545' | jq -r '.result.number' || exit 1

RUN apk add jq && rm -rf /var/cache/apt/*

ARG ENV_PROFILE
ARG TZ
ARG ETH_BC_CORS
ARG ETH_BC_HOST_ADDRESS
ARG ETH_BC_MINER_ADDRESS
ARG ETH_BC_NETWORK_PORT
ARG ETH_BC_DATA_DIR
ARG ETH_BC_GENESIS_BLOCK_FILE
ARG ETH_BC_CONFIG_FILE
ARG ETH_BC_MINER_KEY_PASSWORD_FILE
ARG ETH_BC_MINER_KEY_FILE
ARG ETH_BC_MINER_THREADS
ARG ETH_BC_NETWORK_ID
ARG ETH_BC_BLOCK_PERIOD
ARG ETH_BC_BLOCK_GAS_LIMIT
ARG ETH_BC_NODE_MODE
ARG ETH_BC_NODE_NAME
ARG ETH_BC_HTTP_API
ARG ETH_BC_WS_API
ARG ETH_BC_VERBOSITY
ARG ETH_BC_VMODULE_VERBOSITY
ARG ETH_BC_DUMP_DIR

ENV ENV_PROFILE=${ENV_PROFILE:-localhost} \
  TZ=${TZ:-Europe/Warsaw} \
  ETH_BC_CORS=${ETH_BC_CORS:-*} \
  ETH_BC_HOST_ADDRESS=${ETH_BC_HOST_ADDRESS:-0.0.0.0} \
  ETH_BC_MINER_ADDRESS=${ETH_BC_MINER_ADDRESS:-0x9Ba5D30c0D862cF718189CDb6B7886C7D073ee41} \
  ETH_BC_NETWORK_PORT=${ETH_BC_NETWORK_PORT:-40505} \
  ETH_BC_DATA_DIR=${ETH_BC_DATA_DIR:-/root/.ethereum} \
  ETH_BC_GENESIS_BLOCK_FILE=${ETH_BC_GENESIS_BLOCK_FILE:-/genesis.json} \
  ETH_BC_CONFIG_FILE=${ETH_BC_CONFIG_FILE:-/geth-config.toml} \
  ETH_BC_MINER_KEY_PASSWORD_FILE=${ETH_BC_MINER_KEY_PASSWORD_FILE:-/key-password.txt} \
  ETH_BC_MINER_KEY_FILE=${ETH_BC_MINER_KEY_FILE:-/miner.key} \
  ETH_BC_MINER_THREADS=${ETH_BC_MINER_THREADS:-1} \
  ETH_BC_NETWORK_ID=${ETH_BC_NETWORK_ID:-5777} \
  ETH_BC_BLOCK_PERIOD=${ETH_BC_BLOCK_PERIOD:-12} \
  ETH_BC_BLOCK_GAS_LIMIT=${ETH_BC_BLOCK_GAS_LIMIT:-30000000} \
  ETH_BC_NODE_MODE=${ETH_BC_NODE_MODE:-archive} \
  ETH_BC_NODE_NAME=${ETH_BC_NODE_NAME:-ipor-eth-network} \
  ETH_BC_HTTP_API=${ETH_BC_HTTP_API:-eth,net,web3,debug,txpool} \
  ETH_BC_WS_API=${ETH_BC_WS_API:-eth,net,web3,debug,txpool} \
  ETH_BC_VERBOSITY=${ETH_BC_VERBOSITY:-4} \
  ETH_BC_VMODULE_VERBOSITY=${ETH_BC_VMODULE_VERBOSITY:-rpc=5} \
  ETH_BC_DUMP_DIR=${ETH_BC_DUMP_DIR:-eth-bc-dump}

COPY geth-entrypoint.sh /geth-entrypoint.sh
COPY "envs/${ENV_PROFILE}/genesis.json" /genesis.json
COPY "envs/${ENV_PROFILE}/geth-config.toml" /geth-config.toml
COPY "envs/${ENV_PROFILE}/miner.key" /miner.key
COPY "envs/${ENV_PROFILE}/key-password.txt" /key-password.txt

ENTRYPOINT ["/geth-entrypoint.sh"]
CMD ["run-geth"]

COPY eth-bc-dump/.ethereum /root/.ethereum
VOLUME /root/.ethereum
