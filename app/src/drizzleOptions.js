import Warren from "./contracts/Warren.json";
import MiltonV1 from "./contracts/MiltonV1.json";
import MiltonFaucet from "./contracts/MiltonFaucet.json";
import MiltonConfiguration from "./contracts/MiltonConfiguration";
import DaiMockedToken from "./contracts/DaiMockedToken";
import UsdcMockedToken from "./contracts/UsdcMockedToken";
import UsdtMockedToken from "./contracts/UsdtMockedToken";
import MiltonDevToolDataProvider from "./contracts/MiltonDevToolDataProvider";

const options = {
    web3: {
        fallback: {
            type: "ws",
            url: "ws://127.0.0.1:7545",
        },
    },

    contracts: [
        MiltonDevToolDataProvider,
        Warren,
        MiltonV1,
        MiltonConfiguration,
        DaiMockedToken,
        UsdtMockedToken,
        UsdcMockedToken,
        MiltonFaucet],
    events: {
        Warren: ["IporIndexUpdate"],

    }
};

export default options;
