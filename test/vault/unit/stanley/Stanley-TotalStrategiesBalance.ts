import hre, { upgrades } from "hardhat";
const keccak256 = require("keccak256");
import chai from "chai";
import { BigNumber, Signer } from "ethers";
import { solidity } from "ethereum-waffle";

import { MockStrategy, StanleyDai, TestERC20, IvToken, StanleyUsdc } from "../../../../types";
import { N1__0_6DEC } from "../../../utils/Constants";

chai.use(solidity);
const { expect } = chai;

describe("Stanley -> totalStrategiesBalance 18 decimals", () => {
    const ONE_18DEC: any = BigNumber.from("1000000000000000000");
    const TC_AMOUNT_10000_USD_18DEC = ONE_18DEC.mul(10000);
    const TC_AMOUNT_20000_USD_18DEC = ONE_18DEC.mul(20000);
    let admin: Signer;
    let stanley: StanleyDai;
    let DAI: TestERC20;
    let ivTokenDai: IvToken;
    let strategyAave: MockStrategy;
    let strategyCompound: MockStrategy;

    beforeEach(async () => {
        [admin] = await hre.ethers.getSigners();
        const tokenFactory = await hre.ethers.getContractFactory("TestERC20");
        DAI = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;

        const tokenFactoryIvToken = await hre.ethers.getContractFactory("IvToken");

        const StrategyAave = await hre.ethers.getContractFactory("MockStrategy");
        strategyAave = (await StrategyAave.deploy()) as MockStrategy;
        await strategyAave.setShareToken(DAI.address);
        await strategyAave.setAsset(DAI.address);

        const StrategyCompound = await hre.ethers.getContractFactory("MockStrategy");
        strategyCompound = (await StrategyCompound.deploy()) as MockStrategy;
        await strategyCompound.setShareToken(DAI.address);
        await strategyCompound.setAsset(DAI.address);

        ivTokenDai = (await tokenFactoryIvToken.deploy("IvToken", "IVT", DAI.address)) as IvToken;

        const StanleyDai = await hre.ethers.getContractFactory("StanleyDai");
        stanley = (await upgrades.deployProxy(StanleyDai, [
            DAI.address,
            ivTokenDai.address,
            strategyAave.address,
            strategyCompound.address,
        ])) as StanleyDai;

        await ivTokenDai.setStanley(stanley.address);
        await stanley.setMilton(await admin.getAddress());
    });

    it("Should should return balance from Aave - 18 decimals", async () => {
        //given
        const expectedBalance = TC_AMOUNT_10000_USD_18DEC;
        await DAI.approve(stanley.address, expectedBalance);

        await strategyAave.setApy(BigNumber.from("555"));
        await strategyCompound.setApy(BigNumber.from("444"));

        await stanley.deposit(expectedBalance);

        //when
        const actualBalance = await stanley.totalBalance(await admin.getAddress());

        //then
        const actualMiltonIvTokenBalance = await ivTokenDai.balanceOf(await admin.getAddress());

        expect(actualMiltonIvTokenBalance).to.be.equal(expectedBalance);
        expect(actualBalance).to.be.equal(expectedBalance);
    });

    it("Should should return balance from Compound - 18 decimals", async () => {
        //given
        const expectedBalance = TC_AMOUNT_10000_USD_18DEC;
        await DAI.approve(stanley.address, expectedBalance);

        await strategyAave.setApy(BigNumber.from("33333333"));
        await strategyCompound.setApy(BigNumber.from("55555555"));

        await stanley.deposit(expectedBalance);

        //when
        const actualBalance = await stanley.totalBalance(await admin.getAddress());

        //then
        const actualMiltonIvTokenBalance = await ivTokenDai.balanceOf(await admin.getAddress());

        expect(actualBalance).to.be.equal(expectedBalance);
        expect(actualMiltonIvTokenBalance).to.be.equal(expectedBalance);
    });

    it("Should should return sum of balances from Aave and Compound - 18 decimals", async () => {
        //given
        const expectedTotalBalance = TC_AMOUNT_20000_USD_18DEC;
        await DAI.approve(stanley.address, expectedTotalBalance);

        await strategyAave.setApy(BigNumber.from("33333333"));
        await strategyCompound.setApy(BigNumber.from("55555555"));
        await stanley.deposit(TC_AMOUNT_10000_USD_18DEC);

        await strategyAave.setApy(BigNumber.from("55555555"));
        await strategyCompound.setApy(BigNumber.from("33333333"));
        await stanley.deposit(TC_AMOUNT_10000_USD_18DEC);

        //when
        const actualTotalBalance = await stanley.totalBalance(await admin.getAddress());

        //then
        const actualMiltonIvTokenBalance = await ivTokenDai.balanceOf(await admin.getAddress());

        expect(actualTotalBalance).to.be.equal(expectedTotalBalance);
        expect(actualMiltonIvTokenBalance).to.be.equal(expectedTotalBalance);
    });
});

