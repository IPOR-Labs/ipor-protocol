# ipor-protocol

Shared java library used in IPOR oracle related services.

## Job statuses

Smart contracts continuous integration last status:

* [![CI](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/main.yml/badge.svg)](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/main.yml)

Java continuous integration last status:

* [![Java CD](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/java-cd.yml/badge.svg)](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/java-cd.yml)

Java continuous deployment last status:

* [![Java CI](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/java-ci.yml/badge.svg)](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/java-ci.yml)

### How to run as developer?

1. Clone `ipor-protocol` repository.
2. In directory `ipor-protocol` configure `.env` file based on `.env-local.j2`
3. In directory `ipor-protocol/containers/dev-tool` configure `.env` file based on `.env-local.j2`
4. Execute script `./run.sh` with specific commands in order like below:
   - `b` - build docker containers
   - `r` - run docker-compose
   - `m` - migrate Smart Contracts to blockchain
   - `b` - build docker containers with migrated smart contract addresses
   - `r` - run docker-compose once again
5. Application will be available at `http://localhost:4000`
6. Local blockchain will be available at `http://localhost:9545` `chainId = 5777`
7. Local blockchain explorer will be available at `http://localhost:9055`
8. Before you can open the address `http://localhost:4000` connect to local blockchain using Metamask
    - In Metamask choose `Custom RPC`
    - Enter network name `localhost`
    - Enter New RPC URL: `http://localhost:9545`
    - Enter Chain ID: `5777`
    - Click `Save`

#### How to run all tests?

`npx hardhat test`

#### How to run tests for specific file?

`npx hardhat test test/MiltonSpread.test.js`

#### How to run all tests with additional logs?

`npx hardhat test --logs`

#### How to check contract size?

Run in command line: `truffle run contract-size`

#### How to reset Ethereum blockchain state?

Run in command line: `./run.sh c`

### Environment variables configuration
#### COMPOSE_PROFILE
Docker compose profile used to run containers selectively, locally developer should use: `developer`
other available options:
- developer - run containers needed to work locally as a developer, so without ssl containers 
- eth-bc-provider - run containers needed to serve Ethereum blockchain on remote server
- eth-explorer-provider - run containers needed to serve Ethereum blockchain explorer on remote server 
- explorer - run only Ethereum blockchain explorer
- dev-tool - run only dev-tool
- ssl-eth-bc - run only ssl containers needed for Ethereum blockchain
- ssl-explorer - run only ssl containers needed for Ethereum blockchain explorer
- all - run all containers
