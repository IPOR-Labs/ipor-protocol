import "@openzeppelin/hardhat-upgrades";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-web3";

import { task } from "hardhat/config";
import "hardhat-tracer";
import "solidity-coverage";
import "@typechain/hardhat";
import "hardhat-abi-exporter";
import networks from "./hardhat.network";
import "dotenv";

require("dotenv").config();

require("hardhat-contract-sizer");

if (process.env.REPORT_GAS === "true") {
    require("hardhat-gas-reporter");
}

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners();

    for (const account of accounts) {
        console.log(account.address);
    }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
export default {
    solidity: {
        version: "0.8.9",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    networks,
    paths: {
        tests: "./test",
    },
    typechain: {
        outDir: "types",
        target: "ethers-v5",
        alwaysGenerateOverloads: true, // should overloads with full signatures like deposit(uint256) be generated always, even if there are no overloads?
        externalArtifacts: ["externalArtifacts/*.json"], // optional array of glob patterns with external artifacts to process (for example external libs from node_modules)
    },
    abiExporter: [
        {
            path: "./abi/pretty",
            pretty: true,
        },
        {
            path: "./abi/ugly",
            pretty: false,
        },
    ],
};
