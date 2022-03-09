import Warren from "./contracts/Warren.json";
import ItfWarren from "./contracts/ItfWarren.json";
import WarrenDevToolDataProvider from "./contracts/WarrenDevToolDataProvider.json";
import MiltonUsdt from "./contracts/MiltonUsdt.json";
import MiltonUsdc from "./contracts/MiltonUsdc.json";
import MiltonDai from "./contracts/MiltonDai.json";
import ItfMiltonUsdt from "./contracts/ItfMiltonUsdt.json";
import ItfMiltonUsdc from "./contracts/ItfMiltonUsdc.json";
import ItfMiltonDai from "./contracts/ItfMiltonDai.json";
import MiltonStorageUsdt from "./contracts/MiltonStorageUsdt.json";
import MiltonStorageUsdc from "./contracts/MiltonStorageUsdc.json";
import MiltonStorageDai from "./contracts/MiltonStorageDai.json";
import MiltonFaucet from "./contracts/MiltonFaucet.json";
import IporAssetConfigurationUsdt from "./contracts/IporAssetConfigurationUsdt.json";
import IporAssetConfigurationUsdc from "./contracts/IporAssetConfigurationUsdc.json";
import IporAssetConfigurationDai from "./contracts/IporAssetConfigurationDai.json";
import DaiMockedToken from "./contracts/DaiMockedToken.json";
import UsdcMockedToken from "./contracts/UsdcMockedToken.json";
import UsdtMockedToken from "./contracts/UsdtMockedToken.json";
import MiltonSpreadModel from "./contracts/MiltonSpreadModel.json";
import MiltonDevToolDataProvider from "./contracts/MiltonDevToolDataProvider.json";
import MiltonFrontendDataProvider from "./contracts/MiltonFrontendDataProvider.json";
import IporConfiguration from "./contracts/IporConfiguration.json";
import JosephUsdt from "./contracts/JosephUsdt.json";
import JosephUsdc from "./contracts/JosephUsdc.json";
import JosephDai from "./contracts/JosephDai.json";
import ItfJosephUsdt from "./contracts/ItfJosephUsdt.json";
import ItfJosephUsdc from "./contracts/ItfJosephUsdc.json";
import ItfJosephDai from "./contracts/ItfJosephDai.json";
import StanleyUsdt from "./contracts/StanleyUsdt.json";
import StanleyUsdc from "./contracts/StanleyUsdc.json";
import StanleyDai from "./contracts/StanleyDai.json";
import StrategyAaveUsdt from "./contracts/StrategyAaveUsdt.json";
import StrategyAaveUsdc from "./contracts/StrategyAaveUsdc.json";
import StrategyAaveDai from "./contracts/StrategyAaveDai.json";
import StrategyCompoundUsdt from "./contracts/StrategyCompoundUsdt.json";
import StrategyCompoundUsdc from "./contracts/StrategyCompoundUsdc.json";
import StrategyCompoundDai from "./contracts/StrategyCompoundDai.json";
const options = {
    web3: {
        fallback: {
            type: "ws",
            url: "ws://127.0.0.1:7545",
        },
    },

    contracts: [
        MiltonDevToolDataProvider,
        MiltonFrontendDataProvider,
        IporConfiguration,
        Warren,
        ItfWarren,
        WarrenDevToolDataProvider,
        MiltonUsdt,
        MiltonUsdc,
        MiltonDai,
        ItfMiltonUsdt,
        ItfMiltonUsdc,
        ItfMiltonDai,
        MiltonStorageUsdt,
        MiltonStorageUsdc,
        MiltonStorageDai,
        DaiMockedToken,
        UsdtMockedToken,
        UsdcMockedToken,
        JosephUsdt,
        JosephUsdc,
        JosephDai,
        ItfJosephUsdt,
        ItfJosephUsdc,
        ItfJosephDai,
        StanleyUsdt,
        StanleyUsdc,
        StanleyDai,
        MiltonFaucet,
        IporAssetConfigurationDai,
        IporAssetConfigurationUsdt,
        IporAssetConfigurationUsdc,
        MiltonSpreadModel,
        StrategyAaveUsdt,
        StrategyAaveUsdc,
        StrategyAaveDai,
        StrategyCompoundUsdt,
        StrategyCompoundUsdc,
        StrategyCompoundDai
    ],
    // events: {
    // },
};

export default options;
