import Warren from "./contracts/Warren.json";
import MiltonV1 from "./contracts/MiltonV1.json";
import MiltonV1Storage from "./contracts/MiltonV1Storage.json";
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
        MiltonV1,
        MiltonV1Storage,
        MiltonConfiguration,
        DaiMockedToken,
        UsdtMockedToken,
        UsdcMockedToken,
        MiltonFaucet],
    events: {
        Warren: ["IporIndexUpdate"],
        MiltonV1: ["OpenPosition", "ClosePosition"]
    }
};

export default options;
