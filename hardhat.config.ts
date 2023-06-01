require("dotenv").config();
require("hardhat-docgen");
require("hardhat-contract-sizer");
import "dotenv";
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
import "@hardhat-docgen/core";
import "@hardhat-docgen/markdown";

let jobs = 2;

if (process.env.HARDHAT_MOCHA_JOBS) {
    jobs = Number(process.env.HARDHAT_MOCHA_JOBS);
}

if (process.env.HARDHAT_REPORT_GAS === "true") {
    require("hardhat-gas-reporter");
    jobs = 1;
}

if (process.env.FORK_ENABLED === "true") {
    jobs = 1;
}

console.log("Hardhat Mocha Jobs =", jobs);

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
export default {
    solidity: {
        version: "0.8.20",
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
            path: "./.ipor/abis/pretty",
            pretty: true,
        },
        {
            path: "./.ipor/abis/ugly",
            pretty: false,
        },
    ],
    mocha: {
        timeout: 40000,
        parallel: true,
        jobs,
    },
};
