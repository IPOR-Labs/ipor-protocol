import hre, { upgrades } from "hardhat";
import { BigNumber } from "ethers";

import { MarketSafetyOracle } from "../../types";

export const marketSafetyOracleFactory = async (initialParams: any): Promise<MarketSafetyOracle> => {
    const [admin] = await hre.ethers.getSigners();
    const factory = await hre.ethers.getContractFactory("MarketSafetyOracle", admin);

    return upgrades.deployProxy(
        factory,
        [
            initialParams.assets,
            initialParams.maxNotionalPayFixed,
            initialParams.maxNotionalReceiveFixed,
            initialParams.maxUtilizationRatePayFixed,
            initialParams.maxUtilizationRateReceiveFixed,
            initialParams.maxUtilizationRate,
        ],
        {
            kind: "uups",
        }
    ) as Promise<MarketSafetyOracle>;
};

export const marketSafetyOracleSetup = async (marketSafetyOracle: MarketSafetyOracle) => {
    const [admin] = await hre.ethers.getSigners();
    const adminAddress = await admin.getAddress();
    await marketSafetyOracle.addUpdater(adminAddress);
};
