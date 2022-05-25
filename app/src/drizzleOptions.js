import IporOracle from "./contracts/IporOracle.json";
import MiltonUsdt from "./contracts/MiltonUsdt.json";
import MiltonUsdc from "./contracts/MiltonUsdc.json";
import MiltonDai from "./contracts/MiltonDai.json";
import MiltonStorageUsdt from "./contracts/MiltonStorageUsdt.json";
import MiltonStorageUsdc from "./contracts/MiltonStorageUsdc.json";
import MiltonStorageDai from "./contracts/MiltonStorageDai.json";
import IpTokenUsdt from "./contracts/IpTokenUsdt.json";
import IpTokenUsdc from "./contracts/IpTokenUsdc.json";
import IpTokenDai from "./contracts/IpTokenDai.json";
import IvTokenUsdt from "./contracts/IvTokenUsdt.json";
import IvTokenUsdc from "./contracts/IvTokenUsdc.json";
import IvTokenDai from "./contracts/IvTokenDai.json";

import MiltonSpreadModel from "./contracts/MiltonSpreadModel.json";
import CockpitDataProvider from "./contracts/CockpitDataProvider.json";
import MiltonFacadeDataProvider from "./contracts/MiltonFacadeDataProvider.json";
import IporOracleFacadeDataProvider from "./contracts/IporOracleFacadeDataProvider.json";
import JosephUsdt from "./contracts/JosephUsdt.json";
import JosephUsdc from "./contracts/JosephUsdc.json";
import JosephDai from "./contracts/JosephDai.json";
import StanleyUsdt from "./contracts/StanleyUsdt.json";
import StanleyUsdc from "./contracts/StanleyUsdc.json";
import StanleyDai from "./contracts/StanleyDai.json";

import ItfIporOracle from "./contracts/ItfIporOracle.json";
import ItfMiltonUsdt from "./contracts/ItfMiltonUsdt.json";
import ItfMiltonUsdc from "./contracts/ItfMiltonUsdc.json";
import ItfMiltonDai from "./contracts/ItfMiltonDai.json";
import ItfJosephUsdt from "./contracts/ItfJosephUsdt.json";
import ItfJosephUsdc from "./contracts/ItfJosephUsdc.json";
import ItfJosephDai from "./contracts/ItfJosephDai.json";
import ItfStanleyUsdt from "./contracts/ItfStanleyUsdt.json";
import ItfStanleyUsdc from "./contracts/ItfStanleyUsdc.json";
import ItfStanleyDai from "./contracts/ItfStanleyDai.json";

import TestnetFaucet from "./contracts/TestnetFaucet.json";

import MockTestnetShareTokenAaveUsdt from "./contracts/MockTestnetShareTokenAaveUsdt.json";
import MockTestnetShareTokenAaveUsdc from "./contracts/MockTestnetShareTokenAaveUsdc.json";
import MockTestnetShareTokenAaveDai from "./contracts/MockTestnetShareTokenAaveDai.json";

import MockTestnetShareTokenCompoundUsdt from "./contracts/MockTestnetShareTokenCompoundUsdt.json";
import MockTestnetShareTokenCompoundUsdc from "./contracts/MockTestnetShareTokenCompoundUsdc.json";
import MockTestnetShareTokenCompoundDai from "./contracts/MockTestnetShareTokenCompoundDai.json";

import MockTestnetTokenDai from "./contracts/MockTestnetTokenDai.json";
import MockTestnetTokenUsdc from "./contracts/MockTestnetTokenUsdc.json";
import MockTestnetTokenUsdt from "./contracts/MockTestnetTokenUsdt.json";

import MockTestnetStrategyAaveUsdt from "./contracts/MockTestnetStrategyAaveUsdt.json";
import MockTestnetStrategyAaveUsdc from "./contracts/MockTestnetStrategyAaveUsdc.json";
import MockTestnetStrategyAaveDai from "./contracts/MockTestnetStrategyAaveDai.json";

import MockTestnetStrategyCompoundUsdt from "./contracts/MockTestnetStrategyCompoundUsdt.json";
import MockTestnetStrategyCompoundUsdc from "./contracts/MockTestnetStrategyCompoundUsdc.json";
import MockTestnetStrategyCompoundDai from "./contracts/MockTestnetStrategyCompoundDai.json";

