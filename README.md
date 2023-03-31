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
-   Install `j2cli` : `pip3 install j2cli`
-   Install `curl`, `jq`
-   Check truffle binary execution permission. Run `chmod +x truffle` in binary dir if execution flag is missing.
-   Run `sudo apt-get install build-essential`
-   Install AWS CLI if You want to download images from AWS ECR: https://aws.amazon.com/cli/

### How to run as developer?

1. Clone `ipor-protocol` repository.
2. In directory `ipor-protocol` configure `.env` file based on `.env-local.j2`
    ```
    cd ipor-protocol
    cp .env-local.j2 .env
    ```
    WARNING! You need to setup `GLOBAL_AWS_PROFILE` env variable with the name of Your local AWS profile.
3. In directory `ipor-protocol/containers/cockpit` configure `.env` file based on `.env-local.j2`
    ```
    cd ipor-protocol/containers/cockpit
    cp .env-local.j2 .env
    ```
4. Execute script `./run.sh` with specific commands in order like below:
    - `m` - migrate Smart Contracts to blockchain
5. Application will be available at `http://localhost:4000`
6. Local blockchain will be available at `http://localhost:8545` `chainId = 31337`
7. Local blockchain explorer will be available at `http://localhost:9055`
8. Before you can open the address `http://localhost:4000` connect to local blockchain using Metamask
    - In Metamask choose `Custom RPC`
    - Enter network name `localhost`
    - Enter New RPC URL: `http://localhost:8545`
    - Enter Chain ID: `31337`
    - Click `Save`

### How to execute migrations locally?

-   Migration is executed with the use of Truffle
-   In `.env` file setup migration folder `SC_MIGRATION_DIRECTORY` which should point to one of subfolder in folder `./ipor-protocol/migrations/envs`
-   In `.env` file setup network name `ETH_BC_NETWORK_NAME` which should correspond to one of network names defined in `truffle-config.js`
-   In command line execute `./run.sh m` for incremental migration or `./run.sh mc` if you want to migrate all new smart contracts from scratch

### How to execute smart contracts migrations remotely?

-   On remote server all parameters in `.env` are already prepared, you should not modify them without consultation with IT Team.
-   For `dev` in command line execute: `ssh ipor-dev-warren`,
-   `cd repos/ipor-protocol`
-   `git pull`
-   `./run.sh m mlogs`
-   `./run.sh p`
-   `exit`

### How to deploy new version of `Cockpit` on `Goerli` environment?

Do following steps:

-   Go to Github Actions in `ipor-protocol` repository
-   Select `Deploy Cockpit` -> Run workflow:
-   Select branch: `env/goerli`
-   IPOR cockpit Amplify application name: `ipor-goerli-cockpit`

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
