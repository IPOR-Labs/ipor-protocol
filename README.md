# ipor-protocol

IPOR smart contracts

## Job statuses

-   [![CI](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/ci.yml/badge.svg)](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/ci.yml)
-   [![CD](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/cd.yml/badge.svg)](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/cd.yml)

## Usage

### Pre-run steps

-   Install `python3-pip`.
-   Install `solc-select` using pip: `pip3 install solc-select`
-   Install docker and docker-compose
-   Install `node` and `npm`.
-   Install `truffle` : `npm install -g truffle`
-   Check truffle binary execution permission. Run `chmod +x truffle` in binary dir if execution flag is missing.
-   Run `sudo apt-get install build-essential`

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

#### How to run all tests with coverage?

`npx hardhat coverage`

Coverage reports available in `coverage` folder.

#### How to run tests inside specific file with coverage for mainnet fork?

`export FORK_ENABLED=true; npx hardhat coverage --testfiles "test/vault/mainnet-fork/stanley-aave-dai.ts"`

Notice! `npx hardhat coverage` not includes coverage from tests in mainnet fork, this test coverage should be executed separately on every file.

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

-   developer - run containers needed to work locally as a developer, so without ssl containers
-   eth-bc-provider - run containers needed to serve Ethereum blockchain on remote server
-   eth-explorer-provider - run containers needed to serve Ethereum blockchain explorer on remote server
-   explorer - run only Ethereum blockchain explorer
-   dev-tool - run only dev-tool
-   ssl-eth-bc - run only ssl containers needed for Ethereum blockchain
-   ssl-explorer - run only ssl containers needed for Ethereum blockchain explorer
-   all - run all containers

## Slither

-   `docker pull trailofbits/eth-security-toolbox`
-   go to main project folder
-   `docker run -it --platform linux/amd64 -v /Users/piotrrzonsowski/ipor/ipor-protocol:/share trailofbits/eth-security-toolbox`
-   `cd /share`
-   `npm install`
-   `slither . --solc-remaps @openzeppelin/=$(pwd)/node_modules/@openzeppelin/ < Optional --print human-summary >`
