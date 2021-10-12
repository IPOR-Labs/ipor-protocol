import Warren from "./contracts/Warren.json";
import WarrenStorage from "./contracts/WarrenStorage.json";
import WarrenDevToolDataProvider from "./contracts/WarrenDevToolDataProvider.json";
import Milton from "./contracts/Milton.json";
import TestMilton from "./contracts/TestMilton.json";
import MiltonStorage from "./contracts/MiltonStorage.json";
import MiltonFaucet from "./contracts/MiltonFaucet.json";
import IporConfiguration from "./contracts/IporConfiguration";
import DaiMockedToken from "./contracts/DaiMockedToken";
import UsdcMockedToken from "./contracts/UsdcMockedToken";
import UsdtMockedToken from "./contracts/UsdtMockedToken";
import MiltonDevToolDataProvider from "./contracts/MiltonDevToolDataProvider";
import IporAddressesManager from "./contracts/IporAddressesManager";
import Joseph from "./contracts/Joseph";

const options = {
    web3: {
        fallback: {
            type: "ws",
            url: "ws://127.0.0.1:7545",
        },
    },

    contracts: [
        MiltonDevToolDataProvider,
        IporAddressesManager,
        Joseph,
        Warren,
        WarrenStorage,
        WarrenDevToolDataProvider,
        TestMilton,
        Milton,
        MiltonStorage,
        IporConfiguration,
        DaiMockedToken,
        UsdtMockedToken,
        UsdcMockedToken,
        MiltonFaucet],
    events: {
        WarrenStorage: ["IporIndexUpdate"],
        Milton: ["OpenPosition", "ClosePosition"]
    }
};

export default options;
