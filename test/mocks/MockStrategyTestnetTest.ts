import hre from "hardhat";
import chai from "chai";
import { BigNumber, Signer, constants } from "ethers";
import { UsdtMockedToken, DaiMockedToken, UsdcMockedToken, MockStrategyTestnet } from "../../types";
import {
    N1__0_18DEC,
    N1__0_6DEC,
    PERCENTAGE_3_5_18DEC,
    TOTAL_SUPPLY_18_DECIMALS,
    TOTAL_SUPPLY_6_DECIMALS,
    USER_SUPPLY_10MLN_18DEC,
    USER_SUPPLY_6_DECIMALS,
    ZERO,
} from "../utils/Constants";

const { expect } = chai;

describe("MockStrategyTestnet", () => {
    let admin: Signer, userOne: Signer, userTwo: Signer, userThree: Signer;
    let tokenDai: DaiMockedToken;
    let tokenUsdt: UsdtMockedToken;
    let tokenUsdc: UsdcMockedToken;
    let strategyDai: MockStrategyTestnet;
    let strategyUsdc: MockStrategyTestnet;
    let strategyUsdt: MockStrategyTestnet;
    const N100_000 = BigNumber.from("100000");
    const N10_000 = BigNumber.from("10000");
    const yearInSeconds = 31536000;

    before(async () => {
        [admin, userOne, userTwo, userThree] = await hre.ethers.getSigners();
    });

    beforeEach(async () => {
        const adminAddress = await admin.getAddress();
        const DaiMockedToken = await hre.ethers.getContractFactory("DaiMockedToken");
        tokenDai = (await DaiMockedToken.deploy(TOTAL_SUPPLY_18_DECIMALS, 18)) as DaiMockedToken;
        const shareToken18DEC = (await DaiMockedToken.deploy(
            TOTAL_SUPPLY_18_DECIMALS,
            18
        )) as DaiMockedToken;
        const UsdtMockedToken = await hre.ethers.getContractFactory("UsdtMockedToken");
        tokenUsdt = (await UsdtMockedToken.deploy(TOTAL_SUPPLY_6_DECIMALS, 6)) as UsdtMockedToken;
        const UsdcMockedToken = await hre.ethers.getContractFactory("UsdcMockedToken");
        tokenUsdc = (await UsdcMockedToken.deploy(TOTAL_SUPPLY_6_DECIMALS, 6)) as UsdcMockedToken;
        const shareToken6DEC = (await UsdcMockedToken.deploy(
            TOTAL_SUPPLY_6_DECIMALS,
            6
        )) as UsdcMockedToken;

        const MockStrategyTestnetFactory = await hre.ethers.getContractFactory(
            "MockStrategyTestnet"
        );
        strategyDai = await upgrades.deployProxy(MockStrategyTestnetFactory, [
            tokenDai.address,
            shareToken18DEC.address,
        ]);

        strategyDai.setStanley(adminAddress);
        strategyUsdc = await upgrades.deployProxy(MockStrategyTestnetFactory, [
            tokenUsdc.address,
            shareToken6DEC.address,
        ]);
        strategyUsdc.setStanley(adminAddress);
        strategyUsdt = await upgrades.deployProxy(MockStrategyTestnetFactory, [
            tokenUsdt.address,
            shareToken18DEC.address,
        ]);
        strategyUsdt.setStanley(adminAddress);

        await tokenDai.approve(strategyDai.address, TOTAL_SUPPLY_18_DECIMALS);
        await tokenUsdc.approve(strategyUsdc.address, TOTAL_SUPPLY_6_DECIMALS);
        await tokenUsdt.approve(strategyUsdt.address, TOTAL_SUPPLY_6_DECIMALS);

        tokenDai.setupInitialAmount(strategyDai.address, USER_SUPPLY_10MLN_18DEC);
        tokenUsdc.setupInitialAmount(strategyUsdc.address, USER_SUPPLY_6_DECIMALS);
        tokenUsdt.setupInitialAmount(strategyUsdt.address, USER_SUPPLY_6_DECIMALS);
        tokenDai.setupInitialAmount(adminAddress, USER_SUPPLY_10MLN_18DEC);
        tokenUsdc.setupInitialAmount(adminAddress, USER_SUPPLY_6_DECIMALS);
        tokenUsdt.setupInitialAmount(adminAddress, USER_SUPPLY_6_DECIMALS);
    });

    it("Should return 3.5% APR", async () => {
        // when
        const aprDai = await strategyDai.getApr();
        const aprUsdc = await strategyUsdc.getApr();
        const aprUsdt = await strategyUsdt.getApr();
        // then

        expect(aprDai).to.be.equal(PERCENTAGE_3_5_18DEC);
        expect(aprUsdc).to.be.equal(PERCENTAGE_3_5_18DEC);
        expect(aprUsdt).to.be.equal(PERCENTAGE_3_5_18DEC);
    });

    it("Shoud deposit into strategy 18 dec", async () => {
        // given
        const strategyBalanceTokenBefore = await tokenDai.balanceOf(strategyDai.address);
        const strategyBalanceBefore = await strategyDai.balanceOf();
        const depositAmount = N10_000.mul(N1__0_18DEC);

        // when
        await strategyDai.deposit(depositAmount);

        // then
        const strategyBalanceTokenAfter = await tokenDai.balanceOf(strategyDai.address);
        const strategyBalanceAfter = await strategyDai.balanceOf();

        expect(strategyBalanceTokenBefore).to.be.equal(USER_SUPPLY_10MLN_18DEC);
        expect(strategyBalanceTokenAfter).to.be.equal(USER_SUPPLY_10MLN_18DEC.add(depositAmount));
        expect(strategyBalanceBefore.lt(strategyBalanceAfter)).to.be.true;
    });

    it("Shoud deposit into strategy 6 dec", async () => {
        // given
        const strategyBalanceTokenBefore = await tokenUsdc.balanceOf(strategyUsdc.address);
        const strategyBalanceBefore = await strategyUsdc.balanceOf();
        const depositAmount = N10_000.mul(N1__0_18DEC);

        // when
        await strategyUsdc.deposit(depositAmount);

        // then
        const strategyBalanceTokenAfter = await tokenUsdc.balanceOf(strategyUsdc.address);
        const strategyBalanceAfter = await strategyUsdc.balanceOf();

        expect(strategyBalanceTokenBefore).to.be.equal(USER_SUPPLY_6_DECIMALS);
        expect(strategyBalanceTokenAfter).to.be.equal(
            USER_SUPPLY_6_DECIMALS.add(N10_000.mul(N1__0_6DEC))
        );
        expect(strategyBalanceBefore.lt(strategyBalanceAfter)).to.be.true;
    });

    it("Should balance increase in time", async () => {
        // given
        const depositAmount = N10_000.mul(N1__0_18DEC);
        await strategyDai.deposit(depositAmount);
        const strategyBalanceBefore = await strategyDai.balanceOf();

        // when
        await hre.network.provider.send("evm_increaseTime", [yearInSeconds]);
        await hre.network.provider.send("evm_mine");

        // then
        const strategyBalanceAfter = await strategyDai.balanceOf();

        expect(strategyBalanceBefore.lt(strategyBalanceAfter));
    });
    it("Should withdraw 18 dec", async () => {
        // given
        const depositAmount = N10_000.mul(N1__0_18DEC);
        await strategyDai.deposit(depositAmount);
        const strategyBalanceBefore = await strategyDai.balanceOf();
        const tokenBalanceBefore = await tokenDai.balanceOf(await admin.getAddress());
        await hre.network.provider.send("evm_increaseTime", [yearInSeconds]);
        await hre.network.provider.send("evm_mine");
        // when
        await strategyDai.withdraw(depositAmount);
        // then
        const strategyBalanceAfter = await strategyDai.balanceOf();
        const tokenBalanceAfter = await tokenDai.balanceOf(await admin.getAddress());

        expect(strategyBalanceBefore.gt(strategyBalanceAfter)).to.be.true;
        expect(tokenBalanceBefore.lt(tokenBalanceAfter)).to.be.true;
    });
    it("Should withdraw 6 dec", async () => {
        // given
        const depositAmount = N10_000.mul(N1__0_18DEC);
        await strategyUsdc.deposit(depositAmount);
        const strategyBalanceBefore = await strategyUsdc.balanceOf();
        const tokenBalanceBefore = await tokenUsdc.balanceOf(await admin.getAddress());
        await hre.network.provider.send("evm_increaseTime", [yearInSeconds]);
        await hre.network.provider.send("evm_mine");
        // when
        await strategyUsdc.withdraw(depositAmount);
        // then
        const strategyBalanceAfter = await strategyUsdc.balanceOf();
        const tokenBalanceAfter = await tokenUsdc.balanceOf(await admin.getAddress());

        expect(strategyBalanceBefore.gt(strategyBalanceAfter)).to.be.true;
        expect(tokenBalanceBefore.lt(tokenBalanceAfter)).to.be.true;
    });
    it("Should withdraw more then deposit 6 dec when intrest was added", async () => {
        // given
        const depositAmount = N10_000.mul(N1__0_18DEC);
        await strategyUsdc.deposit(depositAmount);
        const strategyBalanceBefore = await strategyUsdc.balanceOf();
        const tokenBalanceBefore = await tokenUsdc.balanceOf(await admin.getAddress());
        await hre.network.provider.send("evm_increaseTime", [yearInSeconds]);
        await hre.network.provider.send("evm_mine");
        // when
        await strategyUsdc.withdraw(depositAmount.add(BigNumber.from("100").mul(N1__0_18DEC)));
        // then
        const strategyBalanceAfter = await strategyUsdc.balanceOf();
        const tokenBalanceAfter = await tokenUsdc.balanceOf(await admin.getAddress());

        expect(strategyBalanceBefore.gt(strategyBalanceAfter)).to.be.true;
        expect(tokenBalanceBefore.lt(tokenBalanceAfter)).to.be.true;
    });
    it("Should withdraw more then deposit 18 dec when intrest was added", async () => {
        // given
        const depositAmount = N10_000.mul(N1__0_18DEC);
        await strategyDai.deposit(depositAmount);
        const strategyBalanceBefore = await strategyDai.balanceOf();
        const tokenBalanceBefore = await tokenDai.balanceOf(await admin.getAddress());
        await hre.network.provider.send("evm_increaseTime", [yearInSeconds]);
        await hre.network.provider.send("evm_mine");
        // when
        await strategyDai.withdraw(depositAmount.add(BigNumber.from("100").mul(N1__0_18DEC)));
        // then
        const strategyBalanceAfter = await strategyDai.balanceOf();
        const tokenBalanceAfter = await tokenDai.balanceOf(await admin.getAddress());

        expect(strategyBalanceBefore.gt(strategyBalanceAfter)).to.be.true;
        expect(tokenBalanceBefore.lt(tokenBalanceAfter)).to.be.true;
    });
    it("Should not withdraw 6 dec when not stanley", async () => {
        // given
        const depositAmount = N10_000.mul(N1__0_18DEC);
        await strategyUsdc.deposit(depositAmount);
        // when
        await expect(strategyUsdc.connect(userOne).withdraw(depositAmount)).to.be.revertedWith(
            "IPOR_501"
        );
    });
    it("Should not withdraw 18 dec when not stanley", async () => {
        // given
        const depositAmount = N10_000.mul(N1__0_18DEC);
        await strategyDai.deposit(depositAmount);
        // when
        await expect(strategyDai.connect(userOne).withdraw(depositAmount)).to.be.revertedWith(
            "IPOR_501"
        );
    });
    it("Should not deposit 18 dec when not stanley", async () => {
        // given
        const depositAmount = N10_000.mul(N1__0_18DEC);
        // when
        await expect(strategyDai.connect(userOne).deposit(depositAmount)).to.be.revertedWith(
            "IPOR_501"
        );
    });
    it("Should not deposit 6 dec when not stanley", async () => {
        // given
        const depositAmount = N10_000.mul(N1__0_18DEC);
        // when
        await expect(strategyUsdc.connect(userOne).deposit(depositAmount)).to.be.revertedWith(
            "IPOR_501"
        );
    });
});
