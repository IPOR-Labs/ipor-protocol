const path = require("path");
require("dotenv").config();
const HDWalletProvider = require("@truffle/hdwallet-provider");

module.exports = {
    plugins: [
        "truffle-contract-size",
        // "buidler-gas-reporter",
        "solidity-coverage",
    ],
    migrations_directory: process.env.SC_MIGRATION_DIRECTORY,
    contracts_build_directory: path.join(__dirname, "app/src/contracts"),
    networks: {
        docker: {
            provider: () => {
                return new HDWalletProvider(
                    [process.env.SC_ADMIN_PRIV_KEY],
                    process.env.ETH_BC_URL
                );
            },
            network_id: process.env.ETH_BC_NETWORK_ID,
            skipDryRun: true,
            networkCheckTimeout: 600000, //10 min
            gas: 10000000,
            gasPrice: 100000000000,
            confirmations: process.env.SC_MIGRATION_CONFIRMATION,
        },
        develop: {
            host: "127.0.0.1",
            port: 8545,
            network_id: "*",
            gasLimit: 12500000,
        },
    },
    mocha: {
        useColors: true,
        // reporter: 'eth-gas-reporter',
        reporterOptions: {
            showTimeSpent: true,
            // outputFile: "test-eth-gas-report.log"
        },
    },
    compilers: {
        solc: {
            version: "0.8.16",
            docker: true,
            settings: {
                // See the solidity docs for advice about optimization and evmVersion
                optimizer: {
                    enabled: true,
                    runs: 800,
                },
                evmVersion: "london",
            },
        },
    },
};
