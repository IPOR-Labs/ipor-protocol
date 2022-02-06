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
import IporAssetConfigurationUsdt from "./contracts/IporAssetConfigurationUsdt";
import IporAssetConfigurationUsdc from "./contracts/IporAssetConfigurationUsdc";
import IporAssetConfigurationDai from "./contracts/IporAssetConfigurationDai";
import DaiMockedToken from "./contracts/DaiMockedToken";
import UsdcMockedToken from "./contracts/UsdcMockedToken";
import UsdtMockedToken from "./contracts/UsdtMockedToken";
import MiltonSpreadModel from "./contracts/MiltonSpreadModel";
import MiltonDevToolDataProvider from "./contracts/MiltonDevToolDataProvider";
import MiltonFrontendDataProvider from "./contracts/MiltonFrontendDataProvider";
import IporConfiguration from "./contracts/IporConfiguration";
import JosephUsdt from "./contracts/JosephUsdt";
import JosephUsdc from "./contracts/JosephUsdc";
import JosephDai from "./contracts/JosephDai";
import ItfJosephUsdt from "./contracts/ItfJosephUsdt";
import ItfJosephUsdc from "./contracts/ItfJosephUsdc";
import ItfJosephDai from "./contracts/ItfJosephDai";
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
        MiltonFaucet,
        IporAssetConfigurationDai,
        IporAssetConfigurationUsdt,
        IporAssetConfigurationUsdc,
        MiltonSpreadModel
    ],
    // events: {        
    // },
};

export default options;