describe("Stanley -> totalStrategiesBalance 6 decimals", () => {
    const TC_AMOUNT_10000_USD_6DEC = N1__0_6DEC.mul(10000);
    const TC_AMOUNT_20000_USD_6DEC = N1__0_6DEC.mul(20000);
    let admin: Signer;
    let stanley: StanleyUsdc;
    let usdc: TestERC20;
    let ivTokenUsdc: IvToken;
    let strategyAave: MockStrategy;
    let strategyCompound: MockStrategy;

    beforeEach(async () => {
        [admin] = await hre.ethers.getSigners();
        const tokenFactory = await hre.ethers.getContractFactory("TestERC20");
        usdc = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;
        await usdc.setDecimals(BigNumber.from("6"));

        const tokenFactoryIvToken = await hre.ethers.getContractFactory("IvToken");

        const StrategyAave = await hre.ethers.getContractFactory("MockStrategy");
        strategyAave = (await StrategyAave.deploy()) as MockStrategy;
        await strategyAave.setShareToken(usdc.address);
        await strategyAave.setAsset(usdc.address);

        const StrategyCompound = await hre.ethers.getContractFactory("MockStrategy");
        strategyCompound = (await StrategyCompound.deploy()) as MockStrategy;
        await strategyCompound.setShareToken(usdc.address);
        await strategyCompound.setAsset(usdc.address);

        ivTokenUsdc = (await tokenFactoryIvToken.deploy("IvToken", "IVT", usdc.address)) as IvToken;

        const StanleyUsdc = await hre.ethers.getContractFactory("StanleyUsdc");
        stanley = (await upgrades.deployProxy(StanleyUsdc, [
            usdc.address,
            ivTokenUsdc.address,
            strategyAave.address,
            strategyCompound.address,
        ])) as StanleyUsdc;

        await ivTokenUsdc.setStanley(stanley.address);
        await stanley.setMilton(await admin.getAddress());
    });

    it("Should should return balance from Aave - 18 decimals", async () => {
        //given
        const expectedBalance = TC_AMOUNT_10000_USD_6DEC;
        await usdc.approve(stanley.address, expectedBalance);

        await strategyAave.setApy(BigNumber.from("555"));
        await strategyCompound.setApy(BigNumber.from("444"));

        await stanley.deposit(expectedBalance);

        //when
        const actualBalance = await stanley.totalBalance(await admin.getAddress());

        //then
        const actualMiltonIvTokenBalance = await ivTokenUsdc.balanceOf(await admin.getAddress());

        expect(actualMiltonIvTokenBalance).to.be.equal(expectedBalance);
        expect(actualBalance).to.be.equal(expectedBalance);
    });

    it("Should should return balance from Compound - 6 decimals", async () => {
        //given
        const expectedBalance = TC_AMOUNT_10000_USD_6DEC;
        await usdc.approve(stanley.address, expectedBalance);

        await strategyAave.setApy(BigNumber.from("33333333"));
        await strategyCompound.setApy(BigNumber.from("55555555"));

        await stanley.deposit(expectedBalance);

        //when
        const actualBalance = await stanley.totalBalance(await admin.getAddress());

        //then
        const actualMiltonIvTokenBalance = await ivTokenUsdc.balanceOf(await admin.getAddress());

        expect(actualBalance).to.be.equal(expectedBalance);
        expect(actualMiltonIvTokenBalance).to.be.equal(expectedBalance);
    });

    it("Should should return sum of balances from Aave and Compound - 18 decimals", async () => {
        //given
        const expectedTotalBalance = TC_AMOUNT_20000_USD_6DEC;
        await usdc.approve(stanley.address, expectedTotalBalance);

        await strategyAave.setApy(BigNumber.from("33333333"));
        await strategyCompound.setApy(BigNumber.from("55555555"));
        await stanley.deposit(TC_AMOUNT_10000_USD_6DEC);

        await strategyAave.setApy(BigNumber.from("55555555"));
        await strategyCompound.setApy(BigNumber.from("33333333"));
        await stanley.deposit(TC_AMOUNT_10000_USD_6DEC);

        //when
        const actualTotalBalance = await stanley.totalBalance(await admin.getAddress());

        //then
        const actualMiltonIvTokenBalance = await ivTokenUsdc.balanceOf(await admin.getAddress());

        expect(actualTotalBalance).to.be.equal(expectedTotalBalance);
        expect(actualMiltonIvTokenBalance).to.be.equal(expectedTotalBalance);
    });
});
