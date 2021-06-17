import IporOracle from "./contracts/IporOracle.json";
import IporAmm from "./contracts/IporAmm.json";

const options = {
    web3: {
        fallback: {
            type: "ws",
            url: "ws://127.0.0.1:8545",
        },
    },

    contracts: [IporOracle, IporAmm],
    events: {
        IporOracle: ["IporIndexUpdate"],
    }
};

export default options;
