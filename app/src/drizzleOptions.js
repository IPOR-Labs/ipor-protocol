import Migrations from "./contracts/Migrations.json";

import IporToken from "./contracts/IporToken.json";
import MockTestnetTokenUsdt from "./contracts/MockTestnetTokenUsdt.json";
import MockTestnetTokenUsdc from "./contracts/MockTestnetTokenUsdc.json";
import MockTestnetTokenDai from "./contracts/MockTestnetTokenDai.json";

import IpTokenUsdt from "./contracts/IpTokenUsdt.json";
import IpTokenUsdc from "./contracts/IpTokenUsdc.json";
import IpTokenDai from "./contracts/IpTokenDai.json";

import IvTokenUsdt from "./contracts/IvTokenUsdt.json";
import IvTokenUsdc from "./contracts/IvTokenUsdc.json";
import IvTokenDai from "./contracts/IvTokenDai.json";

import IporOracle from "./contracts/IporOracle.json";

import MiltonSpreadModelUsdt from "./contracts/MiltonSpreadModelUsdt.json";
import MiltonSpreadModelUsdc from "./contracts/MiltonSpreadModelUsdc.json";
import MiltonSpreadModelDai from "./contracts/MiltonSpreadModelDai.json";

import MiltonStorageUsdt from "./contracts/MiltonStorageUsdt.json";
import MiltonStorageUsdc from "./contracts/MiltonStorageUsdc.json";
import MiltonStorageDai from "./contracts/MiltonStorageDai.json";

import MiltonUsdt from "./contracts/MiltonUsdt.json";
import MiltonUsdc from "./contracts/MiltonUsdc.json";
import MiltonDai from "./contracts/MiltonDai.json";

import JosephUsdt from "./contracts/JosephUsdt.json";
import JosephUsdc from "./contracts/JosephUsdc.json";
import JosephDai from "./contracts/JosephDai.json";

import StanleyUsdt from "./contracts/StanleyUsdt.json";
import StanleyUsdc from "./contracts/StanleyUsdc.json";
import StanleyDai from "./contracts/StanleyDai.json";

import StrategyAaveUsdt from "./contracts/StrategyAaveUsdt.json";
import StrategyAaveUsdc from "./contracts/StrategyAaveUsdc.json";
import StrategyAaveDai from "./contracts/StrategyAaveDai.json";

import StrategyCompoundUsdt from "./contracts/StrategyCompoundUsdt.json";
import StrategyCompoundUsdc from "./contracts/StrategyCompoundUsdc.json";
import StrategyCompoundDai from "./contracts/StrategyCompoundDai.json";

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

require("dotenv").config({ path: "../../.env" });

const Web3 = require("web3");
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545")); //Web3.givenProvider || "ws://127.0.0.1:8545");
web3.fallback = {
    type: "ws",
    url: "ws://127.0.0.1:8545",
};

const networkId = process.env.REACT_APP_ETH_BC_NETWORK_ID;
const addresses = require("./" + process.env.REACT_APP_ENV_PROFILE + "-docker-ipor-addresses.json");

const DrizzleIporToken = IporToken;
DrizzleIporToken.contractName = "DrizzleIporToken";
DrizzleIporToken.networks[networkId] = { address: addresses.IPOR };

const DrizzleUsdt = MockTestnetTokenUsdt;
DrizzleUsdt.contractName = "DrizzleUsdt";
DrizzleUsdt.networks[networkId] = { address: addresses.USDT };

const DrizzleUsdc = MockTestnetTokenUsdc;
DrizzleUsdc.contractName = "DrizzleUsdc";
DrizzleUsdc.networks[networkId] = { address: addresses.USDC };

const DrizzleDai = MockTestnetTokenDai;
DrizzleDai.contractName = "DrizzleDai";
DrizzleDai.networks[networkId] = { address: addresses.DAI };

IpTokenUsdt.networks[networkId] = { address: addresses.ipUSDT };
IpTokenUsdc.networks[networkId] = { address: addresses.ipUSDC };
IpTokenDai.networks[networkId] = { address: addresses.ipDAI };

