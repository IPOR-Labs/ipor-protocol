import hre, { upgrades } from "hardhat";
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

    it("Shouldl throw error when underlyingToken address is 0", async () => {
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

    it("Should deploy new IporVault", async () => {
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

    it("Should throw error when ivToken address is 0", async () => {
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

    it("Should throw error when strategyAave address is 0", async () => {
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

    it("Should throw error when strategyCompound address is 0", async () => {
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

    it("Should throw error when strategyCompound asset != from IporVault asset", async () => {
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

    it("Should throw error when stanley asset != from IvToken asset", async () => {
        // given
        // when
        await expect(
            //when
            upgrades.deployProxy(StanleyDaiFactory, [
                USDt.address,
                ivToken.address,
                strategyAave.address,
                strategyCompound.address,
            ])
            //then
        ).to.be.revertedWith("IPOR_002");
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

    it("Should pause Smart Contract specific methods", async () => {
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
        await assertError(stanley.deposit(one), "Pausable: paused");
        await assertError(stanley.withdraw(one), "Pausable: paused");
        await assertError(stanley.withdrawAll(), "Pausable: paused");
        await assertError(stanley.migrateAssetToStrategyWithMaxApr(), "Pausable: paused");
        await assertError(stanley.setStrategyAave(strategyAave.address), "Pausable: paused");
        await assertError(stanley.setStrategyAave(strategyCompound.address), "Pausable: paused");
        await assertError(stanley.setMilton(await userOne.getAddress()), "Pausable: paused");
    });

    it("Should return version of contract ", async () => {
        //given
        stanley = (await upgrades.deployProxy(StanleyDaiFactory, [
            DAI.address,
            ivToken.address,
            strategyAave.address,
            strategyCompound.address,
        ])) as Stanley;
        //when
        const version = await stanley.getVersion();

        // then
        expect(version).to.be.equal(2);
    });

    it("Should return propper asset", async () => {
        //given
        stanley = (await upgrades.deployProxy(StanleyDaiFactory, [
            DAI.address,
            ivToken.address,
            strategyAave.address,
            strategyCompound.address,
        ])) as Stanley;
        //when
        const assetAddress = await stanley.getAsset();
        //then
        expect(assetAddress).to.be.equal(DAI.address);
    });

    it("Should deploy new StanleyUsdt", async () => {
        // given
        const StanleyUsdtFactory = await hre.ethers.getContractFactory("StanleyUsdt");
        const tokenFactoryIvTokenUsdt = await hre.ethers.getContractFactory("IvToken");
        const ivTokenUsdt = (await tokenFactoryIvTokenUsdt.deploy(
            "IvToken",
            "IVT",
            USDt.address
        )) as IvToken;
        await USDt.setDecimals(BigNumber.from("6"));
        const StrategyAave = await hre.ethers.getContractFactory("MockStrategy");
        const strategyAaveUsdt = (await StrategyAave.deploy()) as MockStrategy;
        await strategyAaveUsdt.setShareToken(USDt.address);
        await strategyAaveUsdt.setAsset(USDt.address);

        const StrategyCompoundUsdt = await hre.ethers.getContractFactory("MockStrategy");
        const strategyCompoundUsdt = (await StrategyCompoundUsdt.deploy()) as MockStrategy;
        await strategyCompoundUsdt.setShareToken(USDt.address);
        await strategyCompoundUsdt.setAsset(USDt.address);
        // when
        stanley = (await upgrades.deployProxy(StanleyUsdtFactory, [
            USDt.address,
            ivTokenUsdt.address,
            strategyAaveUsdt.address,
            strategyCompoundUsdt.address,
        ])) as Stanley;

        // then
        expect(stanley.address).to.be.not.empty;
    });

    it("Should deploy new StanleyUsdc", async () => {
        // given
        const StanleyUsdtFactory = await hre.ethers.getContractFactory("StanleyUsdc");
        const tokenFactoryIvTokenUsdt = await hre.ethers.getContractFactory("IvToken");
        const tokenFactory = await hre.ethers.getContractFactory("TestERC20");
        const usdc = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;
        await usdc.setDecimals(BigNumber.from("6"));
        const ivTokenUsdc = (await tokenFactoryIvTokenUsdt.deploy(
            "IvToken",
            "IVT",
            usdc.address
        )) as IvToken;

        const StrategyAave = await hre.ethers.getContractFactory("MockStrategy");
        const strategyAaveUsdc = (await StrategyAave.deploy()) as MockStrategy;
        await strategyAaveUsdc.setShareToken(usdc.address);
        await strategyAaveUsdc.setAsset(usdc.address);

        const StrategyCompoundUsdc = await hre.ethers.getContractFactory("MockStrategy");
        const strategyCompoundUsdc = (await StrategyCompoundUsdc.deploy()) as MockStrategy;
        await strategyCompoundUsdc.setShareToken(usdc.address);
        await strategyCompoundUsdc.setAsset(usdc.address);
        // when
        stanley = (await upgrades.deployProxy(StanleyUsdtFactory, [
            usdc.address,
            ivTokenUsdc.address,
            strategyAaveUsdc.address,
            strategyCompoundUsdc.address,
        ])) as Stanley;

        // then
        expect(stanley.address).to.be.not.empty;
    });
});
