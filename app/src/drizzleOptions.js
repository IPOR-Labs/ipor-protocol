import IporOracle from "./contracts/IporOracle.json";
import IporAmmV1 from "./contracts/IporAmmV1.json";

const options = {
    web3: {
        fallback: {
            type: "ws",
            url: "ws://127.0.0.1:7545",
        },
    },

    contracts: [IporOracle, IporAmmV1],
    events: {
        IporOracle: ["IporIndexUpdate"],
    }
};

export default options;
