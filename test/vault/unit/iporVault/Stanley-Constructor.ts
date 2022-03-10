import hre, { upgrades } from "hardhat";
const keccak256 = require("keccak256");
import chai from "chai";
import { BigNumber, Signer, constants } from "ethers";
import { solidity } from "ethereum-waffle";

import { MockStrategy, Stanley, TestERC20, IvToken } from "../../../../types";

chai.use(solidity);
const { expect } = chai;

describe("Stanley -> constructor", () => {
    let admin: Signer;
    let stanley: Stanley;
    let DAI: TestERC20;
    let USDt: TestERC20;
    let aaveStrategy: MockStrategy;
    let compoundStrategy: MockStrategy;
    let StanleyFactory: any;
    let ivToken: IvToken;

    beforeEach(async () => {
        [admin] = await hre.ethers.getSigners();
        const tokenFactory = await hre.ethers.getContractFactory("TestERC20");
        DAI = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;
        USDt = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;
        StanleyFactory = await hre.ethers.getContractFactory("Stanley");
        const tokenFactoryIvToken = await hre.ethers.getContractFactory("IvToken");
        ivToken = (await tokenFactoryIvToken.deploy("IvToken", "IVT", DAI.address)) as IvToken;

        const AaveStrategy = await hre.ethers.getContractFactory("MockStrategy");
        aaveStrategy = (await AaveStrategy.deploy()) as MockStrategy;
        await aaveStrategy.setShareToken(DAI.address);
        await aaveStrategy.setAsset(DAI.address);
        const CompoundStrategy = await hre.ethers.getContractFactory("MockStrategy");
        compoundStrategy = (await CompoundStrategy.deploy()) as MockStrategy;
        await compoundStrategy.setShareToken(DAI.address);
        await compoundStrategy.setAsset(DAI.address);
    });

    it("Shoud throw error when underlyingToken address is 0", async () => {
        // given
        // when
        await expect(
            //when
            upgrades.deployProxy(StanleyFactory, [
                constants.AddressZero,
                ivToken.address,
                aaveStrategy.address,
                compoundStrategy.address,
            ])
            //then
        ).to.be.revertedWith("IPOR_001");
    });

    it("Shoud deploy new IporVault", async () => {
        // given
        // when
        stanley = (await upgrades.deployProxy(StanleyFactory, [
            DAI.address,
            ivToken.address,
            aaveStrategy.address,
            compoundStrategy.address,
        ])) as Stanley;

        // then
        expect(stanley.address).to.be.not.empty;
    });

    it("Shoud throw error when ivToken address is 0", async () => {
        // given
        // when
        await expect(
            //when
            upgrades.deployProxy(StanleyFactory, [
                DAI.address,
                constants.AddressZero,
                aaveStrategy.address,
                compoundStrategy.address,
            ])
            //then
        ).to.be.revertedWith("IPOR_001");
    });

    it("Shoud throw error when aaveStrategy address is 0", async () => {
        // given
        // when
        await expect(
            //when
            upgrades.deployProxy(StanleyFactory, [
                DAI.address,
                ivToken.address,
                constants.AddressZero,
                compoundStrategy.address,
            ])
            //then
        ).to.be.revertedWith("IPOR_001");
    });

    it("Shoud throw error when compoundStrategy address is 0", async () => {
        // given
        // when
        await expect(
            //when
            upgrades.deployProxy(StanleyFactory, [
                DAI.address,
                ivToken.address,
                aaveStrategy.address,
                constants.AddressZero,
            ])
            //then
        ).to.be.revertedWith("IPOR_001");
    });

    it("Shoud throw error when aaveStrategy asset != from IporVault asset", async () => {
        // given
        await aaveStrategy.setAsset(USDt.address);
        // when
        await expect(
            //when
            upgrades.deployProxy(StanleyFactory, [
                DAI.address,
                ivToken.address,
                aaveStrategy.address,
                compoundStrategy.address,
            ])
            //then
        ).to.be.revertedWith("IPOR_503");
    });

    it("Shoud throw error when compoundStrategy asset != from IporVault asset", async () => {
        // given
        await compoundStrategy.setAsset(USDt.address);
        // when
        await expect(
            //when
            upgrades.deployProxy(StanleyFactory, [
                DAI.address,
                ivToken.address,
                aaveStrategy.address,
                compoundStrategy.address,
            ])
            //then
        ).to.be.revertedWith("IPOR_503");
    });
});
