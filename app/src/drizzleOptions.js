import Migrations from "./contracts/Migrations.json";
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

import StrategyAaveUsdt from "./contracts/StrategyAaveUsdt.json";
import StrategyAaveUsdc from "./contracts/StrategyAaveUsdc.json";
import StrategyAaveDai from "./contracts/StrategyAaveDai.json";

import StrategyCompoundUsdt from "./contracts/StrategyCompoundUsdt.json";
import StrategyCompoundUsdc from "./contracts/StrategyCompoundUsdc.json";
import StrategyCompoundDai from "./contracts/StrategyCompoundDai.json";

import MockTestnetStrategyAaveUsdt from "./contracts/MockTestnetStrategyAaveUsdt.json";
import MockTestnetStrategyAaveUsdc from "./contracts/MockTestnetStrategyAaveUsdc.json";
import MockTestnetStrategyAaveDai from "./contracts/MockTestnetStrategyAaveDai.json";

import MockTestnetStrategyCompoundUsdt from "./contracts/MockTestnetStrategyCompoundUsdt.json";
import MockTestnetStrategyCompoundUsdc from "./contracts/MockTestnetStrategyCompoundUsdc.json";
import MockTestnetStrategyCompoundDai from "./contracts/MockTestnetStrategyCompoundDai.json";

require("dotenv").config({ path: "../../.env" });

let DrizzleStrategyAaveUsdt;
let DrizzleStrategyAaveUsdc;
let DrizzleStrategyAaveDai;

let DrizzleStrategyCompoundUsdt;
let DrizzleStrategyCompoundUsdc;
let DrizzleStrategyCompoundDai;

if (process.env.REACT_APP_ENV_PROFILE === "ipor.io") {
	//Mainnet
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

DrizzleStrategyAaveUsdt.contractName = "DrizzleStrategyAaveUsdt";
DrizzleStrategyAaveUsdc.contractName = "DrizzleStrategyAaveUsdc";
DrizzleStrategyAaveDai.contractName = "DrizzleStrategyAaveDai";

DrizzleStrategyCompoundUsdt.contractName = "DrizzleStrategyCompoundUsdt";
DrizzleStrategyCompoundUsdc.contractName = "DrizzleStrategyCompoundUsdc";
DrizzleStrategyCompoundDai.contractName = "DrizzleStrategyCompoundDai";

let options = null;

if (process.env.REACT_APP_ITF_ENABLED === "true") {
    options = {
        web3: {
            fallback: {
                type: "ws",
                url: "ws://127.0.0.1:7545",
            },
        },

        contracts: [
            Migrations,
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
            MockTestnetTokenDai,
            MockTestnetTokenUsdt,
            MockTestnetTokenUsdc,
            MockTestnetShareTokenAaveUsdt,
            MockTestnetShareTokenAaveUsdc,
            MockTestnetShareTokenAaveDai,
            MockTestnetShareTokenCompoundUsdt,
            MockTestnetShareTokenCompoundUsdc,
            MockTestnetShareTokenCompoundDai,
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
        web3: {
            fallback: {
                type: "ws",
                url: "ws://127.0.0.1:7545",
            },
        },

        contracts: [
            Migrations,
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
            MockTestnetTokenDai,
            MockTestnetTokenUsdt,
            MockTestnetTokenUsdc,
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
            TestnetFaucet,
            MockTestnetShareTokenAaveUsdt,
            MockTestnetShareTokenAaveUsdc,
            MockTestnetShareTokenAaveDai,
            MockTestnetShareTokenCompoundUsdt,
            MockTestnetShareTokenCompoundUsdc,
            MockTestnetShareTokenCompoundDai,
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
