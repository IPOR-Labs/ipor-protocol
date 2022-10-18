import Migrations from "./contracts/Migrations.json";

import IpTokenUsdt from "./contracts/IpTokenUsdt.json";
import IpTokenUsdc from "./contracts/IpTokenUsdc.json";
import IpTokenDai from "./contracts/IpTokenDai.json";
import IpTokenWeth from "./contracts/IpTokenWeth.json";

import IvTokenUsdt from "./contracts/IvTokenUsdt.json";
import IvTokenUsdc from "./contracts/IvTokenUsdc.json";
import IvTokenDai from "./contracts/IvTokenDai.json";

import MiltonSpreadModelUsdt from "./contracts/MiltonSpreadModelUsdt.json";
import MiltonSpreadModelUsdc from "./contracts/MiltonSpreadModelUsdc.json";
import MiltonSpreadModelDai from "./contracts/MiltonSpreadModelDai.json";
import MiltonSpreadModelWeth from "./contracts/MiltonSpreadModelWeth.json";
import IporOracle from "./contracts/IporOracle.json";

import MiltonStorageUsdt from "./contracts/MiltonStorageUsdt.json";
import MiltonStorageUsdc from "./contracts/MiltonStorageUsdc.json";
import MiltonStorageDai from "./contracts/MiltonStorageDai.json";
import MiltonStorageWeth from "./contracts/MiltonStorageWeth.json";

import MiltonUsdt from "./contracts/MiltonUsdt.json";
import MiltonUsdc from "./contracts/MiltonUsdc.json";
import MiltonDai from "./contracts/MiltonDai.json";

import JosephUsdt from "./contracts/JosephUsdt.json";
import JosephUsdc from "./contracts/JosephUsdc.json";
import JosephDai from "./contracts/JosephDai.json";

import StanleyUsdt from "./contracts/StanleyUsdt.json";
import StanleyUsdc from "./contracts/StanleyUsdc.json";
import StanleyDai from "./contracts/StanleyDai.json";

import CockpitDataProvider from "./contracts/CockpitDataProvider.json";
import MiltonFacadeDataProvider from "./contracts/MiltonFacadeDataProvider.json";
import IporOracleFacadeDataProvider from "./contracts/IporOracleFacadeDataProvider.json";

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
import MockTestnetTokenWeth from "./contracts/MockTestnetTokenWeth.json";

import StrategyAaveUsdt from "./contracts/StrategyAaveUsdt.json";
import StrategyAaveUsdc from "./contracts/StrategyAaveUsdc.json";
import StrategyAaveDai from "./contracts/StrategyAaveDai.json";

import MockTestnetStrategyAaveUsdt from "./contracts/MockTestnetStrategyAaveUsdt.json";
import MockTestnetStrategyAaveUsdc from "./contracts/MockTestnetStrategyAaveUsdc.json";
import MockTestnetStrategyAaveDai from "./contracts/MockTestnetStrategyAaveDai.json";

import StrategyCompoundUsdt from "./contracts/StrategyCompoundUsdt.json";
import StrategyCompoundUsdc from "./contracts/StrategyCompoundUsdc.json";
import StrategyCompoundDai from "./contracts/StrategyCompoundDai.json";

import MockTestnetStrategyCompoundUsdt from "./contracts/MockTestnetStrategyCompoundUsdt.json";
import MockTestnetStrategyCompoundUsdc from "./contracts/MockTestnetStrategyCompoundUsdc.json";
import MockTestnetStrategyCompoundDai from "./contracts/MockTestnetStrategyCompoundDai.json";

require("dotenv").config({path: "../../.env"});

const Web3 = require("web3");
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545")); //Web3.givenProvider || "ws://127.0.0.1:8545");
web3.fallback = {
    type: "ws",
    url: "ws://127.0.0.1:8545",
};

const networkId = process.env.REACT_APP_ETH_BC_NETWORK_ID;
const addresses = require("./" + process.env.REACT_APP_ENV_PROFILE + "-docker-ipor-addresses.json");

const DrizzleUsdt = MockTestnetTokenUsdt;
const DrizzleUsdc = MockTestnetTokenUsdc;
const DrizzleDai = MockTestnetTokenDai;
const DrizzleWeth = MockTestnetTokenWeth;

