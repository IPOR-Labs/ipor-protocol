import Warren from "./contracts/Warren.json";
import Milton from "./contracts/Milton.json";
import MiltonStorage from "./contracts/MiltonStorage.json";
import MiltonFaucet from "./contracts/MiltonFaucet.json";
import MiltonConfiguration from "./contracts/MiltonConfiguration";
import DaiMockedToken from "./contracts/DaiMockedToken";
import UsdcMockedToken from "./contracts/UsdcMockedToken";
import UsdtMockedToken from "./contracts/UsdtMockedToken";
import MiltonDevToolDataProvider from "./contracts/MiltonDevToolDataProvider";
import MiltonAddressesManager from "./contracts/MiltonAddressesManager";

const options = {
    web3: {
        fallback: {
            type: "ws",
            url: "ws://127.0.0.1:7545",
        },
    },

    contracts: [
        MiltonDevToolDataProvider,
        MiltonAddressesManager,
        Warren,
        Milton,
        MiltonStorage,
        MiltonConfiguration,
        DaiMockedToken,
        UsdtMockedToken,
        UsdcMockedToken,
        MiltonFaucet],
    events: {
        Warren: ["IporIndexUpdate"],
        Milton: ["OpenPosition", "ClosePosition"]
    }
};

export default options;
