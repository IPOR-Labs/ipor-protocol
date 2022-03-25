import hre, { upgrades } from "hardhat";
const keccak256 = require("keccak256");
import chai from "chai";
import { BigNumber, Signer } from "ethers";
import { solidity } from "ethereum-waffle";

import { MockStrategy, StanleyDai, TestERC20, IvToken } from "../../../../types";

chai.use(solidity);
const { expect } = chai;

describe("Stanley -> totalStrategiesBalance", () => {
    const ONE_18DEC: any = BigNumber.from("1000000000000000000");
    const TC_AMOUNT_10000_USD_18DEC = ONE_18DEC.mul(10000);
    const TC_AMOUNT_20000_USD_18DEC = ONE_18DEC.mul(20000);
    let admin: Signer;
    let stanley: StanleyDai;
    let DAI: TestERC20;
    let ivTokenDai: IvToken;
    let aaveStrategy: MockStrategy;
    let compoundStrategy: MockStrategy;

    beforeEach(async () => {
        [admin] = await hre.ethers.getSigners();
        const tokenFactory = await hre.ethers.getContractFactory("TestERC20");
        DAI = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;

        const tokenFactoryIvToken = await hre.ethers.getContractFactory("IvToken");

        const AaveStrategy = await hre.ethers.getContractFactory("MockStrategy");
        aaveStrategy = (await AaveStrategy.deploy()) as MockStrategy;
        await aaveStrategy.setShareToken(DAI.address);
        await aaveStrategy.setAsset(DAI.address);

        const CompoundStrategy = await hre.ethers.getContractFactory("MockStrategy");
        compoundStrategy = (await CompoundStrategy.deploy()) as MockStrategy;
        await compoundStrategy.setShareToken(DAI.address);
        await compoundStrategy.setAsset(DAI.address);

        ivTokenDai = (await tokenFactoryIvToken.deploy("IvToken", "IVT", DAI.address)) as IvToken;

        const StanleyDai = await hre.ethers.getContractFactory("StanleyDai");
        stanley = (await upgrades.deployProxy(StanleyDai, [
            DAI.address,
            ivTokenDai.address,
            aaveStrategy.address,
            compoundStrategy.address,
        ])) as StanleyDai;

        await ivTokenDai.setStanley(stanley.address);
        await stanley.setMilton(await admin.getAddress());
    });

    it("Should should return balance from Aave - 18 decimals", async () => {
        //given
        const expectedBalance = TC_AMOUNT_10000_USD_18DEC;
        await DAI.approve(stanley.address, expectedBalance);

        await aaveStrategy.setApy(BigNumber.from("555"));
        await compoundStrategy.setApy(BigNumber.from("444"));

        await stanley.deposit(expectedBalance);

        //when
        const actualBalance = await stanley.totalBalance(await admin.getAddress());

        //then
        const actualMiltonIvTokenBalance = await ivTokenDai.balanceOf(await admin.getAddress());
        const actualAssetBalanceAave = await DAI.balanceOf(aaveStrategy.address);
        const actualAssetBalanceCompound = await DAI.balanceOf(compoundStrategy.address);

        expect(actualMiltonIvTokenBalance).to.be.equal(expectedBalance);
        expect(actualBalance).to.be.equal(expectedBalance);

        //TODO: currently always 0 uncomment when good mocks for Aave and Compound will be in code
        // expect(actualAssetBalanceAave).to.be.equal(expectedBalance);
        // expect(actualAssetBalanceCompound).to.be.equal(0);
    });

    it("Should should return balance from Compound - 18 decimals", async () => {
        //given
        const expectedBalance = TC_AMOUNT_10000_USD_18DEC;
        await DAI.approve(stanley.address, expectedBalance);

        await aaveStrategy.setApy(BigNumber.from("33333333"));
        await compoundStrategy.setApy(BigNumber.from("55555555"));

        await stanley.deposit(expectedBalance);

        //when
        const actualBalance = await stanley.totalBalance(await admin.getAddress());

        //then
        const actualMiltonIvTokenBalance = await ivTokenDai.balanceOf(await admin.getAddress());
        const actualAssetBalanceAave = await DAI.balanceOf(aaveStrategy.address);
        const actualAssetBalanceCompound = await DAI.balanceOf(compoundStrategy.address);

        expect(actualBalance).to.be.equal(expectedBalance);
        expect(actualMiltonIvTokenBalance).to.be.equal(expectedBalance);

        //TODO: currently always 0 uncomment when good mocks for Aave and Compound will be in code
        // expect(actualAssetBalanceAave).to.be.equal(0);
        // expect(actualAssetBalanceCompound).to.be.equal(expectedBalance);
    });

    it("Should should return sum of balances from Aave and Compound - 18 decimals", async () => {
        //given
        const expectedTotalBalance = TC_AMOUNT_20000_USD_18DEC;
        await DAI.approve(stanley.address, expectedTotalBalance);

        await aaveStrategy.setApy(BigNumber.from("33333333"));
        await compoundStrategy.setApy(BigNumber.from("55555555"));
        await stanley.deposit(TC_AMOUNT_10000_USD_18DEC);

        await aaveStrategy.setApy(BigNumber.from("55555555"));
        await compoundStrategy.setApy(BigNumber.from("33333333"));
        await stanley.deposit(TC_AMOUNT_10000_USD_18DEC);

        //when
        const actualTotalBalance = await stanley.totalBalance(await admin.getAddress());

        //then
        const actualMiltonIvTokenBalance = await ivTokenDai.balanceOf(await admin.getAddress());

        const actualAssetBalanceAave = await DAI.balanceOf(aaveStrategy.address);
        const actualAssetBalanceCompound = await DAI.balanceOf(compoundStrategy.address);

        expect(actualTotalBalance).to.be.equal(expectedTotalBalance);
        expect(actualMiltonIvTokenBalance).to.be.equal(expectedTotalBalance);

        //TODO: currently always 0 uncomment when good mocks for Aave and Compound will be in code
        // expect(actualAssetBalanceAave).to.be.equal(TC_AMOUNT_10000_USD_18DEC);
        // expect(actualAssetBalanceCompound).to.be.equal(
        //     TC_AMOUNT_10000_USD_18DEC
        // );
    });

    //TODO: add tests for 6 decimals !!!
});
