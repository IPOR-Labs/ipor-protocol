import IporOracle from "./contracts/IporOracle.json";
import Amm from "./contracts/Amm.json";

const options = {
    web3: {
        fallback: {
            type: "ws",
            url: "ws://127.0.0.1:8545",
        },
    },

    contracts: [IporOracle, Amm],
    events: {
        IporOracle: ["IporIndexUpdate"],
    }
};

export default options;
