const path = require("path");
require('dotenv').config()
const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
    plugins: [
        "truffle-contract-size",
        // "buidler-gas-reporter",
        "solidity-coverage"
    ],
    contracts_build_directory: path.join(__dirname, "app/src/contracts"),
    networks: {
        // test: {
        //     network_id: "*",
        //     gas: 3500000
        // },
        dev: {
            host: "sc.ipor.info",
            port: 8545,
            network_id: "*"
        },
        docker: {
            provider: () => {
                return new HDWalletProvider(process.env.ADMIN_PRIV_KEY, process.env.ETH_BC_URL);
            },
            network_id: "5777",
            skipDryRun: true
        },
        docker_debug: {
            host: "127.0.0.1",
            port: 9545,
            network_id: "5777",
            skipDryRun: true
        },
        develop: {
            host: "127.0.0.1",
            port: 8545,
            network_id: "*",
            gasLimit: 12500000
        },
        develop2: {
            host: "127.0.0.1",
            port: 7545,
            network_id: "5777"
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
    mocha: {
        useColors: true,
        reporter: 'eth-gas-reporter',
        reporterOptions : {
            showTimeSpent : true,
            outputFile: "test-eth-gas-report.log"
        }
    },
    compilers: {
        solc: {
            version: "0.8.9",    // Fetch exact version from solc-bin (default: truffle's version)
            // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)

            settings: {          // See the solidity docs for advice about optimization and evmVersion
                optimizer: {
                    enabled: true,
                    runs: 800
                },
                //  evmVersion: "byzantium"
            }
        }
    },
};
