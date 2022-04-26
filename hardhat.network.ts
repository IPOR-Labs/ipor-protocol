import { HardhatUserConfig } from "hardhat/config";
import * as dotenv from "dotenv";

dotenv.config();

const alchemyKey = process.env.ALCHEMY_API_KEY;
const infuraApiKey = process.env.INFURA_API_KEY;
const mnemonic = process.env.MNEMONIC;
const fork_enabled = process.env.FORK_ENABLED;

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

if (fork_enabled == "true") {
    console.log("MainNet fork");
    networks.hardhat = {
        chainId: 1,
        forking: {
            url: `https://eth-mainnet.alchemyapi.io/v2/rT2R1mRGMzUr80dcTdwOTG1JSMVYzSJi`,
            blockNumber: 14222088, // 14222087 Compaund APY: 2093206012009920000, AAVE APY: 2242773611830780298
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
        url: `https://eth-mainnet.alchemyapi.io/v2/rT2R1mRGMzUr80dcTdwOTG1JSMVYzSJi`,
        blockNumber: 14222088, // 14222087 Compaund APY: 2093206012009920000, AAVE APY: 2242773611830780298
    },
};

if (mnemonic) {
    networks.xdai = {
        chainId: 100,
        url: "https://rpc.xdaichain.com/",
        accounts: {
            mnemonic,
        },
    };
    networks.poaSokol = {
        chainId: 77,
        url: "https://sokol.poa.network",
        accounts: {
            mnemonic,
        },
    };
    networks.matic = {
        chainId: 137,
        url: "https://rpc-mainnet.maticvigil.com",
        accounts: {
            mnemonic,
        },
    };
    networks.mumbai = {
        chainId: 80001,
        url: "https://rpc-mumbai.matic.today",
        accounts: {
            mnemonic,
        },
        loggingEnabled: true,
    };
}

if (infuraApiKey && mnemonic) {
    networks.kovan = {
        url: `https://kovan.infura.io/v3/${infuraApiKey}`,
        accounts: {
            mnemonic,
        },
    };

    networks.ropsten = {
        url: `https://ropsten.infura.io/v3/${infuraApiKey}`,
        accounts: {
            mnemonic,
        },
    };

    networks.rinkeby = {
        url: `https://rinkeby.infura.io/v3/${infuraApiKey}`,
        accounts: {
            mnemonic,
        },
    };

    networks.mainnet = {
        url: `https://eth-mainnet.alchemyapi.io/v2/${alchemyKey}`,
        accounts: {
            mnemonic,
        },
    };
} else {
    console.warn("No infura or hdwallet available for testnets");
}

export default networks;
