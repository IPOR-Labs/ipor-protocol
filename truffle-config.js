const path = require("path");
require('dotenv').config()
const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
    plugins: ["solidity-coverage"],
    contracts_build_directory: path.join(__dirname, "app/src/contracts"),
    networks: {
        develop: { // default with truffle unbox is 7545, but we can use develop to test changes, ex. truffle migrate --network develop
            host: "127.0.0.1",
            port: 8545,
            network_id: "*"
        },
        kovan: {
            networkCheckTimeout: 10000,
            provider: () => {
                return new HDWalletProvider(
                    process.env.MNEMONIC,
                    `wss://kovan.infura.io/ws/v3/${process.env.INFURA_PROJECT_ID}`
                );
            },
            network_id: "42",
        },

        ropsten: {
            networkCheckTimeout: 10000,
            provider: () => {
                return new HDWalletProvider(
                    process.env.MNEMONIC,
                    `wss://ropsten.infura.io/ws/v3/${process.env.INFURA_PROJECT_ID}`
                );
            },
            network_id: "3",
        }

    },
    compilers: {
        solc: {
            version: "0.8.4",    // Fetch exact version from solc-bin (default: truffle's version)
            // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
            // settings: {          // See the solidity docs for advice about optimization and evmVersion
            //  optimizer: {
            //    enabled: false,
            //    runs: 200
            //  },
            //  evmVersion: "byzantium"
            // }
        }
    },
};