import StrategyAaveUsdt from "./contracts/StrategyAaveUsdt.json";
import StrategyAaveUsdc from "./contracts/StrategyAaveUsdc.json";
import StrategyAaveDai from "./contracts/StrategyAaveDai.json";

import StrategyCompoundUsdt from "./contracts/StrategyCompoundUsdt.json";
import StrategyCompoundUsdc from "./contracts/StrategyCompoundUsdc.json";
import StrategyCompoundDai from "./contracts/StrategyCompoundDai.json";

require("dotenv").config({ path: "../../.env" });

let options;

const Web3 = require("web3");
const web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545') );//Web3.givenProvider || "ws://127.0.0.1:8545");

web3.fallback = {
    type: "ws",
    url: "ws://127.0.0.1:8545",
};

const abiERC20 = require("./contracts/ERC20.json");
const abiShareTokenAaveUsdt = require("./contracts/ERC20.json");
const abiShareTokenAaveUsdc = require("./contracts/ERC20.json");
const abiShareTokenAaveDai = require("./contracts/ERC20.json");
const abiShareTokenCompoundUsdt = require("./contracts/ERC20.json");
const abiShareTokenCompoundUsdc = require("./contracts/ERC20.json");
const abiShareTokenCompoundDai = require("./contracts/ERC20.json");

const usdt = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
const usdc = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const dai = "0x6B175474E89094C44Da98b954EedeAC495271d0F";

const aUsdt = "0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811";
const aUsdc = "0xBcca60bB61934080951369a648Fb03DF4F96263C";
const aDai = "0x028171bCA77440897B824Ca71D1c56caC55b68A3";

const cUsdt = "0xf650c3d88d12db855b8bf7d11be6c55a4e07dcc9";
const cUsdc = "0x39aa39c021dfbae8fac545936693ac917d5e7563";
const cDai = "0x5d3a536e4d6dbd6114cc1ead35777bab948e3643";

const MainnetStableUsdt = {
    contractName: "DrizzleUsdt",
    web3Contract: new web3.eth.Contract(abiERC20.abi, usdt),
};

const MainnetStableUsdc = {
    contractName: "DrizzleUsdc",
    web3Contract: new web3.eth.Contract(abiERC20.abi, usdc, {}),
};

const MainnetStableDai = {
    contractName: "DrizzleDai",
    web3Contract: new web3.eth.Contract(abiERC20.abi, dai),
};

const MainnetShareTokenAaveUsdt = {
    contractName: "DrizzleShareTokenAaveUsdt",
    web3Contract: new web3.eth.Contract(abiShareTokenAaveUsdt.abi, aUsdt),
};

const MainnetShareTokenAaveUsdc = {
    contractName: "DrizzleShareTokenAaveUsdc",
    web3Contract: new web3.eth.Contract(abiShareTokenAaveUsdc.abi, aUsdc),
};

const MainnetShareTokenAaveDai = {
    contractName: "DrizzleShareTokenAaveDai",
    web3Contract: new web3.eth.Contract(abiShareTokenAaveDai.abi, aDai),
};

const MainnetShareTokenCompoundUsdt = {
    contractName: "DrizzleShareTokenCompoundUsdt",
    web3Contract: new web3.eth.Contract(abiShareTokenCompoundUsdt.abi, cUsdt),
};

const MainnetShareTokenCompoundUsdc = {
    contractName: "DrizzleShareTokenCompoundUsdc",
    web3Contract: new web3.eth.Contract(abiShareTokenCompoundUsdc.abi, cUsdc),
};

const MainnetShareTokenCompoundDai = {
    contractName: "DrizzleShareTokenCompoundDai",
    web3Contract: new web3.eth.Contract(abiShareTokenCompoundDai.abi, cDai),
};

const DrizzleUsdt =
    process.env.REACT_APP_BS_NETWORK_NAME === "localhost"
        ? MainnetStableUsdt
        : MockTestnetTokenUsdt;
