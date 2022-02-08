FROM ethereum/client-go:alltools-v1.10.12

ENV ENV_PROFILE localhost

COPY geth-entrypoint.sh /geth-entrypoint.sh
COPY envs/${ENV_PROFILE}/genesis.json /genesis.json
COPY envs/${ENV_PROFILE}/geth-config.toml /geth-config.toml
COPY envs/${ENV_PROFILE}/miner.key /miner.key
COPY envs/${ENV_PROFILE}/key-password.txt /key-password.txt

ENV TZ "Europe/Warsaw"
ENV ETH_BC_CORS "*"
ENV ETH_BC_HOST_ADDRESS "0.0.0.0"
ENV ETH_BC_MINER_ADDRESS "0x9Ba5D30c0D862cF718189CDb6B7886C7D073ee41"
ENV ETH_BC_NETWORK_PORT 40505
ENV ETH_BC_DATA_DIR "/root/.ethereum"
ENV ETH_BC_GENESIS_BLOCK_FILE "/genesis.json"
ENV ETH_BC_CONFIG_FILE "/geth-config.toml"
ENV ETH_BC_MINER_KEY_PASSWORD_FILE "/key-password.txt"
ENV ETH_BC_MINER_KEY_FILE "/miner.key"
ENV ETH_BC_MINER_THREADS "1"
ENV ETH_BC_NETWORK_ID "5777"
ENV ETH_BC_BLOCK_PERIOD "0"
ENV ETH_BC_NODE_MODE "archive"
ENV ETH_BC_NODE_NAME "ipor-eth-network"
ENV ETH_BC_HTTP_API "eth,net,web3,debug,txpool"
ENV ETH_BC_WS_API "eth,net,web3,debug,txpool"

ENTRYPOINT ["/geth-entrypoint.sh"]
CMD ["run-geth"]
