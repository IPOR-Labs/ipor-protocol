import hre, { upgrades } from "hardhat";
import { BigNumber } from "ethers";

import { IporRiskManagementOracle } from "../../types";

export const iporRiskManagementOracleFactory = async (initialParams: any): Promise<IporRiskManagementOracle> => {
    const [admin] = await hre.ethers.getSigners();
    const factory = await hre.ethers.getContractFactory("IporRiskManagementOracle", admin);

    return upgrades.deployProxy(
        factory,
        [
            initialParams.assets,
            initialParams.maxNotionalPayFixed,
            initialParams.maxNotionalReceiveFixed,
            initialParams.maxCollateralRatioPayFixed,
            initialParams.maxCollateralRatioReceiveFixed,
            initialParams.maxCollateralRatio,
        ],
        {
            kind: "uups",
        }
    ) as Promise<IporRiskManagementOracle>;
};

export const iporRiskManagementOracleSetup = async (iporRiskManagementOracle: IporRiskManagementOracle) => {
    const [admin] = await hre.ethers.getSigners();
    const adminAddress = await admin.getAddress();
    await iporRiskManagementOracle.addUpdater(adminAddress);
};
