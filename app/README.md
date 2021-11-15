## IPOR Protocol

### Run IPOR App and local blockchain

`docker build . -t ipor-labs/ipor-app`

`docker-compose up`

IPOR App available in port `3000`

Local blockchain available in port `9545`

#### Compile contracts

In project root folder execute in command line:

`truffle compile`

If there is a new version of Smart Contracts then execute deploy:

`truffle migrate --network kovan`

#### Run application locally

In `app` folder execute in command line:

`npm run start`