DrizzleUsdt.contractName = "DrizzleUsdt";

const DrizzleUsdc =
    process.env.REACT_APP_BS_NETWORK_NAME === "localhost"
        ? MainnetStableUsdc
        : MockTestnetTokenUsdc;
DrizzleUsdc.contractName = "DrizzleUsdc";

const DrizzleDai =
    process.env.REACT_APP_BS_NETWORK_NAME === "localhost" ? MainnetStableDai : MockTestnetTokenDai;
DrizzleDai.contractName = "DrizzleDai";

const DrizzleShareTokenAaveUsdt =
    process.env.REACT_APP_BS_NETWORK_NAME === "localhost"
        ? MainnetShareTokenAaveUsdt
        : MockTestnetShareTokenAaveUsdt;
DrizzleShareTokenAaveUsdt.contractName = "DrizzleShareTokenAaveUsdt";

const DrizzleShareTokenAaveUsdc =
    process.env.REACT_APP_BS_NETWORK_NAME === "localhost"
        ? MainnetShareTokenAaveUsdc
        : MockTestnetShareTokenAaveUsdc;
DrizzleShareTokenAaveUsdc.contractName = "DrizzleShareTokenAaveUsdc";

const DrizzleShareTokenAaveDai =
    process.env.REACT_APP_BS_NETWORK_NAME === "localhost"
        ? MainnetShareTokenAaveDai
        : MockTestnetShareTokenAaveDai;
DrizzleShareTokenAaveDai.contractName = "DrizzleShareTokenAaveDai";

const DrizzleShareTokenCompoundUsdt =
    process.env.REACT_APP_BS_NETWORK_NAME === "localhost"
        ? MainnetShareTokenCompoundUsdt
        : MockTestnetShareTokenCompoundUsdt;
DrizzleShareTokenCompoundUsdt.contractName = "DrizzleShareTokenCompoundUsdt";

const DrizzleShareTokenCompoundUsdc =
    process.env.REACT_APP_BS_NETWORK_NAME === "localhost"
        ? MainnetShareTokenCompoundUsdc
        : MockTestnetShareTokenCompoundUsdc;
DrizzleShareTokenCompoundUsdc.contractName = "DrizzleShareTokenCompoundUsdc";

const DrizzleShareTokenCompoundDai =
    process.env.REACT_APP_BS_NETWORK_NAME === "localhost"
        ? MainnetShareTokenCompoundDai
        : MockTestnetShareTokenCompoundDai;
DrizzleShareTokenCompoundDai.contractName = "DrizzleShareTokenCompoundDai";

StrategyAaveUsdt.contractName = "DrizzleStrategyAaveUsdt";
MockTestnetStrategyAaveUsdt.contractName = "DrizzleStrategyAaveUsdt";
const DrizzleStrategyAaveUsdt =
    process.env.REACT_APP_BS_NETWORK_NAME === "localhost"
        ? StrategyAaveUsdt
        : MockTestnetStrategyAaveUsdt;

StrategyAaveUsdc.contractName = "DrizzleStrategyAaveUsdc";
MockTestnetStrategyAaveUsdc.contractName = "DrizzleStrategyAaveUsdc";
const DrizzleStrategyAaveUsdc =
    process.env.REACT_APP_BS_NETWORK_NAME === "localhost"
        ? StrategyAaveUsdc
        : MockTestnetStrategyAaveUsdc;

StrategyAaveDai.contractName = "DrizzleStrategyAaveDai";
MockTestnetStrategyAaveDai.contractName = "DrizzleStrategyAaveDai";
const DrizzleStrategyAaveDai =
    process.env.REACT_APP_BS_NETWORK_NAME === "localhost"
        ? StrategyAaveDai
        : MockTestnetStrategyAaveDai;

StrategyCompoundUsdt.contractName = "DrizzleStrategyCompoundUsdt";
MockTestnetStrategyCompoundUsdt.contractName = "DrizzleStrategyCompoundUsdt";
const DrizzleStrategyCompoundUsdt =
    process.env.REACT_APP_BS_NETWORK_NAME === "localhost"
        ? StrategyCompoundUsdt
        : MockTestnetStrategyCompoundUsdt;