IvTokenUsdt.networks[networkId] = { address: addresses.ivUSDT };
IvTokenUsdc.networks[networkId] = { address: addresses.ivUSDC };
IvTokenDai.networks[networkId] = { address: addresses.ivDAI };

MiltonSpreadModelUsdt.networks[networkId] = { address: addresses.MiltonSpreadModelUsdt };
MiltonSpreadModelUsdc.networks[networkId] = { address: addresses.MiltonSpreadModelUsdc };
MiltonSpreadModelDai.networks[networkId] = { address: addresses.MiltonSpreadModelDai };

MiltonStorageUsdt.networks[networkId] = { address: addresses.MiltonStorageProxyUsdt };
MiltonStorageUsdc.networks[networkId] = { address: addresses.MiltonStorageProxyUsdc };
MiltonStorageDai.networks[networkId] = { address: addresses.MiltonStorageProxyDai };

CockpitDataProvider.networks[networkId] = { address: addresses.CockpitDataProviderProxy };
MiltonFacadeDataProvider.networks[networkId] = { address: addresses.MiltonFacadeDataProviderProxy };
IporOracleFacadeDataProvider.networks[networkId] = {
    address: addresses.IporOracleFacadeDataProviderProxy,
};

const DrizzleShareTokenAaveUsdt = MockTestnetShareTokenAaveUsdt;
DrizzleShareTokenAaveUsdt.contractName = "DrizzleShareTokenAaveUsdt";
DrizzleShareTokenAaveUsdt.networks[networkId] = { address: addresses.aUSDT };

const DrizzleShareTokenAaveUsdc = MockTestnetShareTokenAaveUsdc;
DrizzleShareTokenAaveUsdc.contractName = "DrizzleShareTokenAaveUsdc";
DrizzleShareTokenAaveUsdc.networks[networkId] = { address: addresses.aUSDC };

const DrizzleShareTokenAaveDai = MockTestnetShareTokenAaveDai;
DrizzleShareTokenAaveDai.contractName = "DrizzleShareTokenAaveDai";
DrizzleShareTokenAaveDai.networks[networkId] = { address: addresses.aDAI };

const DrizzleShareTokenCompoundUsdt = MockTestnetShareTokenCompoundUsdt;
DrizzleShareTokenCompoundUsdt.contractName = "DrizzleShareTokenCompoundUsdt";
DrizzleShareTokenCompoundUsdt.networks[networkId] = { address: addresses.cUSDT };

const DrizzleShareTokenCompoundUsdc = MockTestnetShareTokenCompoundUsdc;
DrizzleShareTokenCompoundUsdc.contractName = "DrizzleShareTokenCompoundUsdc";
DrizzleShareTokenCompoundUsdc.networks[networkId] = { address: addresses.cUSDC };

const DrizzleShareTokenCompoundDai = MockTestnetShareTokenCompoundDai;
DrizzleShareTokenCompoundDai.contractName = "DrizzleShareTokenCompoundDai";
DrizzleShareTokenCompoundDai.networks[networkId] = { address: addresses.cDAI };

StrategyAaveUsdt.networks[networkId] = { address: addresses.AaveStrategyProxyUsdt };
StrategyAaveUsdc.networks[networkId] = { address: addresses.AaveStrategyProxyUsdc };
StrategyAaveDai.networks[networkId] = { address: addresses.AaveStrategyProxyDai };
StrategyCompoundUsdt.networks[networkId] = { address: addresses.CompoundStrategyProxyUsdt };
StrategyCompoundUsdc.networks[networkId] = { address: addresses.CompoundStrategyProxyUsdc };
StrategyCompoundDai.networks[networkId] = { address: addresses.CompoundStrategyProxyDai };

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

