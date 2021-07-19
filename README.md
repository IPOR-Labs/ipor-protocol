### How to run?

1. Clone in the same folder `ipor-blockchain` and `ipor-protocol` repositories.
2. In folder `ipor-protocol` configure `.env` file based on `.env-sample`
3. Execute script `./run.sh`
4. Application available in url `http://localhost:4000`
5. Local blockchain Ganacha available in url `http://localhost:9545` `chainId = 2337`
6. Before enter on web page `http://localhost:4000` connect to local blockchain Ganache using Metamask
    - In Metamask choose `Custom RPC`
    - Enter network name `Docker Local`
    - Enter New RPC URL: `http://localhost:9545`
    - Enter Chain ID: `2337`
    - Click `Save`


#### Configure your local `.env` using sample in file `.env-sample`

#### Deploy Smart Contract on Kovan Testnet

In project root folder execute in command line:

`truffle migrate --network kovan`

#### Deploy Smart Contract on Testnet which contains Smart Contract Upgrade

In project root folder execute in command line:

`truffle migrate --network kovan --skip-dry-run`