StrategyCompoundUsdc.contractName = "DrizzleStrategyCompoundUsdc";
MockTestnetStrategyCompoundUsdc.contractName = "DrizzleStrategyCompoundUsdc";
const DrizzleStrategyCompoundUsdc =
    process.env.REACT_APP_BS_NETWORK_NAME === "localhost"
        ? StrategyCompoundUsdc
        : MockTestnetStrategyCompoundUsdc;

StrategyCompoundDai.contractName = "DrizzleStrategyCompoundDai";
MockTestnetStrategyCompoundDai.contractName = "DrizzleStrategyCompoundDai";
const DrizzleStrategyCompoundDai =
    process.env.REACT_APP_BS_NETWORK_NAME === "localhost"
        ? StrategyCompoundDai
        : MockTestnetStrategyCompoundDai;

if (process.env.REACT_APP_ITF_ENABLED === "true") {
    options = {
        web3: {
            fallback: {
                type: "ws",
                url: "ws://127.0.0.1:8545",
            },
        },

        contracts: [
            CockpitDataProvider,
            MiltonFacadeDataProvider,
            IporOracleFacadeDataProvider,
            MiltonStorageUsdt,
            MiltonStorageUsdc,
            MiltonStorageDai,
            IpTokenUsdt,
            IpTokenUsdc,
            IpTokenDai,
            IvTokenUsdt,
            IvTokenUsdc,
            IvTokenDai,
            MiltonSpreadModel,
            ItfIporOracle,
            ItfMiltonUsdt,
            ItfMiltonUsdc,
            ItfMiltonDai,
            ItfJosephUsdt,
            ItfJosephUsdc,
            ItfJosephDai,
            ItfStanleyUsdt,
            ItfStanleyUsdc,
            ItfStanleyDai,
            TestnetFaucet,
            DrizzleUsdt,
            DrizzleUsdc,
            DrizzleDai,
            DrizzleShareTokenAaveUsdt,
            DrizzleShareTokenAaveUsdc,
            DrizzleShareTokenAaveDai,
            DrizzleShareTokenCompoundUsdt,
            DrizzleShareTokenCompoundUsdc,
            DrizzleShareTokenCompoundDai,
            DrizzleStrategyAaveUsdt,
            DrizzleStrategyAaveUsdc,
            DrizzleStrategyAaveDai,
            DrizzleStrategyCompoundUsdt,
            DrizzleStrategyCompoundUsdc,
            DrizzleStrategyCompoundDai,
        ],
    };
} else {
    options = {
        web3: web3,
        //  {
        //     fallback: {
        //         type: "ws",
        //         url: "ws://127.0.0.1:7545",
        //     },
        // },

        contracts: [
            CockpitDataProvider,
            MiltonFacadeDataProvider,
            IporOracleFacadeDataProvider,
            IporOracle,
            MiltonUsdt,
            MiltonUsdc,
            MiltonDai,
            MiltonStorageUsdt,
            MiltonStorageUsdc,
            MiltonStorageDai,
            DrizzleUsdt,
            DrizzleUsdc,
            DrizzleDai,
            IpTokenUsdt,
            IpTokenUsdc,
            IpTokenDai,
            IvTokenUsdt,
            IvTokenUsdc,
            IvTokenDai,
            JosephUsdt,
            JosephUsdc,
            JosephDai,
            StanleyUsdt,
            StanleyUsdc,
            StanleyDai,
            MiltonSpreadModel,
            // TestnetFaucet,
            DrizzleShareTokenAaveUsdt,
            DrizzleShareTokenAaveUsdc,
            DrizzleShareTokenAaveDai,
            DrizzleShareTokenCompoundUsdt,
            DrizzleShareTokenCompoundUsdc,
            DrizzleShareTokenCompoundDai,
            DrizzleStrategyAaveUsdt,
            DrizzleStrategyAaveUsdc,
            DrizzleStrategyAaveDai,
            DrizzleStrategyCompoundUsdt,
            DrizzleStrategyCompoundUsdc,
            DrizzleStrategyCompoundDai,
        ],
    };
}

export default options;
