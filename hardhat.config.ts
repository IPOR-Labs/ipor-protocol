import { task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import "hardhat-tracer";
import "solidity-coverage";
import "@nomiclabs/hardhat-web3";
import "dotenv";
// require("@nomiclabs/hardhat-waffle");
// require("hardhat-tracer");
// require("solidity-coverage");
// require("@nomiclabs/hardhat-web3");
require("dotenv").config();

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
                runs: 1000,
            },
        },
    },
    paths: {
        tests: "./test",
    },
};
