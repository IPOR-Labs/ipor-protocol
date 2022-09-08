import hre, { upgrades } from "hardhat";
const keccak256 = require("keccak256");
import chai from "chai";
import { BigNumber, Signer, constants } from "ethers";
import { solidity } from "ethereum-waffle";

import { MockStrategy, StanleyDai, TestERC20 } from "../../../../types";

chai.use(solidity);
const { expect } = chai;

describe("Stanley -> StrategyChanged", () => {
    let admin: Signer;
    let stanley: StanleyDai;
    let DAI: TestERC20;
    let USDt: TestERC20;
    let strategyAave: MockStrategy;
    let strategyCompound: MockStrategy;

    beforeEach(async () => {
        [admin] = await hre.ethers.getSigners();
        const tokenFactory = await hre.ethers.getContractFactory("TestERC20");

        DAI = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;
        USDt = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;

        const tokenFactoryIvToken = await hre.ethers.getContractFactory("IvToken");
        const ivToken = await tokenFactoryIvToken.deploy("IvToken", "IVT", DAI.address);

        const StrategyAave = await hre.ethers.getContractFactory("MockStrategy");
        strategyAave = (await StrategyAave.deploy()) as MockStrategy;
        await strategyAave.setShareToken(DAI.address);
        await strategyAave.setAsset(DAI.address);
        const StrategyCompound = await hre.ethers.getContractFactory("MockStrategy");
        strategyCompound = (await StrategyCompound.deploy()) as MockStrategy;
        await strategyCompound.setShareToken(DAI.address);
        await strategyCompound.setAsset(DAI.address);

        const StanleyDai = await hre.ethers.getContractFactory("StanleyDai");
        stanley = (await upgrades.deployProxy(StanleyDai, [
            DAI.address,
            ivToken.address,
            strategyAave.address,
            strategyCompound.address,
        ])) as StanleyDai;

        await ivToken.setStanley(stanley.address);
    });

    describe("strategyAave", () => {
        it("Should setup aave strategy", async () => {
            //given
            const NewStrategyAave = await hre.ethers.getContractFactory("MockStrategy");
            const newStrategyAave = await NewStrategyAave.deploy();
            await newStrategyAave.setShareToken(DAI.address);
            await newStrategyAave.setAsset(DAI.address);
            const oldStrategyAddress = strategyAave.address;
            const newStrategyBalanceBefore = await newStrategyAave.balanceOf();

            //when
            await expect(stanley.setStrategyAave(newStrategyAave.address))
                //then
                .to.emit(stanley, "StrategyChanged")
                .withArgs(
                    admin.getAddress,
                    oldStrategyAddress,
                    newStrategyAave.address,
                    DAI.address
                );
            //then
            const newStrategyBalanceAfter = await newStrategyAave.balanceOf();

            expect(
                newStrategyBalanceBefore.eq(newStrategyBalanceAfter),
                "newStrategyBalanceBefore = newStrategyBalanceAfter"
            ).to.be.true;

            //revert to old strategy
            await stanley.setStrategyAave(oldStrategyAddress);
        });

        it("Should not setup new strategy when underlying Token don't match", async () => {
            //given
            const NewStrategyAave = await hre.ethers.getContractFactory("MockStrategy");
            const newStrategyAave = await NewStrategyAave.deploy();
            await newStrategyAave.setShareToken(DAI.address);
            await newStrategyAave.setAsset(USDt.address);
            await expect(
                //when
                stanley.setStrategyAave(newStrategyAave.address)
                //then
            ).to.revertedWith("IPOR_500");
        });

        it("Should not setup new strategy when pass zero address", async () => {
            //given
            const NewStrategyAave = await hre.ethers.getContractFactory("MockStrategy");
            await expect(
                //when
                stanley.setStrategyAave(constants.AddressZero)
                //then
            ).to.revertedWith("IPOR_000");
        });
    });

    describe("strategyCompound", () => {
        it("Should setup compound strategy", async () => {
            //given
            const NewStrategyCompound = await hre.ethers.getContractFactory("MockStrategy");
            const newStrategyCompound = await NewStrategyCompound.deploy();
            await newStrategyCompound.setShareToken(DAI.address);
            await newStrategyCompound.setAsset(DAI.address);
            const oldStrategyAddress = strategyCompound.address;
            //when
            await expect(stanley.setStrategyCompound(newStrategyCompound.address))
                //then
                .to.emit(stanley, "StrategyChanged")
                .withArgs(
                    await admin.getAddress,
                    oldStrategyAddress,
                    newStrategyCompound.address,
                    DAI.address
                );
            //then
        });

        it("Should not setup new strategy when underlying Token don't match", async () => {
            //given
            const NewStrategyCompound = await hre.ethers.getContractFactory("MockStrategy");
            const newStrategyCompound = await NewStrategyCompound.deploy();
            await newStrategyCompound.setShareToken(DAI.address);
            await newStrategyCompound.setAsset(USDt.address);
            await expect(
                //when
                stanley.setStrategyCompound(newStrategyCompound.address)
                //then
            ).to.revertedWith("IPOR_500");
        });

        it("Should not setup new strategy when pass zero address", async () => {
            //given
            const NewStrategyAave = await hre.ethers.getContractFactory("MockStrategy");
            await expect(
                //when
                stanley.setStrategyCompound(constants.AddressZero)
                //then
            ).to.revertedWith("IPOR_000");
        });
    });
});
