#### Rules required when preparing migration script

-   Increase version number inside smart contract when implementation inside source code is different that implementation deployed on Mainnet
-   deployment new smart contract put in separate migration script
-   one migration script should not contain a lot of changes in blockchain
-   in every migration script at the end of file should be executed commans
    `await func.updateLastCompletedMigration();`
-   check if your migration is aligned for all folders `mainnet`, `private-testnet`, `goerli`
-   never change scripts in `libs` folder but always add new one with new number

#### What is the meaning of folders in migrations?

-   `mainnet` - migrations specific for mainnet environment
-   `private-testnet` - migrations specific for dev, test, localhost environments
-   `goerli` - migrations specific for Goerli environment

#### Notice!

Migration inside `migrations/env/private-testnet` folder is based on current source code. If you add incompatible changes in smart contract please align old scripts to new changes. Don't add incremental changes for example with upgrades in folder `migrations/env/private-testnet`.

#### Notice!

Binary state of smart contracts on Mainnet is determined by incremental migration scripts added to folder `migrations/env/mainnet` and the commit hash on which this migration was executed.

#### Notice!

Migration execution on up to date source code in `main` branch using command `./run.sh mc` doesn't setup binary state of smart contracts which is on Mainnet. Binary state of smart contracts on Mainnet is based on migration done over time.
