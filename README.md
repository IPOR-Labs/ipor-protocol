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
-   Install `node` (v18.15.0) and `npm` (v9.5.0).
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


## Slither

-   `docker pull trailofbits/eth-security-toolbox`
-   go to main project folder
-   `docker run -it --platform linux/amd64 -v ../ipor-protocol:/share trailofbits/eth-security-toolbox`
-   `cd /share`
-   `npm install`
-   `slither . --solc-remaps @openzeppelin/=$(pwd)/node_modules/@openzeppelin/ < Optional --print human-summary >`
