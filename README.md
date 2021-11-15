### How to run?

1. Clone `ipor-protocol` repository.
2. In folder `ipor-protocol` configure `.env` file based on `.env.j2`
3. Execute script `./run.sh` with specific commands which can be joined
   - `b` - build docker containers
   - `r` - run docker-compose
   - `m` - migrate Smart Contracts to blockchain
   - `b` - build docker containers with migrated smart contract addresses
   - `r` - run docker-compose once again
4. Application will be available at `http://localhost:4000`
5. Local blockchain will be available at `http://localhost:9545` `chainId = 5777`
6. Before you can open the address `http://localhost:4000` connect to local blockchain using Metamask
    - In Metamask choose `Custom RPC`
    - Enter network name `Docker Local`
    - Enter New RPC URL: `http://localhost:9545`
    - Enter Chain ID: `5777`
    - Click `Save`

#### How to check contract size?

Run in command line: `truffle run contract-size`
