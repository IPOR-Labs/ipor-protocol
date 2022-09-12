import { HardhatUserConfig } from "hardhat/config";
import * as dotenv from "dotenv";

dotenv.config();

const forkEnabled = process.env.FORK_ENABLED;
const forkingUrl = process.env.HARDHAT_FORKING_URL as string;

const networks: HardhatUserConfig["networks"] = {
    coverage: {
        url: "http://127.0.0.1:8555",
        blockGasLimit: 200000000,
        allowUnlimitedContractSize: true,
    },
    localhost: {
        chainId: 5777,
        url: "http://localhost:9545",
        allowUnlimitedContractSize: true,
    },
};

if (forkEnabled == "true") {
    console.log("Mainnet Fork");
    networks.hardhat = {
        chainId: 1,
        forking: {
            url: forkingUrl,
            blockNumber: 14222088,
        },
    };
} else {
    networks.hardhat = {
        allowUnlimitedContractSize: true,
    };
}

networks.hardhatfork = {
    chainId: 1,
    url: "http://127.0.0.1:8545",
    forking: {
        url: forkingUrl,
        blockNumber: 14222088,
    },
};

export default networks;
