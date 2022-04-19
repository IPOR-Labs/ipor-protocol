import hre from "hardhat";
import chai from "chai";
import { BigNumber, Signer } from "ethers";
import { UsdtMockedToken, DaiMockedToken, UsdcMockedToken, TestnetFaucet } from "../../types";
import {
    N1__0_18DEC,
    N1__0_6DEC,
    TOTAL_SUPPLY_18_DECIMALS,
    TOTAL_SUPPLY_6_DECIMALS,
    USER_SUPPLY_10MLN_18DEC,
    USER_SUPPLY_6_DECIMALS,
    ZERO,
} from "../utils/Constants";

const { expect } = chai;

describe("IvToken", () => {
    let admin: Signer, userOne: Signer, userTwo: Signer, userThree: Signer;
    let tokenDai: DaiMockedToken;
    let tokenUsdt: UsdtMockedToken;
    let tokenUsdc: UsdcMockedToken;
    let testnetFaucet: TestnetFaucet;
    const N100_000 = BigNumber.from("100000");
    const N10_000 = BigNumber.from("10000");

    before(async () => {
        [admin, userOne, userTwo, userThree] = await hre.ethers.getSigners();
    });

    beforeEach(async () => {
        const DaiMockedToken = await hre.ethers.getContractFactory("DaiMockedToken");
        tokenDai = (await DaiMockedToken.deploy(TOTAL_SUPPLY_18_DECIMALS, 18)) as DaiMockedToken;
        const UsdtMockedToken = await hre.ethers.getContractFactory("UsdtMockedToken");
        tokenUsdt = (await UsdtMockedToken.deploy(TOTAL_SUPPLY_6_DECIMALS, 6)) as UsdtMockedToken;
        const UsdcMockedToken = await hre.ethers.getContractFactory("UsdcMockedToken");
        tokenUsdc = (await UsdcMockedToken.deploy(TOTAL_SUPPLY_6_DECIMALS, 6)) as UsdcMockedToken;

        const TestnetFaucetFactory = await hre.ethers.getContractFactory("TestnetFaucet");
        testnetFaucet = await upgrades.deployProxy(TestnetFaucetFactory, [
            tokenDai.address,
            tokenUsdc.address,
            tokenUsdt.address,
        ]);

        tokenDai.setupInitialAmount(testnetFaucet.address, USER_SUPPLY_10MLN_18DEC);
        tokenUsdc.setupInitialAmount(testnetFaucet.address, USER_SUPPLY_6_DECIMALS);
        tokenUsdt.setupInitialAmount(testnetFaucet.address, USER_SUPPLY_6_DECIMALS);
    });

    it("Should claim 100 000", async () => {
        // Given
        const daiBalanceBefore = await tokenDai.balanceOf(await userOne.getAddress());
        const usdcBalanceBefore = await tokenUsdc.balanceOf(await userOne.getAddress());
        const usdtBalanceBefore = await tokenUsdt.balanceOf(await userOne.getAddress());

        // When
        await testnetFaucet.connect(userOne).claim();

        // Then
        const daiBalanceAfter = await tokenDai.balanceOf(await userOne.getAddress());
        const usdcBalanceAfter = await tokenUsdc.balanceOf(await userOne.getAddress());
        const usdtBalanceAfter = await tokenUsdt.balanceOf(await userOne.getAddress());

        expect(daiBalanceBefore).to.be.equal(ZERO);
        expect(usdcBalanceBefore).to.be.equal(ZERO);
        expect(usdtBalanceBefore).to.be.equal(ZERO);

        expect(daiBalanceAfter, "daiBalanceAfter").to.be.equal(N1__0_18DEC.mul(N100_000));
        expect(usdcBalanceAfter, "usdcBalanceAfter").to.be.equal(N1__0_6DEC.mul(N100_000));
        expect(usdtBalanceAfter, "usdtBalanceAfter").to.be.equal(N1__0_6DEC.mul(N100_000));
    });

    it("Should not be able to claim twice", async () => {
        // Given
        const daiBalanceBefore = await tokenDai.balanceOf(await userOne.getAddress());
        const usdcBalanceBefore = await tokenUsdc.balanceOf(await userOne.getAddress());
        const usdtBalanceBefore = await tokenUsdt.balanceOf(await userOne.getAddress());

        // When
        await testnetFaucet.connect(userOne).claim();
        const changeTime = 1000;
        await hre.network.provider.send("evm_increaseTime", [changeTime]);
        await hre.network.provider.send("evm_mine");
        const timeToNextClaim = await testnetFaucet.connect(userOne).couldClaimInSeconds();
        await expect(testnetFaucet.connect(userOne).claim()).to.be.revertedWith("IPOR_600");

        // Then
        const daiBalanceAfter = await tokenDai.balanceOf(await userOne.getAddress());
        const usdcBalanceAfter = await tokenUsdc.balanceOf(await userOne.getAddress());
        const usdtBalanceAfter = await tokenUsdt.balanceOf(await userOne.getAddress());

        expect(daiBalanceBefore).to.be.equal(ZERO);
        expect(usdcBalanceBefore).to.be.equal(ZERO);
        expect(usdtBalanceBefore).to.be.equal(ZERO);

        expect(daiBalanceAfter, "daiBalanceAfter").to.be.equal(N1__0_18DEC.mul(N100_000));
        expect(usdcBalanceAfter, "usdcBalanceAfter").to.be.equal(N1__0_6DEC.mul(N100_000));
        expect(usdtBalanceAfter, "usdtBalanceAfter").to.be.equal(N1__0_6DEC.mul(N100_000));
        expect(timeToNextClaim.gt(ZERO), "timeToNextClaim").to.be.true;
    });

    it("Should claim 110 000", async () => {
        // Given
        const daiBalanceBefore = await tokenDai.balanceOf(await userOne.getAddress());
        const usdcBalanceBefore = await tokenUsdc.balanceOf(await userOne.getAddress());
        const usdtBalanceBefore = await tokenUsdt.balanceOf(await userOne.getAddress());

        // When
        await testnetFaucet.connect(userOne).claim();
        const changeTime = 60 * 60 * 24 + 100;

        await hre.network.provider.send("evm_increaseTime", [changeTime]);
        await hre.network.provider.send("evm_mine");
        const timeToNextClaim = await testnetFaucet.connect(userOne).couldClaimInSeconds();
        await testnetFaucet.connect(userOne).claim();

        // Then
        const daiBalanceAfter = await tokenDai.balanceOf(await userOne.getAddress());
        const usdcBalanceAfter = await tokenUsdc.balanceOf(await userOne.getAddress());
        const usdtBalanceAfter = await tokenUsdt.balanceOf(await userOne.getAddress());

        expect(daiBalanceBefore).to.be.equal(ZERO);
        expect(usdcBalanceBefore).to.be.equal(ZERO);
        expect(usdtBalanceBefore).to.be.equal(ZERO);

        expect(daiBalanceAfter, "daiBalanceAfter").to.be.equal(
            N1__0_18DEC.mul(N100_000.add(N10_000))
        );
        expect(usdcBalanceAfter, "usdcBalanceAfter").to.be.equal(
            N1__0_6DEC.mul(N100_000.add(N10_000))
        );
        expect(usdtBalanceAfter, "usdtBalanceAfter").to.be.equal(
            N1__0_6DEC.mul(N100_000.add(N10_000))
        );
        expect(timeToNextClaim, "timeToNextClaim").to.be.equal(ZERO);
    });
});
