import IporOracle from "./contracts/IporOracle.json";
import ItfIporOracle from "./contracts/ItfIporOracle.json";
import MiltonUsdt from "./contracts/MiltonUsdt.json";
import MiltonUsdc from "./contracts/MiltonUsdc.json";
import MiltonDai from "./contracts/MiltonDai.json";
import ItfMiltonUsdt from "./contracts/ItfMiltonUsdt.json";
import ItfMiltonUsdc from "./contracts/ItfMiltonUsdc.json";
import ItfMiltonDai from "./contracts/ItfMiltonDai.json";
import MiltonStorageUsdt from "./contracts/MiltonStorageUsdt.json";
import MiltonStorageUsdc from "./contracts/MiltonStorageUsdc.json";
import MiltonStorageDai from "./contracts/MiltonStorageDai.json";
import TestnetFaucet from "./contracts/TestnetFaucet.json";
import DaiMockedToken from "./contracts/DaiMockedToken.json";
import UsdcMockedToken from "./contracts/UsdcMockedToken.json";
import UsdtMockedToken from "./contracts/UsdtMockedToken.json";
import IpTokenUsdt from "./contracts/IpTokenUsdt.json";
import IpTokenUsdc from "./contracts/IpTokenUsdc.json";
import IpTokenDai from "./contracts/IpTokenDai.json";
import IvTokenUsdt from "./contracts/IvTokenUsdt.json";
import IvTokenUsdc from "./contracts/IvTokenUsdc.json";
import IvTokenDai from "./contracts/IvTokenDai.json";
import MockAUsdt from "./contracts/MockAUsdt.json";
import MockAUsdc from "./contracts/MockAUsdc.json";
import MockADai from "./contracts/MockADai.json";
import MockCUSDC from "./contracts/MockCUSDC.json";
import MockCUSDT from "./contracts/MockCUSDT.json";
import MockCDai from "./contracts/MockCDai.json";

import MiltonSpreadModel from "./contracts/MiltonSpreadModel.json";
import CockpitDataProvider from "./contracts/CockpitDataProvider.json";
import MiltonFacadeDataProvider from "./contracts/MiltonFacadeDataProvider.json";
import JosephUsdt from "./contracts/JosephUsdt.json";
import JosephUsdc from "./contracts/JosephUsdc.json";
import JosephDai from "./contracts/JosephDai.json";
import ItfJosephUsdt from "./contracts/ItfJosephUsdt.json";
import ItfJosephUsdc from "./contracts/ItfJosephUsdc.json";
import ItfJosephDai from "./contracts/ItfJosephDai.json";
import ItfStanleyUsdt from "./contracts/ItfStanleyUsdt.json";
import ItfStanleyUsdc from "./contracts/ItfStanleyUsdc.json";
import ItfStanleyDai from "./contracts/ItfStanleyDai.json";
import StanleyUsdt from "./contracts/StanleyUsdt.json";
import StanleyUsdc from "./contracts/StanleyUsdc.json";
import StanleyDai from "./contracts/StanleyDai.json";
import StrategyAaveUsdt from "./contracts/StrategyAaveUsdt.json";
import StrategyAaveUsdc from "./contracts/StrategyAaveUsdc.json";
import StrategyAaveDai from "./contracts/StrategyAaveDai.json";
import StrategyCompoundUsdt from "./contracts/StrategyCompoundUsdt.json";
import StrategyCompoundUsdc from "./contracts/StrategyCompoundUsdc.json";
import StrategyCompoundDai from "./contracts/StrategyCompoundDai.json";

require("dotenv").config({ path: "../../.env" });

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
            CockpitDataProvider,
            MiltonFacadeDataProvider,
            ItfIporOracle,
            ItfMiltonUsdt,
            ItfMiltonUsdc,
            ItfMiltonDai,
            MiltonStorageUsdt,
            MiltonStorageUsdc,
            MiltonStorageDai,
            DaiMockedToken,
            UsdtMockedToken,
            UsdcMockedToken,
            IpTokenUsdt,
            IpTokenUsdc,
            IpTokenDai,
            IvTokenUsdt,
            IvTokenUsdc,
            IvTokenDai,
            MockAUsdt,
            MockAUsdc,
            MockADai,
            MockCUSDC,
            MockCUSDT,
            MockCDai,
            ItfJosephUsdt,
            ItfJosephUsdc,
            ItfJosephDai,
            ItfStanleyUsdt,
            ItfStanleyUsdc,
            ItfStanleyDai,
            TestnetFaucet,
            MiltonSpreadModel,
            StrategyAaveUsdt,
            StrategyAaveUsdc,
            StrategyAaveDai,
            StrategyCompoundUsdt,
            StrategyCompoundUsdc,
            StrategyCompoundDai,
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
            CockpitDataProvider,
            MiltonFacadeDataProvider,
            IporOracle,
            MiltonUsdt,
            MiltonUsdc,
            MiltonDai,
            MiltonStorageUsdt,
            MiltonStorageUsdc,
            MiltonStorageDai,
            DaiMockedToken,
            UsdtMockedToken,
            UsdcMockedToken,
            IpTokenUsdt,
            IpTokenUsdc,
            IpTokenDai,
            IvTokenUsdt,
            IvTokenUsdc,
            IvTokenDai,
            MockAUsdt,
            MockAUsdc,
            MockADai,
            MockCUSDC,
            MockCUSDT,
            MockCDai,
            JosephUsdt,
            JosephUsdc,
            JosephDai,
            StanleyUsdt,
            StanleyUsdc,
            StanleyDai,
            TestnetFaucet,
            MiltonSpreadModel,
            StrategyAaveUsdt,
            StrategyAaveUsdc,
            StrategyAaveDai,
            StrategyCompoundUsdt,
            StrategyCompoundUsdc,
            StrategyCompoundDai,
        ],
    };
}

export default options;
