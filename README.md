# ipor-protocol

IPOR smart contracts

## Job statuses

-   [![CI](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/ci.yml/badge.svg)](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/ci.yml)
-   [![CD](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/cd.yml/badge.svg)](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/cd.yml)

## Usage

### Pre-run steps

-   Install `Foundry` from https://getfoundry.sh/
-   Install `python3-pip`.
-   Install `solc-select` using pip: `pip3 install solc-select`
-   Install `node` (v16.15.0) and `npm` (v8.5.5).
-   Install `truffle` : `npm install -g truffle`
-   Install `jq`
-   Check truffle binary execution permission. Run `chmod +x truffle` in binary dir if execution flag is missing.
-   Run `sudo apt-get install build-essential`

### How to run as developer?

1. Clone `ipor-protocol` repository.
2. In directory `ipor-protocol` configure `.env` file based on `.env-local.j2`
    ```
    cd ipor-protocol
    cp .env-local.j2 .env
    ```
    WARNING! Optional: You can setup `GLOBAL_AWS_PROFILE` env variable with the name of Your local AWS profile. Its only needed when publishing migration results to S3.
3. Run local `Ethereum` node. The assumption is that `Ethereum` node is a local instance of `anvil` from `Foundry` and will be available at `http://localhost:8545` with `chainId = 31337`
4. Execute script `./run.sh` with specific command, like below:
    - `mc` - migrate Smart Contracts to blockchain from the first migration
    - `m` - migrate Smart Contracts to blockchain from the last migration

### How to execute migrations locally?

-   Migration is executed with the use of Truffle
-   In `.env` file setup migration folder `SC_MIGRATION_DIRECTORY` which should point to one of subfolder in folder `./ipor-protocol/migrations/envs`
-   In `.env` file setup network name `ETH_BC_NETWORK_NAME` which should correspond to one of network names defined in `truffle-config.js`
-   In command line execute `./run.sh m` for incremental migration or `./run.sh mc` if you want to migrate all new smart contracts from scratch

### How to execute smart contracts migrations remotely?

-   On remote server all parameters in `.env` are already prepared, you should not modify them without consultation with IT Team.
-   Connect to server by ssh
-   `cd repos/ipor-protocol`
-   `git pull`
-   `./run.sh m mlogs`
-   `./run.sh p`
-   `exit`

#### How to run all tests?

`npm run test`

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

### How to extract all error codes from solidity codes to json file?

`npm run export-errorCodes`

#### How to check contract size?

Run in command line: `truffle run contract-size`

#### How to generate documentation with markdown?

Run in command line: `yarn run hardhat docgen --theme markdown`

## Slither

-   `docker pull trailofbits/eth-security-toolbox`
-   go to main project folder
-   `docker run -it --platform linux/amd64 -v ../ipor-protocol:/share trailofbits/eth-security-toolbox`
-   `cd /share`
-   `npm install`
-   `slither . --solc-remaps @openzeppelin/=$(pwd)/node_modules/@openzeppelin/ < Optional --print human-summary >`
