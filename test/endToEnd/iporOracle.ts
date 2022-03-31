import hre, { upgrades } from "hardhat";
import { BigNumber } from "ethers";

import { IporOracle } from "../../types";
import { daiAddress, usdcAddress, usdtAddress } from "./tokens";

export const iporOracleFactory = async (): Promise<IporOracle> => {
    const [admin] = await hre.ethers.getSigners();
    const factory = await hre.ethers.getContractFactory("IporOracle", admin);
    return upgrades.deployProxy(factory, [], {
        kind: "uups",
    }) as Promise<IporOracle>;
};

export const iporOracleSetup = async (iporOracle: IporOracle) => {
    const [admin] = await hre.ethers.getSigners();
    const adminAddress = await admin.getAddress();
    await iporOracle.addUpdater(adminAddress);
    await iporOracle.addAsset(usdtAddress);
    await iporOracle.addAsset(usdcAddress);
    await iporOracle.addAsset(daiAddress);
};

export const initIporValues = async (iporOracle: IporOracle) => {
    await iporOracle.updateIndexes(
        [daiAddress, usdtAddress, usdcAddress],
        [
            BigNumber.from("30000000000000000"),
            BigNumber.from("30000000000000000"),
            BigNumber.from("30000000000000000"),
        ]
    );
};
