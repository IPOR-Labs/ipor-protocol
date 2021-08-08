import Warren from "./contracts/Warren.json";
import MiltonV1 from "./contracts/MiltonV1.json";
import MiltonConfiguration from "./contracts/MiltonConfiguration";

const options = {
    web3: {
        fallback: {
            type: "ws",
            url: "ws://127.0.0.1:7545",
        },
    },

    contracts: [Warren, MiltonV1, MiltonConfiguration],
    events: {
        Warren: ["IporIndexUpdate"],

    }
};

export default options;
