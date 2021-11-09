import Warren from "./contracts/Warren.json";
import WarrenStorage from "./contracts/WarrenStorage.json";
import WarrenDevToolDataProvider from "./contracts/WarrenDevToolDataProvider.json";
import Milton from "./contracts/Milton.json";
import TestMilton from "./contracts/TestMilton.json";
import MiltonStorage from "./contracts/MiltonStorage.json";
import MiltonFaucet from "./contracts/MiltonFaucet.json";
import IporConfigurationUsdt from "./contracts/IporConfigurationUsdt";
import IporConfigurationUsdc from "./contracts/IporConfigurationUsdc";
import IporConfigurationDai from "./contracts/IporConfigurationDai";
import DaiMockedToken from "./contracts/DaiMockedToken";
import UsdcMockedToken from "./contracts/UsdcMockedToken";
import UsdtMockedToken from "./contracts/UsdtMockedToken";
import MiltonDevToolDataProvider from "./contracts/MiltonDevToolDataProvider";
import MiltonFrontendDataProvider from "./contracts/MiltonFrontendDataProvider";
import IporAddressesManager from "./contracts/IporAddressesManager";
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
        IporAddressesManager,
        Joseph,
        TestJoseph,
        Warren,
        WarrenStorage,
        WarrenDevToolDataProvider,
        Milton,
        TestMilton,
        MiltonStorage,
        DaiMockedToken,
        UsdtMockedToken,
        UsdcMockedToken,
        MiltonFaucet,
        IporConfigurationDai,
        IporConfigurationUsdt,
        IporConfigurationUsdc],
    events: {
        WarrenStorage: ["IporIndexUpdate"]
    }
};

export default options;
