import hre, { upgrades } from "hardhat";
const keccak256 = require("keccak256");
import chai from "chai";
import { BigNumber, Signer, constants } from "ethers";
import { solidity } from "ethereum-waffle";

import {
    MockStrategy,
    StanleyDai,
    TestERC20,
    MockTestnetShareTokenAaveDai,
    MockTestnetShareTokenCompoundDai,
} from "../../../../types";

chai.use(solidity);
const { expect } = chai;

describe("Stanley -> StrategyChanged", () => {
    let admin: Signer;
    let stanley: StanleyDai;
    let DAI: TestERC20;
    let aDAI: MockTestnetShareTokenAaveDai;
    let cDAI: MockTestnetShareTokenCompoundDai;
    let USDT: TestERC20;
    let strategyAave: MockStrategy;
    let strategyCompound: MockStrategy;

    beforeEach(async () => {
        [admin] = await hre.ethers.getSigners();
        const tokenFactory = await hre.ethers.getContractFactory("TestERC20");
        const shareTokenAaveFactory = await hre.ethers.getContractFactory(
            "MockTestnetShareTokenAaveDai"
        );
        const shareTokenCompoundFactory = await hre.ethers.getContractFactory(
            "MockTestnetShareTokenCompoundDai"
        );

        DAI = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;
        USDT = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;

        aDAI = (await shareTokenAaveFactory.deploy(
            BigNumber.from(2).pow(255)
        )) as MockTestnetShareTokenAaveDai;

        cDAI = (await shareTokenCompoundFactory.deploy(
            BigNumber.from(2).pow(255)
        )) as MockTestnetShareTokenCompoundDai;

        const tokenFactoryIvToken = await hre.ethers.getContractFactory("IvToken");
        const ivToken = await tokenFactoryIvToken.deploy("IvToken", "IVT", DAI.address);

        const StrategyAave = await hre.ethers.getContractFactory("MockStrategy");
        strategyAave = (await StrategyAave.deploy()) as MockStrategy;
        await strategyAave.setShareToken(aDAI.address);
        await strategyAave.setAsset(DAI.address);
        const StrategyCompound = await hre.ethers.getContractFactory("MockStrategy");
        strategyCompound = (await StrategyCompound.deploy()) as MockStrategy;
        await strategyCompound.setShareToken(cDAI.address);
        await strategyCompound.setAsset(DAI.address);

        const StanleyDai = await hre.ethers.getContractFactory("StanleyDai");
        stanley = (await upgrades.deployProxy(StanleyDai, [
            DAI.address,
            ivToken.address,
            strategyAave.address,
            strategyCompound.address,
        ])) as StanleyDai;

        await stanley.setMilton(await admin.getAddress());

        await ivToken.setStanley(stanley.address);
    });

    describe("strategyAave", () => {
        it("Should setup AAVE strategy", async () => {
            //given
            const NewStrategyAave = await hre.ethers.getContractFactory("MockStrategy");
            const newStrategyAave = await NewStrategyAave.deploy();
            await newStrategyAave.setShareToken(aDAI.address);

            await newStrategyAave.setAsset(DAI.address);
            const oldStrategyAddress = strategyAave.address;

            const newStrategyBalanceBefore = await newStrategyAave.balanceOf();

            await aDAI.mint(strategyAave.address, BigNumber.from("1000000000000000000000"));
            await strategyAave.setBalance(BigNumber.from("1000000000000000000000"));

            //when
            await expect(stanley.setStrategyAave(newStrategyAave.address))
                //then
                .to.emit(stanley, "StrategyChanged")
                .withArgs(
                    admin.getAddress,
                    oldStrategyAddress,
                    newStrategyAave.address,
                    aDAI.address
                );
            //then
            const newStrategyBalanceAfter = await newStrategyAave.balanceOf();

            expect(
                newStrategyBalanceBefore.eq(newStrategyBalanceAfter),
                "newStrategyBalanceBefore = newStrategyBalanceAfter"
            ).to.be.true;
        });

        it("Should not setup new strategy when underlying Token don't match", async () => {
            //given
            const NewStrategyAave = await hre.ethers.getContractFactory("MockStrategy");
            const newStrategyAave = await NewStrategyAave.deploy();
            await newStrategyAave.setShareToken(aDAI.address);
            await newStrategyAave.setAsset(USDT.address);
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
            await newStrategyCompound.setShareToken(cDAI.address);
            await newStrategyCompound.setAsset(DAI.address);
            const oldStrategyAddress = strategyCompound.address;

            await cDAI.mint(strategyCompound.address, BigNumber.from("1000000000000000000000"));
            await strategyCompound.setBalance(BigNumber.from("1000000000000000000000"));

            //when
            await expect(stanley.setStrategyCompound(newStrategyCompound.address))
                //then
                .to.emit(stanley, "StrategyChanged")
                .withArgs(
                    await admin.getAddress,
                    oldStrategyAddress,
                    newStrategyCompound.address,
                    cDAI.address
                );
            //then
        });

        it("Should not setup new strategy when underlying Token don't match", async () => {
            //given
            const NewStrategyCompound = await hre.ethers.getContractFactory("MockStrategy");
            const newStrategyCompound = await NewStrategyCompound.deploy();
            await newStrategyCompound.setShareToken(cDAI.address);
            await newStrategyCompound.setAsset(USDT.address);
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