if (process.env.REACT_APP_ITF_ENABLED === "true") {
    DrizzleIporOracle = ItfIporOracle;
    DrizzleIporOracle.networks[networkId] = { address: addresses.ItfIporOracleProxy };

    DrizzleMiltonUsdt = ItfMiltonUsdt;
    DrizzleMiltonUsdt.networks[networkId] = { address: addresses.ItfMiltonProxyUsdt };

    DrizzleMiltonUsdc = ItfMiltonUsdc;
    DrizzleMiltonUsdc.networks[networkId] = { address: addresses.ItfMiltonProxyUsdc };

    DrizzleMiltonDai = ItfMiltonDai;
    DrizzleMiltonDai.networks[networkId] = { address: addresses.ItfMiltonProxyDai };

    DrizzleJosephUsdt = ItfJosephUsdt;
    DrizzleJosephUsdt.networks[networkId] = { address: addresses.ItfJosephProxyUsdt };

    DrizzleJosephUsdc = ItfJosephUsdc;
    DrizzleJosephUsdc.networks[networkId] = { address: addresses.ItfJosephProxyUsdc };

    DrizzleJosephDai = ItfJosephDai;
    DrizzleJosephDai.networks[networkId] = { address: addresses.ItfJosephProxyDai };

    DrizzleStanleyUsdt = ItfStanleyUsdt;
    DrizzleStanleyUsdt.networks[networkId] = { address: addresses.ItfStanleyProxyUsdt };

    DrizzleStanleyUsdc = ItfStanleyUsdc;
    DrizzleStanleyUsdc.networks[networkId] = { address: addresses.ItfStanleyProxyUsdc };

    DrizzleStanleyDai = ItfStanleyDai;
    DrizzleStanleyDai.networks[networkId] = { address: addresses.StanleyProxyDai };
} else {
    DrizzleIporOracle = IporOracle;
    DrizzleIporOracle.networks[networkId] = { address: addresses.IporOracleProxy };

    DrizzleMiltonUsdt = MiltonUsdt;
    DrizzleMiltonUsdt.networks[networkId] = { address: addresses.MiltonProxyUsdt };

    DrizzleMiltonUsdc = MiltonUsdc;
    DrizzleMiltonUsdc.networks[networkId] = { address: addresses.MiltonProxyUsdc };

    DrizzleMiltonDai = MiltonDai;
    DrizzleMiltonDai.networks[networkId] = { address: addresses.MiltonProxyDai };

    DrizzleJosephUsdt = JosephUsdt;
    DrizzleJosephUsdt.networks[networkId] = { address: addresses.JosephProxyUsdt };

    DrizzleJosephUsdc = JosephUsdc;
    DrizzleJosephUsdc.networks[networkId] = { address: addresses.JosephProxyUsdc };

    DrizzleJosephDai = JosephDai;
    DrizzleJosephDai.networks[networkId] = { address: addresses.JosephProxyDai };

    DrizzleStanleyUsdt = StanleyUsdt;
    DrizzleStanleyUsdt.networks[networkId] = { address: addresses.StanleyProxyUsdt };

    DrizzleStanleyUsdc = StanleyUsdc;
    DrizzleStanleyUsdc.networks[networkId] = { address: addresses.StanleyProxyUsdc };

    DrizzleStanleyDai = StanleyDai;
    DrizzleStanleyDai.networks[networkId] = { address: addresses.StanleyProxyDai };
}

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

let options = {
    web3: web3,
    contracts: [
        Migrations,

        DrizzleIporToken,

        DrizzleUsdt,
        DrizzleUsdc,
        DrizzleDai,

        IpTokenUsdt,
        IpTokenUsdc,
        IpTokenDai,
        IvTokenUsdt,
        IvTokenUsdc,
        IvTokenDai,

        MiltonSpreadModelUsdt,
        MiltonSpreadModelUsdc,
        MiltonSpreadModelDai,

        MiltonStorageUsdt,
        MiltonStorageUsdc,
        MiltonStorageDai,

        DrizzleIporOracle,
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

        StrategyAaveUsdt,
        StrategyAaveUsdc,
        StrategyAaveDai,

        StrategyCompoundUsdt,
        StrategyCompoundUsdc,
        StrategyCompoundDai,

        CockpitDataProvider,
        MiltonFacadeDataProvider,
        IporOracleFacadeDataProvider,
    ],
};

if (process.env.REACT_APP_ENV_PROFILE !== "mainnet.ipor.io") {
    options.contracts.push(TestnetFaucet);
}

export default options;