let DrizzleIporOracle;
let DrizzleMiltonUsdt;
let DrizzleMiltonUsdc;
let DrizzleMiltonDai;
let DrizzleJosephUsdt;
let DrizzleJosephUsdc;
let DrizzleJosephDai;
let DrizzleStanleyUsdt;
let DrizzleStanleyUsdc;
let DrizzleStanleyDai;

const DrizzleShareTokenAaveUsdt = MockTestnetShareTokenAaveUsdt;
const DrizzleShareTokenAaveUsdc = MockTestnetShareTokenAaveUsdc;
const DrizzleShareTokenAaveDai = MockTestnetShareTokenAaveDai;
const DrizzleShareTokenCompoundUsdt = MockTestnetShareTokenCompoundUsdt;
const DrizzleShareTokenCompoundUsdc = MockTestnetShareTokenCompoundUsdc;
const DrizzleShareTokenCompoundDai = MockTestnetShareTokenCompoundDai;

let DrizzleStrategyAaveUsdt;
let DrizzleStrategyAaveUsdc;
let DrizzleStrategyAaveDai;
let DrizzleStrategyCompoundUsdt;
let DrizzleStrategyCompoundUsdc;
let DrizzleStrategyCompoundDai;

if (process.env.REACT_APP_ENV_PROFILE === "mainnet.ipor.io") {
    //Mainnet

    DrizzleUsdt.networks[networkId] = {address: addresses.USDT};
    DrizzleUsdc.networks[networkId] = {address: addresses.USDC};
    DrizzleDai.networks[networkId] = {address: addresses.DAI};
    DrizzleWeth.networks[networkId] = {address: addresses.WETH};
    DrizzleShareTokenAaveUsdt.networks[networkId] = {address: addresses.aUSDT};
    DrizzleShareTokenAaveUsdc.networks[networkId] = {address: addresses.aUSDC};
    DrizzleShareTokenAaveDai.networks[networkId] = {address: addresses.aDAI};
    DrizzleShareTokenCompoundUsdt.networks[networkId] = {address: addresses.cUSDT};
    DrizzleShareTokenCompoundUsdc.networks[networkId] = {address: addresses.cUSDC};
    DrizzleShareTokenCompoundDai.networks[networkId] = {address: addresses.cDAI};

    DrizzleStrategyAaveUsdt = StrategyAaveUsdt;
    DrizzleStrategyAaveUsdc = StrategyAaveUsdc;
    DrizzleStrategyAaveDai = StrategyAaveDai;

    DrizzleStrategyCompoundUsdt = StrategyCompoundUsdt;
    DrizzleStrategyCompoundUsdc = StrategyCompoundUsdc;
    DrizzleStrategyCompoundDai = StrategyCompoundDai;
} else {
    //Other than Mainnet
    DrizzleStrategyAaveUsdt = MockTestnetStrategyAaveUsdt;
    DrizzleStrategyAaveUsdc = MockTestnetStrategyAaveUsdc;
    DrizzleStrategyAaveDai = MockTestnetStrategyAaveDai;

    DrizzleStrategyCompoundUsdt = MockTestnetStrategyCompoundUsdt;
    DrizzleStrategyCompoundUsdc = MockTestnetStrategyCompoundUsdc;
    DrizzleStrategyCompoundDai = MockTestnetStrategyCompoundDai;
}

if (process.env.REACT_APP_ITF_ENABLED === "true") {
    DrizzleIporOracle = ItfIporOracle;
    DrizzleMiltonUsdt = ItfMiltonUsdt;
    DrizzleMiltonUsdc = ItfMiltonUsdc;
    DrizzleMiltonDai = ItfMiltonDai;
    DrizzleJosephUsdt = ItfJosephUsdt;
    DrizzleJosephUsdc = ItfJosephUsdc;
    DrizzleJosephDai = ItfJosephDai;
    DrizzleStanleyUsdt = ItfStanleyUsdt;
    DrizzleStanleyUsdc = ItfStanleyUsdc;
    DrizzleStanleyDai = ItfStanleyDai;
} else {
    DrizzleIporOracle = IporOracle;
    DrizzleMiltonUsdt = MiltonUsdt;
    DrizzleMiltonUsdc = MiltonUsdc;
    DrizzleMiltonDai = MiltonDai;
    DrizzleJosephUsdt = JosephUsdt;
    DrizzleJosephUsdc = JosephUsdc;
    DrizzleJosephDai = JosephDai;

    DrizzleStanleyUsdt = StanleyUsdt;
    DrizzleStanleyUsdc = StanleyUsdc;
    DrizzleStanleyDai = StanleyDai;
}

