### How to run?

1. Clone `ipor-blockchain` and `ipor-protocol` repositories to the same folder.
2. In folder `ipor-protocol` configure `.env` file based on `.env-sample`
3. Execute script `./run.sh` with specific commands which can be joined
   - `g` - run Ganache blockchain
   - `m` - migrate Smart Contracts to blockchain
   - `b` - build Milton Tool docker
   - 'r' - run Milton Tool
4. Application will be available at `http://localhost:4000`
5. Local blockchain Ganache will be available at `http://localhost:9545` `chainId = 2337`
6. Before you can open the address `http://localhost:4000` connect to local blockchain Ganache using Metamask
    - In Metamask choose `Custom RPC`
    - Enter network name `Docker Local`
    - Enter New RPC URL: `http://localhost:9545`
    - Enter Chain ID: `2337`
    - Click `Save`

#### How to check contract size?

Run in command line: `truffle run contract-size`


#### Configure your local `.env` using sample in file `.env-sample`

#### Deploy Smart Contract on Kovan Testnet

In project root folder execute in command line:

`truffle migrate --network kovan`

#### Deploy Smart Contract on Testnet which contains Smart Contract Upgrade

In project root folder execute in command line:

`truffle migrate --network kovan --skip-dry-run`
