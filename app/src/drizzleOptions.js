import IporOracle from "./contracts/IporOracle.json";

const options = {
    web3: {
        fallback: {
            type: "ws",
            url: "ws://127.0.0.1:8545",
        },
    },

    contracts: [IporOracle],
    events: {
        IporOracle: ["IporIndexUpdate"],
    }
};

export default options;
