# ipor-protocol

IPOR smart contracts

## Job statuses

-   [![CI](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/ci.yml/badge.svg)](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/ci.yml)
-   [![CD](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/cd.yml/badge.svg)](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/cd.yml)

## Usage

### Pre-run steps

- Install `python3-pip`.
- Install `solc-select` using pip: `pip3 install solc-select`
- Install docker and docker-compose
- Install `node` and `npm`.
- Install `truffle` : `npm install -g truffle`
- Install `j2cli` : `pip3 install j2cli`
- Install `curl`, `jq`
- Check truffle binary execution permission. Run `chmod +x truffle` in binary dir if execution flag is missing.
- Run `sudo apt-get install build-essential`
- Install AWS CLI if You want to download images from AWS ECR: https://aws.amazon.com/cli/

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

### How to change used docker images?

The default docker images configured in `.env-local.j2` file are the local ones, that developer can use when working locally with smart contracts:

```
IPOR_COCKPIT_DOCKER_IMAGE="ipor-cockpit:latest"
ETH_BC_DOCKER_IMAGE="ethereum/client-go:v1.10.18"
```

But there are also docker images with already migrated smart contracts for faster usage without waiting for smart contracts compilation and migrations.
Like those below, which can be changed in `.env` file:

```
IPOR_COCKPIT_DOCKER_IMAGE="964341344241.dkr.ecr.eu-central-1.amazonaws.com/ipor-cockpit:s0-develop"
ETH_BC_DOCKER_IMAGE="964341344241.dkr.ecr.eu-central-1.amazonaws.com/ipor-geth:s0-develop"
```

### What docker image tag means?

There are different possible tags that You can use. They are created in this format:
```
{IMAGE_TYPE}-{BRANCH_NAME}
```
where:
* `IMAGE_TYPE` - is the type of the image that is used in ethereum blockchain, the geth node. 
It corresponds to the type of smart contracts deployment, if they are for ITF (IPOR test framework) or normal (non-ITF). 
It also says about how new blocks are created in ethereum blockchain.
  * `itf` - new blocks are created with every transaction, IPOR ITF smart contracts were deployed into blockchain, the geth node was modified to accept bigger smart contract size - twice as big as normal
  * `s0` - new blocks are created with every transaction, IPOR normal (non-ITF) smart contracts were deployed into blockchain
  * `s12` - new blocks are created every 12 seconds, IPOR normal (non-ITF) smart contracts were deployed into blockchain
* `BRANCH_NAME` - is the name of the branch from which smart contracts where migrated, like:
  * `develop` - from ipor-protocol *develop* branch
  * `main` - from ipor-protocol *main* branch

### What possible docker images tags I can use?

* `itf-develop` - image with IPOR ITF migrated smart contracts from develop branch, new blocks are created with every transaction
* `s0-develop` - image with IPOR migrated smart contracts from develop branch, new blocks are created with every transaction
* `s12-develop` - image with IPOR migrated smart contracts from develop branch, new blocks are created every 12 seconds
* `itf-main` - image with IPOR ITF migrated smart contracts from main branch, new blocks are created with every transaction
* `s0-main` - image with IPOR migrated smart contracts from main branch, new blocks are created with every transaction
* `s12-main` - image with IPOR migrated smart contracts from main branch, new blocks are created every 12 seconds

### How to execute migrations locally?

-   Migration is executed with the use of Truffle
-   In `.env` file setup migration folder `SC_MIGRATION_DIRECTORY` which should point to one of subfolder in folder `./ipor-protocol/migrations/envs`
-   In `.env` file setup network name `ETH_BC_NETWORK_NAME` which should correspond to one of network names defined in `truffle-config.js`
-   In command line execute `./run.sh m` for incremental migration or `./run.sh mc` if you want to migrate all new smart contracts from scratch

### How to execute migrations using git tags?

-   You can start migration as default. Start from last completed migration to latest:
-   ./migrate.sh
-   Start from 5th migration to latest
-   ./migrate.sh --start-from-migration 5
-   Start from 5th migration to 10th migration 
-   ./migrate.sh --start-from-migration 5 --migrate-to 10
-   Start migration in dry run mode - you will see only migration logs without running migration commands
-   ./migration.sh --dry-run
-   Change default tag name prefix "migration-" to "audit-"
-   ./migration.sh --tag-prefix "audit-"

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
- cockpit - run only cockpit
- cockpit-provider - run containers needed to serve cockpit on remote server
- ssl-eth-bc - run only ssl containers needed for Ethereum blockchain
- ssl-explorer - run only ssl containers needed for Ethereum blockchain explorer
- all - run all containers

## Slither

-   `docker pull trailofbits/eth-security-toolbox`
-   go to main project folder
-   `docker run -it --platform linux/amd64 -v /Users/piotrrzonsowski/ipor/ipor-protocol:/share trailofbits/eth-security-toolbox`
-   `cd /share`
-   `npm install`
-   `slither . --solc-remaps @openzeppelin/=$(pwd)/node_modules/@openzeppelin/ < Optional --print human-summary >`
