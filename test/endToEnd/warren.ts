import hre, { upgrades } from "hardhat";
import { BigNumber } from "ethers";

import { Warren } from "../../types";
import { daiAddress, usdcAddress, usdtAddress } from "./tokens";

export const warrenFactory = async (): Promise<Warren> => {
    const [admin] = await hre.ethers.getSigners();
    const factory = await hre.ethers.getContractFactory("Warren", admin);
    return upgrades.deployProxy(factory, [], {
        kind: "uups",
    }) as Promise<Warren>;
};

export const warrenSetup = async (warren: Warren) => {
    const [admin] = await hre.ethers.getSigners();
    const adminAddress = await admin.getAddress();
    await warren.addUpdater(adminAddress);
    await warren.addAsset(usdtAddress);
    await warren.addAsset(usdcAddress);
    await warren.addAsset(daiAddress);
};

export const initIporValuse = async (warren: Warren) => {
    await warren.updateIndexes(
        [daiAddress, usdtAddress, usdcAddress],
        [
            BigNumber.from("30000000000000000"),
            BigNumber.from("30000000000000000"),
            BigNumber.from("30000000000000000"),
        ]
    );
};
