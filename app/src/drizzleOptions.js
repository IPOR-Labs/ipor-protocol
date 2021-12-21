import Warren from "./contracts/Warren.json";
import TestWarren from "./contracts/TestWarren.json";
import WarrenStorage from "./contracts/WarrenStorage.json";
import WarrenDevToolDataProvider from "./contracts/WarrenDevToolDataProvider.json";
import Milton from "./contracts/Milton.json";
import TestMilton from "./contracts/TestMilton.json";
import MiltonStorage from "./contracts/MiltonStorage.json";
import MiltonFaucet from "./contracts/MiltonFaucet.json";
import IporAssetConfigurationUsdt from "./contracts/IporAssetConfigurationUsdt";
import IporAssetConfigurationUsdc from "./contracts/IporAssetConfigurationUsdc";
import IporAssetConfigurationDai from "./contracts/IporAssetConfigurationDai";
import DaiMockedToken from "./contracts/DaiMockedToken";
import UsdcMockedToken from "./contracts/UsdcMockedToken";
import UsdtMockedToken from "./contracts/UsdtMockedToken";
import MiltonDevToolDataProvider from "./contracts/MiltonDevToolDataProvider";
import MiltonFrontendDataProvider from "./contracts/MiltonFrontendDataProvider";
import IporConfiguration from "./contracts/IporConfiguration";
import Joseph from "./contracts/Joseph";
import TestJoseph from "./contracts/TestJoseph";
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
        Joseph,
        TestJoseph,
        Warren,
        TestWarren,
        WarrenStorage,
        WarrenDevToolDataProvider,
        Milton,
        TestMilton,
        MiltonStorage,
        DaiMockedToken,
        UsdtMockedToken,
        UsdcMockedToken,
        MiltonFaucet,
        IporAssetConfigurationDai,
        IporAssetConfigurationUsdt,
        IporAssetConfigurationUsdc],
    events: {
        WarrenStorage: ["IporIndexUpdate"]
    }
};

export default options;
