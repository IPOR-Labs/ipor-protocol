import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { MockSpreadModel } from "../../types";
import {
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USD_10_400_18DEC,
    USD_14_000_18DEC,
    PERCENTAGE_3_18DEC,
    USD_14_000_6DEC,
    N1__0_18DEC,
    N0__01_18DEC,
    N1__0_6DEC,
    ZERO,
} from "../utils/Constants";
import { assertError } from "../utils/AssertUtils";
import {
    prepareMockSpreadModel,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
} from "../utils/MiltonUtils";
import {
    prepareTestData,
    prepareTestDataDaiCase000,
    prepareApproveForUsers,
    setupTokenDaiInitialValuesForUsers,
    getStandardDerivativeParamsDAI,
    getReceiveFixedSwapParamsDAI,
    setupTokenUsdtInitialValuesForUsers,
    getStandardDerivativeParamsUSDT,
} from "../utils/DataUtils";

import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

const { expect } = chai;

describe("Joseph Redeem", () => {
    let miltonSpreadModel: MockSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockSpreadModel(
            BigNumber.from(4).mul(N0__01_18DEC),
            BigNumber.from("2").mul(N0__01_18DEC),
            ZERO,
            ZERO
        );
    });

    it("should redeem ipToken - simple case 1 - DAI 18 decimals", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );

        const { josephDai, tokenDai, ipTokenDai, miltonDai } = testData;
        if (
            josephDai === undefined ||
            tokenDai === undefined ||
            ipTokenDai === undefined ||
            miltonDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);
        const assetAmount = USD_14_000_18DEC;
        const withdrawAmount = TC_TOTAL_AMOUNT_10_000_18DEC;

        const redeemFee18Dec = BigNumber.from("50").mul(N1__0_18DEC);
        const expectedIpTokenBalanceSender = BigNumber.from("4000").mul(N1__0_18DEC);
        const expectedStableBalanceMilton = BigNumber.from("4000")
            .mul(N1__0_18DEC)
            .add(redeemFee18Dec);
        const expectedLiquidityProviderStableBalance = BigNumber.from("9996000")
            .mul(N1__0_18DEC)
            .sub(redeemFee18Dec);
        const expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(assetAmount, params.openTimestamp);

        //when
        await josephDai.connect(liquidityProvider).itfRedeem(withdrawAmount, params.openTimestamp);

        //then
        const actualIpTokenBalanceSender = await ipTokenDai.balanceOf(
            await liquidityProvider.getAddress()
        );
        const actualUnderlyingBalanceMilton = await tokenDai.balanceOf(miltonDai.address);
        const actualLiquidityPoolBalanceMilton = await (
            await miltonDai.getAccruedBalance()
        ).liquidityPool;
        const actualUnderlyingBalanceSender = await tokenDai.balanceOf(
            await liquidityProvider.getAddress()
        );
        expect(
            expectedIpTokenBalanceSender,
            `Incorrect ipToken balance on user for asset ${params.asset} actual: ${actualIpTokenBalanceSender}, expected: ${expectedIpTokenBalanceSender}`
        ).to.be.equal(actualIpTokenBalanceSender);

        expect(
            expectedStableBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${expectedStableBalanceMilton}`
        ).to.be.equal(actualUnderlyingBalanceMilton);

        expect(
            expectedLiquidityPoolBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
        ).to.be.equal(actualLiquidityPoolBalanceMilton);

        expect(
            expectedLiquidityProviderStableBalance,
            `Incorrect DAI balance on Liquidity Provider for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
        ).to.be.equal(actualUnderlyingBalanceSender);
    });

    it("should redeem ipToken - simple case 1 - USDT 6 decimals", async () => {
        //given
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            [],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE0,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            testData
        );

        const { josephUsdt, tokenUsdt, ipTokenUsdt, miltonUsdt } = testData;
        if (
            josephUsdt === undefined ||
            tokenUsdt === undefined ||
            ipTokenUsdt === undefined ||
            miltonUsdt === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );
        const params = getStandardDerivativeParamsUSDT(userTwo, tokenUsdt);
        const assetAmount = USD_14_000_6DEC;
        const withdrawIpTokenAmount = TC_TOTAL_AMOUNT_10_000_18DEC;
        const redeemFee18Dec = BigNumber.from("50").mul(N1__0_18DEC);
        const redeemFee6Dec = BigNumber.from("50").mul(N1__0_6DEC);
        const expectedIpTokenBalanceSender = BigNumber.from("4000").mul(N1__0_18DEC);
        const expectedStableBalanceMilton = BigNumber.from("4000")
            .mul(N1__0_6DEC)
            .add(redeemFee6Dec);
        const expectedLiquidityProviderStableBalance = BigNumber.from("9996000")
            .mul(N1__0_6DEC)
            .sub(redeemFee6Dec);
        const expectedLiquidityPoolBalanceMilton = BigNumber.from("4000")
            .mul(N1__0_18DEC)
            .add(redeemFee18Dec);

        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(assetAmount, params.openTimestamp);

        //when
        await josephUsdt
            .connect(liquidityProvider)
            .itfRedeem(withdrawIpTokenAmount, params.openTimestamp);

        //then
        const actualIpTokenBalanceSender = await ipTokenUsdt.balanceOf(
            await liquidityProvider.getAddress()
        );
        const actualUnderlyingBalanceMilton = BigNumber.from(
            await tokenUsdt.balanceOf(miltonUsdt.address)
        );
        const actualLiquidityPoolBalanceMilton = BigNumber.from(
            await (
                await miltonUsdt.getAccruedBalance()
            ).liquidityPool
        );
        const actualUnderlyingBalanceSender = BigNumber.from(
            await tokenUsdt.balanceOf(await liquidityProvider.getAddress())
        );

        expect(
            expectedIpTokenBalanceSender,
            `Incorrect ipToken balance on user for asset ${params.asset} actual: ${actualIpTokenBalanceSender}, expected: ${expectedIpTokenBalanceSender}`
        ).to.be.equal(actualIpTokenBalanceSender);

        expect(
            expectedStableBalanceMilton,
            `Incorrect USDT balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${expectedStableBalanceMilton}`
        ).to.be.equal(actualUnderlyingBalanceMilton);

        expect(
            expectedLiquidityPoolBalanceMilton,
            `Incorrect USDT Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
        ).to.be.equal(actualLiquidityPoolBalanceMilton);

        expect(
            expectedLiquidityProviderStableBalance,
            `Incorrect USDT balance on Liquidity Provider for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
        ).to.be.equal(actualUnderlyingBalanceSender);
    });

    it("should redeem ipTokens because NO validation for cool off period", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );

        const { josephDai, tokenDai, ipTokenDai, miltonDai } = testData;
        if (
            josephDai === undefined ||
            tokenDai === undefined ||
            ipTokenDai === undefined ||
            miltonDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const assetAmount = USD_14_000_18DEC;
        const withdrawAmount = TC_TOTAL_AMOUNT_10_000_18DEC;

        const timestamp = Math.floor(Date.now() / 1000);

        await josephDai.connect(liquidityProvider).itfProvideLiquidity(assetAmount, timestamp);

        //when
        await josephDai.connect(liquidityProvider).itfRedeem(withdrawAmount, timestamp);

        const redeemFee18Dec = BigNumber.from("50").mul(N1__0_18DEC);

        const expectedIpTokenBalanceSender = BigNumber.from("4000").mul(N1__0_18DEC);
        const expectedStableBalanceMilton = BigNumber.from("4000")
            .mul(N1__0_18DEC)
            .add(redeemFee18Dec);
        const expectedLiquidityProviderStableBalance = BigNumber.from("9996000")
            .mul(N1__0_18DEC)
            .sub(redeemFee18Dec);
        const expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

        //then
        const actualIpTokenBalanceSender = BigNumber.from(
            await ipTokenDai.balanceOf(await liquidityProvider.getAddress())
        );

        const actualUnderlyingBalanceMilton = await tokenDai.balanceOf(miltonDai.address);
        const actualLiquidityPoolBalanceMilton = await (
            await miltonDai.getAccruedBalance()
        ).liquidityPool;
        const actualUnderlyingBalanceSender = await tokenDai.balanceOf(
            await liquidityProvider.getAddress()
        );
        expect(
            expectedIpTokenBalanceSender,
            `Incorrect ipToken balance on user for asset ${tokenDai.address} actual: ${actualIpTokenBalanceSender}, expected: ${expectedIpTokenBalanceSender}`
        ).to.be.equal(actualIpTokenBalanceSender);

        expect(
            expectedStableBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${tokenDai.address} actual: ${actualUnderlyingBalanceMilton}, expected: ${expectedStableBalanceMilton}`
        ).to.be.equal(actualUnderlyingBalanceMilton);

        expect(
            expectedLiquidityPoolBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${tokenDai.address} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
        ).to.be.equal(actualLiquidityPoolBalanceMilton);

        expect(
            expectedLiquidityProviderStableBalance,
            `Incorrect DAI balance on Liquidity Provider for asset ${tokenDai.address} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
        ).to.be.equal(actualUnderlyingBalanceSender);
    });

    it("should redeem ipTokens, two times provided liquidity", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );

        const { josephDai, tokenDai, ipTokenDai, miltonDai } = testData;
        if (
            josephDai === undefined ||
            tokenDai === undefined ||
            ipTokenDai === undefined ||
            miltonDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(TC_TOTAL_AMOUNT_10_000_18DEC, timestamp);
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(TC_TOTAL_AMOUNT_10_000_18DEC, timestamp);

        //when
        await josephDai.connect(liquidityProvider).itfRedeem(USD_14_000_18DEC, timestamp);

        //then
        const redeemFee18Dec = BigNumber.from("70").mul(N1__0_18DEC);

        const expectedIpTokenBalanceSender = BigNumber.from("6000").mul(N1__0_18DEC);
        const expectedStableBalanceMilton = BigNumber.from("6000")
            .mul(N1__0_18DEC)
            .add(redeemFee18Dec);
        const expectedLiquidityProviderStableBalance = BigNumber.from("9994000")
            .mul(N1__0_18DEC)
            .sub(redeemFee18Dec);
        const expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

        const actualIpTokenBalanceSender = await ipTokenDai.balanceOf(
            await liquidityProvider.getAddress()
        );
        const actualUnderlyingBalanceMilton = await tokenDai.balanceOf(miltonDai.address);
        const actualLiquidityPoolBalanceMilton = await (
            await miltonDai.getAccruedBalance()
        ).liquidityPool;
        const actualUnderlyingBalanceSender = await tokenDai.balanceOf(
            await liquidityProvider.getAddress()
        );
        expect(
            expectedIpTokenBalanceSender,
            `Incorrect ipToken balance on user for asset ${tokenDai.address} actual: ${actualIpTokenBalanceSender}, expected: ${expectedIpTokenBalanceSender}`
        ).to.be.equal(actualIpTokenBalanceSender);

        expect(
            expectedStableBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${tokenDai.address} actual: ${actualUnderlyingBalanceMilton}, expected: ${expectedStableBalanceMilton}`
        ).to.be.equal(actualUnderlyingBalanceMilton);

        expect(
            expectedLiquidityPoolBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${tokenDai.address} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
        ).to.be.equal(actualLiquidityPoolBalanceMilton);

        expect(
            expectedLiquidityProviderStableBalance,
            `Incorrect DAI balance on Liquidity Provider for asset ${tokenDai.address} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
        ).to.be.equal(actualUnderlyingBalanceSender);
    });

    it("should redeem ipDAI, should redeem ipUSDT - simple case 1", async () => {
        //given
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI", "USDT"],
            [],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE0,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );

        const {
            josephUsdt,
            tokenUsdt,
            ipTokenUsdt,
            miltonUsdt,
            josephDai,
            ipTokenDai,
            tokenDai,
            miltonDai,
        } = testData;
        if (
            josephUsdt === undefined ||
            tokenUsdt === undefined ||
            ipTokenUsdt === undefined ||
            miltonUsdt === undefined ||
            josephDai === undefined ||
            ipTokenDai === undefined ||
            tokenDai == undefined ||
            miltonDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        const assetAmountDAI = USD_14_000_18DEC;
        const withdrawIpTokenAmountDAI = TC_TOTAL_AMOUNT_10_000_18DEC;

        const assetAmountUSDT = USD_14_000_6DEC;
        const withdrawIpTokenAmountUSDT = TC_TOTAL_AMOUNT_10_000_18DEC;

        const redeemFee18Dec = BigNumber.from("50").mul(N1__0_18DEC);
        const redeemFee6Dec = BigNumber.from("50").mul(N1__0_6DEC);

        const expectedIpDAIBalanceSender = BigNumber.from("4000").mul(N1__0_18DEC);
        const expectedDAIBalanceMilton = BigNumber.from("4000")
            .mul(N1__0_18DEC)
            .add(redeemFee18Dec);
        const expectedLiquidityProviderDAIBalance = BigNumber.from("9996000")
            .mul(N1__0_18DEC)
            .sub(redeemFee18Dec);
        const expectedLiquidityPoolDAIBalanceMilton = expectedDAIBalanceMilton;

        const expectedIpUSDTBalanceSender = BigNumber.from("4000").mul(N1__0_18DEC);
        const expectedUSDTBalanceMilton = BigNumber.from("4000").mul(N1__0_6DEC).add(redeemFee6Dec);
        const expectedLiquidityProviderUSDTBalance = BigNumber.from("9996000")
            .mul(N1__0_6DEC)
            .sub(redeemFee6Dec);
        const expectedLiquidityPoolUSDTBalanceMilton = BigNumber.from("4000")
            .mul(N1__0_18DEC)
            .add(redeemFee18Dec);

        const timestamp = Math.floor(Date.now() / 1000);

        await josephDai.connect(liquidityProvider).itfProvideLiquidity(assetAmountDAI, timestamp);
        await josephUsdt.connect(liquidityProvider).itfProvideLiquidity(assetAmountUSDT, timestamp);

        //when
        await josephDai.connect(liquidityProvider).itfRedeem(withdrawIpTokenAmountDAI, timestamp);
        await josephUsdt.connect(liquidityProvider).itfRedeem(withdrawIpTokenAmountUSDT, timestamp);

        //then
        const actualIpDAIBalanceSender = await ipTokenDai.balanceOf(
            await liquidityProvider.getAddress()
        );
        const actualDAIBalanceMilton = await tokenDai.balanceOf(miltonDai.address);
        const actualLiquidityPoolDAIBalanceMilton = await (
            await miltonDai.getAccruedBalance()
        ).liquidityPool;
        const actualDAIBalanceSender = await tokenDai.balanceOf(
            await liquidityProvider.getAddress()
        );
        expect(
            expectedIpDAIBalanceSender,
            `Incorrect ipToken DAI balance on user for asset ${tokenDai.address} actual: ${actualIpDAIBalanceSender}, expected: ${expectedIpDAIBalanceSender}`
        ).to.be.equal(actualIpDAIBalanceSender);

        expect(
            expectedDAIBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${tokenDai.address} actual: ${actualDAIBalanceMilton}, expected: ${expectedDAIBalanceMilton}`
        ).to.be.equal(actualDAIBalanceMilton);

        expect(
            expectedLiquidityPoolDAIBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${tokenDai.address} actual: ${actualLiquidityPoolDAIBalanceMilton}, expected: ${expectedLiquidityPoolDAIBalanceMilton}`
        ).to.be.equal(actualLiquidityPoolDAIBalanceMilton);

        expect(
            expectedLiquidityProviderDAIBalance,
            `Incorrect DAI balance on Liquidity Provider for asset ${tokenDai.address} actual: ${actualDAIBalanceSender}, expected: ${expectedLiquidityProviderDAIBalance}`
        ).to.be.equal(actualDAIBalanceSender);

        const actualIpUSDTBalanceSender = await ipTokenUsdt.balanceOf(
            await liquidityProvider.getAddress()
        );
        const actualUSDTBalanceMilton = await tokenUsdt.balanceOf(miltonUsdt.address);
        const actualLiquidityPoolUSDTBalanceMilton = await (
            await miltonUsdt.getAccruedBalance()
        ).liquidityPool;
        const actualUSDTBalanceSender = await tokenUsdt.balanceOf(
            await liquidityProvider.getAddress()
        );
        expect(
            expectedIpUSDTBalanceSender,
            `Incorrect ipToken USDT balance on user for asset ${tokenUsdt.address} actual: ${actualIpUSDTBalanceSender}, expected: ${expectedIpUSDTBalanceSender}`
        ).to.be.equal(actualIpUSDTBalanceSender);

        expect(
            expectedUSDTBalanceMilton,
            `Incorrect USDT balance on Milton for asset ${tokenUsdt.address} actual: ${actualUSDTBalanceMilton}, expected: ${expectedUSDTBalanceMilton}`
        ).to.be.equal(actualUSDTBalanceMilton);

        expect(
            expectedLiquidityPoolUSDTBalanceMilton,
            `Incorrect USDT Liquidity Pool Balance on Milton for asset ${tokenUsdt.address} actual: ${actualLiquidityPoolUSDTBalanceMilton}, expected: ${expectedLiquidityPoolUSDTBalanceMilton}`
        ).to.be.equal(actualLiquidityPoolUSDTBalanceMilton);

        expect(
            expectedLiquidityProviderUSDTBalance,
            `Incorrect USDT balance on Liquidity Provider for asset ${tokenUsdt.address} actual: ${actualUSDTBalanceSender}, expected: ${expectedLiquidityProviderUSDTBalance}`
        ).to.be.equal(actualUSDTBalanceSender);
    });

    it("should redeem ipDAI, should redeem ipUSDT, two users - simple case 1", async () => {
        //given
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI", "USDT"],
            [],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE0,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            testData
        );

        const {
            josephUsdt,
            tokenUsdt,
            ipTokenUsdt,
            miltonUsdt,
            josephDai,
            ipTokenDai,
            tokenDai,
            miltonDai,
        } = testData;
        if (
            josephUsdt === undefined ||
            tokenUsdt === undefined ||
            ipTokenUsdt === undefined ||
            miltonUsdt === undefined ||
            josephDai === undefined ||
            ipTokenDai === undefined ||
            tokenDai == undefined ||
            miltonDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        const assetAmountDAI = USD_14_000_18DEC;
        const withdrawIpTokenAmountDAI = TC_TOTAL_AMOUNT_10_000_18DEC;
        const assetAmountUSDT = USD_14_000_6DEC;
        const withdrawIpTokenAmountUSDT = TC_TOTAL_AMOUNT_10_000_18DEC;

        const redeemFee18Dec = BigNumber.from("50").mul(N1__0_18DEC);
        const redeemFee6Dec = BigNumber.from("50").mul(N1__0_6DEC);
        const expectedIpDAIBalanceSender = BigNumber.from("4000").mul(N1__0_18DEC);
        const expectedDAIBalanceMilton = BigNumber.from("4000")
            .mul(N1__0_18DEC)
            .add(redeemFee18Dec);
        const expectedLiquidityProviderDAIBalance = BigNumber.from("9996000")
            .mul(N1__0_18DEC)
            .sub(redeemFee18Dec);
        const expectedLiquidityPoolDAIBalanceMilton = expectedDAIBalanceMilton;

        const expectedIpUSDTBalanceSender = BigNumber.from("4000").mul(N1__0_18DEC);
        const expectedUSDTBalanceMilton = BigNumber.from("4000").mul(N1__0_6DEC).add(redeemFee6Dec);
        const expectedLiquidityProviderUSDTBalance = BigNumber.from("9996000")
            .mul(N1__0_6DEC)
            .sub(redeemFee6Dec);
        const expectedLiquidityPoolUSDTBalanceMilton = BigNumber.from("4000")
            .mul(N1__0_18DEC)
            .add(redeemFee18Dec);

        const daiUser = userOne;
        const usdtUser = userTwo;

        const timestamp = Math.floor(Date.now() / 1000);

        await josephDai.connect(daiUser).itfProvideLiquidity(assetAmountDAI, timestamp);

        await josephUsdt.connect(usdtUser).itfProvideLiquidity(assetAmountUSDT, timestamp);

        //when
        await josephDai.connect(daiUser).itfRedeem(withdrawIpTokenAmountDAI, timestamp);
        await josephUsdt.connect(usdtUser).itfRedeem(withdrawIpTokenAmountUSDT, timestamp);

        //then
        const actualIpDAIBalanceSender = await ipTokenDai.balanceOf(await daiUser.getAddress());
        const actualDAIBalanceMilton = await tokenDai.balanceOf(miltonDai.address);
        const actualLiquidityPoolDAIBalanceMilton = await (
            await miltonDai.getAccruedBalance()
        ).liquidityPool;
        const actualDAIBalanceSender = await tokenDai.balanceOf(await daiUser.getAddress());

        expect(
            expectedIpDAIBalanceSender,
            `Incorrect ipToken DAI balance on user for asset ${tokenDai.address} actual: ${actualIpDAIBalanceSender}, expected: ${expectedIpDAIBalanceSender}`
        ).to.be.equal(actualIpDAIBalanceSender);

        expect(
            expectedDAIBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${tokenDai.address} actual: ${actualDAIBalanceMilton}, expected: ${expectedDAIBalanceMilton}`
        ).to.be.equal(actualDAIBalanceMilton);

        expect(
            expectedLiquidityPoolDAIBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${tokenDai.address} actual: ${actualLiquidityPoolDAIBalanceMilton}, expected: ${expectedLiquidityPoolDAIBalanceMilton}`
        ).to.be.equal(actualLiquidityPoolDAIBalanceMilton);

        expect(
            expectedLiquidityProviderDAIBalance,
            `Incorrect DAI balance on Liquidity Provider for asset ${tokenDai.address} actual: ${actualDAIBalanceSender}, expected: ${expectedLiquidityProviderDAIBalance}`
        ).to.be.equal(actualDAIBalanceSender);

        const actualIpUSDTBalanceSender = await ipTokenUsdt.balanceOf(await usdtUser.getAddress());
        const actualUSDTBalanceMilton = BigNumber.from(
            await tokenUsdt.balanceOf(miltonUsdt.address)
        );

        const actualLiquidityPoolUSDTBalanceMilton = await (
            await miltonUsdt.getAccruedBalance()
        ).liquidityPool;
        const actualUSDTBalanceSender = await tokenUsdt.balanceOf(await usdtUser.getAddress());

        expect(
            expectedIpUSDTBalanceSender,
            `Incorrect ipToken USDT balance on user for asset ${tokenUsdt.address} actual: ${actualIpUSDTBalanceSender}, expected: ${expectedIpUSDTBalanceSender}`
        ).to.be.equal(actualIpUSDTBalanceSender);

        expect(
            expectedUSDTBalanceMilton,
            `Incorrect USDT balance on Milton for asset ${tokenUsdt.address} actual: ${actualUSDTBalanceMilton}, expected: ${expectedUSDTBalanceMilton}`
        ).to.be.equal(actualUSDTBalanceMilton);

        expect(
            expectedLiquidityPoolUSDTBalanceMilton,
            `Incorrect USDT Liquidity Pool Balance on Milton for asset ${tokenUsdt.address} actual: ${actualLiquidityPoolUSDTBalanceMilton}, expected: ${expectedLiquidityPoolUSDTBalanceMilton}`
        ).to.be.equal(actualLiquidityPoolUSDTBalanceMilton);

        expect(
            expectedLiquidityProviderUSDTBalance,
            `Incorrect USDT balance on Liquidity Provider for asset ${tokenUsdt.address} actual: ${actualUSDTBalanceSender}, expected: ${expectedLiquidityProviderUSDTBalance}`
        ).to.be.equal(actualUSDTBalanceSender);
    });

    it("should redeem - Liquidity Provider can transfer tokens to other user, user can redeem tokens", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const { josephDai, ipTokenDai, tokenDai, miltonDai } = testData;
        if (
            josephDai === undefined ||
            ipTokenDai === undefined ||
            tokenDai == undefined ||
            miltonDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));
        await josephDai.connect(liquidityProvider).itfProvideLiquidity(USD_10_400_18DEC, timestamp);

        await ipTokenDai
            .connect(liquidityProvider)
            .transfer(await userThree.getAddress(), TC_TOTAL_AMOUNT_10_000_18DEC);

        await josephDai.connect(userThree).itfRedeem(TC_TOTAL_AMOUNT_10_000_18DEC, timestamp);
        const redeemFee = BigNumber.from("50").mul(N1__0_18DEC);
        const expectedDAIBalanceMilton = BigNumber.from("400").mul(N1__0_18DEC).add(redeemFee);
        const expectedDAIBalanceMiltonLiquidityPool = expectedDAIBalanceMilton;

        const expectedIpDAIBalanceLiquidityProvider = BigNumber.from("400").mul(N1__0_18DEC);
        const expectedDAIBalanceLiquidityProvider = BigNumber.from("9989600").mul(N1__0_18DEC);

        const expectedIpDAIBalanceUserThree = ZERO;
        const expectedDAIBalanceUserThree = BigNumber.from("10010000")
            .mul(N1__0_18DEC)
            .sub(redeemFee);

        const actualDAIBalanceMilton = await tokenDai.balanceOf(miltonDai.address);
        const actualDAIBalanceMiltonLiquidityPool = await (
            await miltonDai.getAccruedBalance()
        ).liquidityPool;
        const actualIpDAIBalanceLiquidityProvider = await ipTokenDai.balanceOf(
            await liquidityProvider.getAddress()
        );
        const actualDAIBalanceLiquidityProvider = await tokenDai.balanceOf(
            await liquidityProvider.getAddress()
        );
        const actualIpDAIBalanceUserThree = await ipTokenDai.balanceOf(
            await userThree.getAddress()
        );
        const actualDAIBalanceUserThree = await tokenDai.balanceOf(await userThree.getAddress());
        expect(
            expectedDAIBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${tokenDai.address} actual: ${actualDAIBalanceMilton}, expected: ${expectedDAIBalanceMilton}`
        ).to.be.equal(actualDAIBalanceMilton);
        expect(
            expectedDAIBalanceMiltonLiquidityPool,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${tokenDai.address} actual: ${actualDAIBalanceMiltonLiquidityPool}, expected: ${expectedDAIBalanceMiltonLiquidityPool}`
        ).to.be.equal(actualDAIBalanceMiltonLiquidityPool);

        expect(
            expectedIpDAIBalanceLiquidityProvider,
            `Incorrect ipToken DAI balance on Liquidity Provider for asset ${tokenDai.address} actual: ${actualIpDAIBalanceLiquidityProvider}, expected: ${expectedIpDAIBalanceLiquidityProvider}`
        ).to.be.equal(actualIpDAIBalanceLiquidityProvider);
        expect(
            expectedDAIBalanceLiquidityProvider,
            `Incorrect DAI balance on Liquidity Provider for asset ${tokenDai.address} actual: ${actualDAIBalanceLiquidityProvider}, expected: ${expectedDAIBalanceLiquidityProvider}`
        ).to.be.equal(actualDAIBalanceLiquidityProvider);

        expect(
            expectedIpDAIBalanceUserThree,
            `Incorrect ipToken DAI balance on user for asset ${tokenDai.address} actual: ${actualIpDAIBalanceUserThree}, expected: ${expectedIpDAIBalanceUserThree}`
        ).to.be.equal(actualIpDAIBalanceUserThree);
        expect(
            expectedDAIBalanceUserThree,
            `Incorrect DAI balance on user for asset ${tokenDai.address} actual: ${actualDAIBalanceUserThree}, expected: ${expectedDAIBalanceUserThree}`
        ).to.be.equal(actualDAIBalanceUserThree);
    });

    it("should redeem - Liquidity Pool Utilization not exceedeed, Redeem Liquidity Pool Utilization not exceeded, Pay Fixed", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );

        const { josephDai, ipTokenDai, tokenDai, miltonDai, iporOracle } = testData;
        if (
            josephDai === undefined ||
            ipTokenDai === undefined ||
            tokenDai == undefined ||
            miltonDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from("100000").mul(N1__0_18DEC), params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigNumber.from("27000").mul(N1__0_18DEC),
                params.acceptableFixedInterestRate,
                params.leverage
            );

        const balance = await miltonDai.getAccruedBalance();
        const actualCollateral = balance.totalCollateralPayFixed.add(
            balance.totalCollateralReceiveFixed
        );
        const actualLiquidityPoolBalance = balance.liquidityPool;

        //when
        await josephDai
            .connect(liquidityProvider)
            .itfRedeem(BigNumber.from("51000").mul(N1__0_18DEC), params.openTimestamp);

        //then
        //this line is not achieved if redeem failed
        const actualIpTokenBalanceSender = await ipTokenDai.balanceOf(
            await liquidityProvider.getAddress()
        );
        expect(
            actualCollateral.lt(actualLiquidityPoolBalance),
            "Actual collateral cannot be higher than actual Liquidity Pool Balance"
        ).to.be.true;

        expect(actualIpTokenBalanceSender).to.be.eq(BigNumber.from("49000").mul(N1__0_18DEC));
    });

    it("should redeem - Liquidity Pool Utilization not exceedeed, Redeem Liquidity Pool Utilization not exceeded, Receive Fixed", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );

        const { josephDai, ipTokenDai, tokenDai, miltonDai, iporOracle } = testData;
        if (
            josephDai === undefined ||
            ipTokenDai === undefined ||
            tokenDai == undefined ||
            miltonDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const params = getReceiveFixedSwapParamsDAI(userTwo, tokenDai);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from("100000").mul(N1__0_18DEC), params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                BigNumber.from("40000").mul(N1__0_18DEC),
                params.acceptableFixedInterestRate,
                params.leverage
            );

        const balance = await miltonDai.getAccruedBalance();
        const actualCollateral = balance.totalCollateralPayFixed.add(
            balance.totalCollateralReceiveFixed
        );
        const actualLiquidityPoolBalance = BigNumber.from(balance.liquidityPool);

        //when
        await josephDai
            .connect(liquidityProvider)
            .itfRedeem(BigNumber.from("51000").mul(N1__0_18DEC), params.openTimestamp);

        //then
        //this line is not achieved if redeem failed
        const actualIpTokenBalanceSender = await ipTokenDai.balanceOf(
            await liquidityProvider.getAddress()
        );
        expect(
            actualCollateral.lt(actualLiquidityPoolBalance),
            "Actual collateral cannot be higher than actual Liquidity Pool Balance"
        ).to.be.true;

        expect(actualIpTokenBalanceSender).to.be.eq(BigNumber.from("49000").mul(N1__0_18DEC));
    });

    it("should redeem - Liquidity Pool Utilization exceeded, Redeem Liquidity Pool Utilization not exceeded, Pay Fixed", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const { josephDai, ipTokenDai, tokenDai, miltonDai, iporOracle } = testData;
        if (
            josephDai === undefined ||
            ipTokenDai === undefined ||
            tokenDai == undefined ||
            miltonDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from("100000").mul(N1__0_18DEC), params.openTimestamp);

        //position which utilizates 48% per leg
        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigNumber.from("48000").mul(N1__0_18DEC),
                params.acceptableFixedInterestRate,
                params.leverage
            );

        //first small redeem
        await josephDai
            .connect(liquidityProvider)
            .itfRedeem(BigNumber.from("10000").mul(N1__0_18DEC), params.openTimestamp);

        //presentation that currently liquidity pool utilization for opening position is achieved
        await assertError(
            miltonDai
                .connect(userTwo)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    BigNumber.from("50").mul(N1__0_18DEC),
                    params.acceptableFixedInterestRate,
                    params.leverage
                ),
            "IPOR_303"
        );

        //when
        await josephDai
            .connect(liquidityProvider)
            .itfRedeem(BigNumber.from("10300").mul(N1__0_18DEC), params.openTimestamp);

        //then
        //this line is not achieved if redeem failed
        const actualIpTokenBalanceSender = await ipTokenDai.balanceOf(
            await liquidityProvider.getAddress()
        );
        expect(actualIpTokenBalanceSender).to.be.eq(BigNumber.from("79700").mul(N1__0_18DEC));
    });
    it("should redeem - Liquidity Pool Utilization exceeded, Redeem Liquidity Pool Utilization not exceeded, Receive Fixed", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );

        const { josephDai, ipTokenDai, tokenDai, miltonDai, iporOracle } = testData;
        if (
            josephDai === undefined ||
            ipTokenDai === undefined ||
            tokenDai == undefined ||
            miltonDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const params = getReceiveFixedSwapParamsDAI(userTwo, tokenDai);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from("100000").mul(N1__0_18DEC), params.openTimestamp);

        //position which utilizates 48% per leg
        await miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                BigNumber.from("48000").mul(N1__0_18DEC),
                params.acceptableFixedInterestRate,
                params.leverage
            );

        //first small redeem
        await josephDai
            .connect(liquidityProvider)
            .itfRedeem(BigNumber.from("10000").mul(N1__0_18DEC), params.openTimestamp);

        //presentation that currently liquidity pool utilization for opening position is achieved
        await assertError(
            miltonDai
                .connect(userTwo)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    BigNumber.from("50").mul(N1__0_18DEC),
                    params.acceptableFixedInterestRate,
                    params.leverage
                ),
            "IPOR_303"
        );

        //when
        await josephDai
            .connect(liquidityProvider)
            .itfRedeem(BigNumber.from("10300").mul(N1__0_18DEC), params.openTimestamp);

        //then
        //this line is not achieved if redeem failed
        const actualIpTokenBalanceSender = BigNumber.from(
            await ipTokenDai.balanceOf(await liquidityProvider.getAddress())
        );
        expect(actualIpTokenBalanceSender).to.be.eq(BigNumber.from("79700").mul(N1__0_18DEC));
    });
});