DrizzleUsdt.contractName = "DrizzleUsdt";
DrizzleUsdc.contractName = "DrizzleUsdc";
DrizzleDai.contractName = "DrizzleDai";
DrizzleWeth.contractName = "DrizzleWeth";

DrizzleIporOracle.contractName = "DrizzleIporOracle";
DrizzleMiltonUsdt.contractName = "DrizzleMiltonUsdt";
DrizzleMiltonUsdc.contractName = "DrizzleMiltonUsdc";
DrizzleMiltonDai.contractName = "DrizzleMiltonDai";
DrizzleJosephUsdt.contractName = "DrizzleJosephUsdt";
DrizzleJosephUsdc.contractName = "DrizzleJosephUsdc";
DrizzleJosephDai.contractName = "DrizzleJosephDai";
DrizzleStanleyUsdt.contractName = "DrizzleStanleyUsdt";
DrizzleStanleyUsdc.contractName = "DrizzleStanleyUsdc";
DrizzleStanleyDai.contractName = "DrizzleStanleyDai";

DrizzleShareTokenAaveUsdt.contractName = "DrizzleShareTokenAaveUsdt";
DrizzleShareTokenAaveUsdc.contractName = "DrizzleShareTokenAaveUsdc";
DrizzleShareTokenAaveDai.contractName = "DrizzleShareTokenAaveDai";
DrizzleShareTokenCompoundUsdt.contractName = "DrizzleShareTokenCompoundUsdt";
DrizzleShareTokenCompoundUsdc.contractName = "DrizzleShareTokenCompoundUsdc";
DrizzleShareTokenCompoundDai.contractName = "DrizzleShareTokenCompoundDai";

DrizzleStrategyAaveUsdt.contractName = "DrizzleStrategyAaveUsdt";
DrizzleStrategyAaveUsdc.contractName = "DrizzleStrategyAaveUsdc";
DrizzleStrategyAaveDai.contractName = "DrizzleStrategyAaveDai";

DrizzleStrategyCompoundUsdt.contractName = "DrizzleStrategyCompoundUsdt";
DrizzleStrategyCompoundUsdc.contractName = "DrizzleStrategyCompoundUsdc";
DrizzleStrategyCompoundDai.contractName = "DrizzleStrategyCompoundDai";

let options = {
    web3: web3,
    contracts: [
        Migrations,

        DrizzleUsdt,
        DrizzleUsdc,
        DrizzleDai,
        DrizzleWeth,

        IpTokenUsdt,
        IpTokenUsdc,
        IpTokenDai,
        IpTokenWeth,
        IvTokenUsdt,
        IvTokenUsdc,
        IvTokenDai,

        MiltonSpreadModelUsdt,
        MiltonSpreadModelUsdc,
        MiltonSpreadModelDai,
        MiltonSpreadModelWeth,
        DrizzleIporOracle,

        MiltonStorageUsdt,
        MiltonStorageUsdc,
        MiltonStorageDai,
        MiltonStorageWeth,

        DrizzleMiltonUsdt,
        DrizzleMiltonUsdc,
        DrizzleMiltonDai,
        DrizzleJosephUsdt,
        DrizzleJosephUsdc,
        DrizzleJosephDai,
        DrizzleStanleyUsdt,
        DrizzleStanleyUsdc,
        DrizzleStanleyDai,

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

        CockpitDataProvider,
        MiltonFacadeDataProvider,
        IporOracleFacadeDataProvider,
    ],
};

if (process.env.REACT_APP_ENV_PROFILE !== "mainnet.ipor.io") {
    options.contracts.push(TestnetFaucet);
}

export default options;
