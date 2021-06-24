#### Configure your local `.env`

```properties
MNEMONIC=
INFURA_PROJECT_ID=
``` 

#### Build project

`npm install`

#### Deploy Smart Contract on Kovan Testnet

In project root folder execute in command line:

`truffle migrate --network kovan`

#### Deploy Smart Contract on Testnet which contains Smart Contract Upgrade

In project root folder execute in command line:

`truffle migrate --network kovan --skip-dry-run`