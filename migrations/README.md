#### Rules required when preparing migration script

-   deployment new smart contract put in separate migration script
-   one migration script should not contain a lot of changes in blockchain
-   in every migration script at the end of file should be executed commans
    `await func.updateLastCompletedMigration();`
-   check if your migration is aligned for all folders `mainnet`, `private-testnet`, `rinkeby`
-   never change scripts in `libs` folder but always add new one with new number

#### What is the meaning of folders in migrations?

-   `mainnet` - migrations specific for mainnet environment
-   `private-testnet` - migrations specific for dev, test, localhost environments
-   `rinkeby` - migrations specific for Rinkeby environment
-   `goerli` - migrations specific for Goerli environment

#### How to specify migration folder?
