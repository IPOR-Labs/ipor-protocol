import hre, { upgrades } from "hardhat";
const keccak256 = require("keccak256");
import chai from "chai";
import { BigNumber, Signer, constants } from "ethers";
import { solidity } from "ethereum-waffle";

import { MockStrategy, Stanley, TestERC20, IvToken } from "../../../../types";

chai.use(solidity);
const { expect } = chai;
import { assertError } from "../../../utils/AssertUtils";
const one = BigNumber.from("1000000000000000000");

describe("Stanley -> constructor", () => {
    let admin: Signer, userOne: Signer;
    let stanley: Stanley;
    let DAI: TestERC20;
    let USDt: TestERC20;
    let strategyAave: MockStrategy;
    let strategyCompound: MockStrategy;
    let StanleyDaiFactory: any;
    let ivToken: IvToken;

    beforeEach(async () => {
        [admin, userOne] = await hre.ethers.getSigners();
        const tokenFactory = await hre.ethers.getContractFactory("TestERC20");
        DAI = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;
        USDt = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;
        StanleyDaiFactory = await hre.ethers.getContractFactory("StanleyDai");
        const tokenFactoryIvToken = await hre.ethers.getContractFactory("IvToken");
        ivToken = (await tokenFactoryIvToken.deploy("IvToken", "IVT", DAI.address)) as IvToken;

        const StrategyAave = await hre.ethers.getContractFactory("MockStrategy");
        strategyAave = (await StrategyAave.deploy()) as MockStrategy;
        await strategyAave.setShareToken(DAI.address);
        await strategyAave.setAsset(DAI.address);
        const StrategyCompound = await hre.ethers.getContractFactory("MockStrategy");
        strategyCompound = (await StrategyCompound.deploy()) as MockStrategy;
        await strategyCompound.setShareToken(DAI.address);
        await strategyCompound.setAsset(DAI.address);
    });

    it("Shoudl throw error when underlyingToken address is 0", async () => {
        // given
        // when
        await expect(
            //when
            upgrades.deployProxy(StanleyDaiFactory, [
                constants.AddressZero,
                ivToken.address,
                strategyAave.address,
                strategyCompound.address,
            ])
            //then
        ).to.be.revertedWith("IPOR_000");
    });

    it("Shoud deploy new IporVault", async () => {
        // given
        // when
        stanley = (await upgrades.deployProxy(StanleyDaiFactory, [
            DAI.address,
            ivToken.address,
            strategyAave.address,
            strategyCompound.address,
        ])) as Stanley;

        // then
        expect(stanley.address).to.be.not.empty;
    });

    it("Shoud throw error when ivToken address is 0", async () => {
        // given
        // when
        await expect(
            //when
            upgrades.deployProxy(StanleyDaiFactory, [
                DAI.address,
                constants.AddressZero,
                strategyAave.address,
                strategyCompound.address,
            ])
            //then
        ).to.be.revertedWith("IPOR_000");
    });

    it("Shoud throw error when strategyAave address is 0", async () => {
        // given
        // when
        await expect(
            //when
            upgrades.deployProxy(StanleyDaiFactory, [
                DAI.address,
                ivToken.address,
                constants.AddressZero,
                strategyCompound.address,
            ])
            //then
        ).to.be.revertedWith("IPOR_000");
    });

    it("Shoud throw error when strategyCompound address is 0", async () => {
        // given
        // when
        await expect(
            //when
            upgrades.deployProxy(StanleyDaiFactory, [
                DAI.address,
                ivToken.address,
                strategyAave.address,
                constants.AddressZero,
            ])
            //then
        ).to.be.revertedWith("IPOR_000");
    });

    it("Should throw error when strategyAave asset != from IporVault asset", async () => {
        // given
        await strategyAave.setAsset(USDt.address);
        // when
        await expect(
            //when
            upgrades.deployProxy(StanleyDaiFactory, [
                DAI.address,
                ivToken.address,
                strategyAave.address,
                strategyCompound.address,
            ])
            //then
        ).to.be.revertedWith("IPOR_500");
    });

    it("Shoud throw error when strategyCompound asset != from IporVault asset", async () => {
        // given
        await strategyCompound.setAsset(USDt.address);
        // when
        await expect(
            //when
            upgrades.deployProxy(StanleyDaiFactory, [
                DAI.address,
                ivToken.address,
                strategyAave.address,
                strategyCompound.address,
            ])
            //then
        ).to.be.revertedWith("IPOR_500");
    });

    it("Should be able to pause contract when sender is owner", async () => {
        //given
        stanley = (await upgrades.deployProxy(StanleyDaiFactory, [
            DAI.address,
            ivToken.address,
            strategyAave.address,
            strategyCompound.address,
        ])) as Stanley;
        //when
        await stanley.pause();
        //then
        expect(await stanley.paused()).to.be.true;
    });

    it("Should be able to unpause contract when sender is owner", async () => {
        //given
        stanley = (await upgrades.deployProxy(StanleyDaiFactory, [
            DAI.address,
            ivToken.address,
            strategyAave.address,
            strategyCompound.address,
        ])) as Stanley;
        await stanley.pause();
        expect(await stanley.paused()).to.be.true;
        //when
        await stanley.unpause();
        //then
        expect(await stanley.paused()).to.be.false;
    });

    it("Should not be able to unpause contract when sender is not owner", async () => {
        //given
        stanley = (await upgrades.deployProxy(StanleyDaiFactory, [
            DAI.address,
            ivToken.address,
            strategyAave.address,
            strategyCompound.address,
        ])) as Stanley;
        await stanley.pause();
        expect(await stanley.paused()).to.be.true;
        //when
        await assertError(
            stanley.connect(userOne).unpause(),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("Should not be able to unpause contract when sender is not owner", async () => {
        //given
        stanley = (await upgrades.deployProxy(StanleyDaiFactory, [
            DAI.address,
            ivToken.address,
            strategyAave.address,
            strategyCompound.address,
        ])) as Stanley;
        //when

        await assertError(
            stanley.connect(userOne).pause(),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT pause Smart Contract specific methods when paused", async () => {
        //given
        stanley = (await upgrades.deployProxy(StanleyDaiFactory, [
            DAI.address,
            ivToken.address,
            strategyAave.address,
            strategyCompound.address,
        ])) as Stanley;
        //when
        await stanley.pause();
        //then
        await stanley.totalBalance(await userOne.getAddress());
    });

    it("should pause Smart Contract specific methods", async () => {
        //given
        stanley = (await upgrades.deployProxy(StanleyDaiFactory, [
            DAI.address,
            ivToken.address,
            strategyAave.address,
            strategyCompound.address,
        ])) as Stanley;
        // stanley.setMilton(await userOne.getAddress());
        //when
        await stanley.pause();
        //then
        await assertError(stanley.deposit(one), "Pausable: paused");
        await assertError(stanley.withdraw(one), "Pausable: paused");
        await assertError(stanley.withdrawAll(), "Pausable: paused");
        await assertError(stanley.migrateAssetToStrategyWithMaxApr(), "Pausable: paused");
        await assertError(stanley.setStrategyAave(strategyAave.address), "Pausable: paused");
        await assertError(stanley.setStrategyAave(strategyCompound.address), "Pausable: paused");
        await assertError(stanley.setMilton(await userOne.getAddress()), "Pausable: paused");
    });
});
