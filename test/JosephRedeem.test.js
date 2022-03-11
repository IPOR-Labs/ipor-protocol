const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");

const {
    PERCENTAGE_2_18DEC,
    PERCENTAGE_2_5_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_8_18DEC,
    PERCENTAGE_50_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USD_500_18DEC,
    USD_10_400_18DEC,
    USD_14_000_18DEC,
    USD_14_000_6DEC,
    ZERO,

    PERIOD_25_DAYS_IN_SECONDS,
} = require("./Const.js");

const {
    assertError,
    getStandardDerivativeParamsDAI,
    getStandardDerivativeParamsUSDT,
    prepareApproveForUsers,
    prepareData,
    prepareTestData,
    prepareTestDataDaiCase000,
    prepareTestDataDaiCase001,
    setupIpTokenDaiInitialValues,
    setupIpTokenUsdtInitialValues,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdtInitialValuesForUsers,
} = require("./Utils");

describe("Joseph - redeem", () => {
    let data = null;
    let admin, userOne, userTwo, userThree, liquidityProvider;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await ethers.getSigners();
        data = await prepareData([admin, userOne, userTwo, userThree, liquidityProvider], 1);
    });

    it("should redeem ipToken - simple case 1 - DAI 18 decimals", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupIpTokenDaiInitialValues(testData, liquidityProvider, ZERO);
        const params = getStandardDerivativeParamsDAI(userTwo, testData);
        const liquidityAmount = USD_14_000_18DEC;
        const withdrawAmount = TC_TOTAL_AMOUNT_10_000_18DEC;

        const redeemFee18Dec = BigInt("50000000000000000000");
        const expectedIpTokenBalanceSender = BigInt("4000000000000000000000");
        const expectedStableBalanceMilton = BigInt("4000000000000000000000") + redeemFee18Dec;
        const expectedLiquidityProviderStableBalance =
            BigInt("9996000000000000000000000") - redeemFee18Dec;
        const expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(liquidityAmount, params.openTimestamp);

        //when
        await testData.josephDai
            .connect(liquidityProvider)
            .itfRedeem(withdrawAmount, params.openTimestamp);

        //then
        const actualIpTokenBalanceSender = BigInt(
            await testData.ipTokenDai.balanceOf(liquidityProvider.address)
        );

        const actualUnderlyingBalanceMilton = BigInt(
            await testData.tokenDai.balanceOf(testData.miltonDai.address)
        );
        const actualLiquidityPoolBalanceMilton = BigInt(
            await (
                await testData.miltonDai.getAccruedBalance()
            ).liquidityPool
        );
        const actualUnderlyingBalanceSender = BigInt(
            await testData.tokenDai.balanceOf(liquidityProvider.address)
        );

        expect(
            expectedIpTokenBalanceSender,
            `Incorrect ipToken balance on user for asset ${params.asset} actual: ${actualIpTokenBalanceSender}, expected: ${expectedIpTokenBalanceSender}`
        ).to.be.eql(actualIpTokenBalanceSender);

        expect(
            expectedStableBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${expectedStableBalanceMilton}`
        ).to.be.eql(actualUnderlyingBalanceMilton);

        expect(
            expectedLiquidityPoolBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
        ).to.be.eql(actualLiquidityPoolBalanceMilton);

        expect(
            expectedLiquidityProviderStableBalance,
            `Incorrect DAI balance on Liquidity Provider for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
        ).to.be.eql(actualUnderlyingBalanceSender);
    });

    it("should redeem ipToken - simple case 1 - USDT 6 decimals", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
            0,
            0,
            0
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            data,
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupIpTokenUsdtInitialValues(liquidityProvider, ZERO);
        const params = getStandardDerivativeParamsUSDT(userTwo, testData);
        const liquidityAmount = USD_14_000_6DEC;
        const withdrawIpTokenAmount = TC_TOTAL_AMOUNT_10_000_18DEC;
        const redeemFee18Dec = BigInt("50000000000000000000");
        const redeemFee6Dec = BigInt("50000000");
        const expectedIpTokenBalanceSender = BigInt("4000000000000000000000");
        const expectedStableBalanceMilton = BigInt("4000000000") + redeemFee6Dec;
        const expectedLiquidityProviderStableBalance = BigInt("9996000000000") - redeemFee6Dec;
        const expectedLiquidityPoolBalanceMilton =
            BigInt("4000000000000000000000") + redeemFee18Dec;

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(liquidityAmount, params.openTimestamp);

        //when
        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfRedeem(withdrawIpTokenAmount, params.openTimestamp);

        //then
        const actualIpTokenBalanceSender = BigInt(
            await testData.ipTokenUsdt.balanceOf(liquidityProvider.address)
        );

        const actualUnderlyingBalanceMilton = BigInt(
            await testData.tokenUsdt.balanceOf(testData.miltonUsdt.address)
        );
        const actualLiquidityPoolBalanceMilton = BigInt(
            await (
                await testData.miltonUsdt.getAccruedBalance()
            ).liquidityPool
        );
        const actualUnderlyingBalanceSender = BigInt(
            await testData.tokenUsdt.balanceOf(liquidityProvider.address)
        );

        expect(
            expectedIpTokenBalanceSender,
            `Incorrect ipToken balance on user for asset ${params.asset} actual: ${actualIpTokenBalanceSender}, expected: ${expectedIpTokenBalanceSender}`
        ).to.be.eql(actualIpTokenBalanceSender);

        expect(
            expectedStableBalanceMilton,
            `Incorrect USDT balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${expectedStableBalanceMilton}`
        ).to.be.eql(actualUnderlyingBalanceMilton);

        expect(
            expectedLiquidityPoolBalanceMilton,
            `Incorrect USDT Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
        ).to.be.eql(actualLiquidityPoolBalanceMilton);

        expect(
            expectedLiquidityProviderStableBalance,
            `Incorrect USDT balance on Liquidity Provider for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
        ).to.be.eql(actualUnderlyingBalanceSender);
    });

    it("should NOT redeem ipTokens because of empty Liquidity Pool", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupIpTokenDaiInitialValues(testData, liquidityProvider, ZERO);
        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(params.totalAmount, params.openTimestamp);

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        await testData.miltonStorageDai.setJoseph(userOne.address);
        await testData.miltonStorageDai.connect(userOne).subtractLiquidity(params.totalAmount);
        await testData.miltonStorageDai.setJoseph(testData.josephDai.address);

        //when
        await assertError(
            //when
            testData.josephDai
                .connect(liquidityProvider)
                .itfRedeem(BigInt("1000000000000000000000"), params.openTimestamp),
            //then
            "IPOR_300"
        );
    });

    it("should NOT redeem ipTokens because after redeem Liquidity Pool will be empty", async () => {
        //given
        const testData = await prepareTestDataDaiCase001(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupIpTokenDaiInitialValues(testData, liquidityProvider, ZERO);
        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(params.totalAmount, params.openTimestamp);

        //when
        await assertError(
            //when
            testData.josephDai
                .connect(liquidityProvider)
                .itfRedeem(params.totalAmount, params.openTimestamp),
            //then
            "IPOR_402"
        );
    });

    it("should redeem ipTokens because NO validation for cool off period", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupIpTokenDaiInitialValues(testData, liquidityProvider, ZERO);

        const liquidityAmount = USD_14_000_18DEC;
        const withdrawAmount = TC_TOTAL_AMOUNT_10_000_18DEC;

        const timestamp = Math.floor(Date.now() / 1000);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(liquidityAmount, timestamp);

        //when
        await testData.josephDai.connect(liquidityProvider).itfRedeem(withdrawAmount, timestamp);

        const redeemFee18Dec = BigInt("50000000000000000000");

        const expectedIpTokenBalanceSender = BigInt("4000000000000000000000");
        const expectedStableBalanceMilton = BigInt("4000000000000000000000") + redeemFee18Dec;
        const expectedLiquidityProviderStableBalance =
            BigInt("9996000000000000000000000") - redeemFee18Dec;
        const expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

        //then
        const actualIpTokenBalanceSender = BigInt(
            await testData.ipTokenDai.balanceOf(liquidityProvider.address)
        );

        const actualUnderlyingBalanceMilton = BigInt(
            await testData.tokenDai.balanceOf(testData.miltonDai.address)
        );
        const actualLiquidityPoolBalanceMilton = BigInt(
            await (
                await testData.miltonDai.getAccruedBalance()
            ).liquidityPool
        );
        const actualUnderlyingBalanceSender = BigInt(
            await testData.tokenDai.balanceOf(liquidityProvider.address)
        );

        expect(
            expectedIpTokenBalanceSender,
            `Incorrect ipToken balance on user for asset ${testData.tokenDai.address} actual: ${actualIpTokenBalanceSender}, expected: ${expectedIpTokenBalanceSender}`
        ).to.be.eql(actualIpTokenBalanceSender);

        expect(
            expectedStableBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${testData.tokenDai.address} actual: ${actualUnderlyingBalanceMilton}, expected: ${expectedStableBalanceMilton}`
        ).to.be.eql(actualUnderlyingBalanceMilton);

        expect(
            expectedLiquidityPoolBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${testData.tokenDai.address} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
        ).to.be.eql(actualLiquidityPoolBalanceMilton);

        expect(
            expectedLiquidityProviderStableBalance,
            `Incorrect DAI balance on Liquidity Provider for asset ${testData.tokenDai.address} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
        ).to.be.eql(actualUnderlyingBalanceSender);
    });

    it("should redeem ipTokens, two times provided liquidity", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupIpTokenDaiInitialValues(testData, liquidityProvider, ZERO);
        const timestamp = Math.floor(Date.now() / 1000);
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(TC_TOTAL_AMOUNT_10_000_18DEC, timestamp);
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(TC_TOTAL_AMOUNT_10_000_18DEC, timestamp);

        //when
        await testData.josephDai.connect(liquidityProvider).itfRedeem(USD_14_000_18DEC, timestamp);

        //then
        const redeemFee18Dec = BigInt("70000000000000000000");
        const redeemFee6Dec = BigInt("70000000");

        const expectedIpTokenBalanceSender = BigInt("6000000000000000000000");
        const expectedStableBalanceMilton = BigInt("6000000000000000000000") + redeemFee18Dec;
        const expectedLiquidityProviderStableBalance =
            BigInt("9994000000000000000000000") - redeemFee18Dec;
        const expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

        const actualIpTokenBalanceSender = BigInt(
            await testData.ipTokenDai.balanceOf(liquidityProvider.address)
        );

        const actualUnderlyingBalanceMilton = BigInt(
            await testData.tokenDai.balanceOf(testData.miltonDai.address)
        );
        const actualLiquidityPoolBalanceMilton = BigInt(
            await (
                await testData.miltonDai.getAccruedBalance()
            ).liquidityPool
        );
        const actualUnderlyingBalanceSender = BigInt(
            await testData.tokenDai.balanceOf(liquidityProvider.address)
        );

        expect(
            expectedIpTokenBalanceSender,
            `Incorrect ipToken balance on user for asset ${testData.tokenDai.address} actual: ${actualIpTokenBalanceSender}, expected: ${expectedIpTokenBalanceSender}`
        ).to.be.eql(actualIpTokenBalanceSender);

        expect(
            expectedStableBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${testData.tokenDai.address} actual: ${actualUnderlyingBalanceMilton}, expected: ${expectedStableBalanceMilton}`
        ).to.be.eql(actualUnderlyingBalanceMilton);

        expect(
            expectedLiquidityPoolBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${testData.tokenDai.address} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
        ).to.be.eql(actualLiquidityPoolBalanceMilton);

        expect(
            expectedLiquidityProviderStableBalance,
            `Incorrect DAI balance on Liquidity Provider for asset ${testData.tokenDai.address} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
        ).to.be.eql(actualUnderlyingBalanceSender);
    });

    it("should redeem ipDAI, should redeem ipUSDT - simple case 1", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI", "USDT"],
            data,
            0,
            0,
            0
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupIpTokenDaiInitialValues(testData, liquidityProvider, ZERO);
        await setupIpTokenUsdtInitialValues(testData, liquidityProvider, ZERO);

        const liquidityAmountDAI = USD_14_000_18DEC;
        const withdrawIpTokenAmountDAI = TC_TOTAL_AMOUNT_10_000_18DEC;

        const liquidityAmountUSDT = USD_14_000_6DEC;
        const withdrawIpTokenAmountUSDT = TC_TOTAL_AMOUNT_10_000_18DEC;

        const redeemFee18Dec = BigInt("50000000000000000000");
        const redeemFee6Dec = BigInt("50000000");

        const expectedIpDAIBalanceSender = BigInt("4000000000000000000000");
        const expectedDAIBalanceMilton = BigInt("4000000000000000000000") + redeemFee18Dec;
        const expectedLiquidityProviderDAIBalance =
            BigInt("9996000000000000000000000") - redeemFee18Dec;
        const expectedLiquidityPoolDAIBalanceMilton = expectedDAIBalanceMilton;

        const expectedIpUSDTBalanceSender = BigInt("4000000000000000000000");
        const expectedUSDTBalanceMilton = BigInt("4000000000") + redeemFee6Dec;
        const expectedLiquidityProviderUSDTBalance = BigInt("9996000000000") - redeemFee6Dec;
        const expectedLiquidityPoolUSDTBalanceMilton =
            BigInt("4000000000000000000000") + redeemFee18Dec;

        const timestamp = Math.floor(Date.now() / 1000);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(liquidityAmountDAI, timestamp);
        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(liquidityAmountUSDT, timestamp);

        //when
        await testData.josephDai
            .connect(liquidityProvider)
            .itfRedeem(withdrawIpTokenAmountDAI, timestamp);
        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfRedeem(withdrawIpTokenAmountUSDT, timestamp);

        //then
        const actualIpDAIBalanceSender = BigInt(
            await testData.ipTokenDai.balanceOf(liquidityProvider.address)
        );
        const actualDAIBalanceMilton = BigInt(
            await testData.tokenDai.balanceOf(testData.miltonDai.address)
        );
        const actualLiquidityPoolDAIBalanceMilton = BigInt(
            await (
                await testData.miltonDai.getAccruedBalance()
            ).liquidityPool
        );
        const actualDAIBalanceSender = BigInt(
            await testData.tokenDai.balanceOf(liquidityProvider.address)
        );

        expect(
            expectedIpDAIBalanceSender,
            `Incorrect ipToken DAI balance on user for asset ${testData.tokenDai.address} actual: ${actualIpDAIBalanceSender}, expected: ${expectedIpDAIBalanceSender}`
        ).to.be.eql(actualIpDAIBalanceSender);

        expect(
            expectedDAIBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceMilton}, expected: ${expectedDAIBalanceMilton}`
        ).to.be.eql(actualDAIBalanceMilton);

        expect(
            expectedLiquidityPoolDAIBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${testData.tokenDai.address} actual: ${actualLiquidityPoolDAIBalanceMilton}, expected: ${expectedLiquidityPoolDAIBalanceMilton}`
        ).to.be.eql(actualLiquidityPoolDAIBalanceMilton);

        expect(
            expectedLiquidityProviderDAIBalance,
            `Incorrect DAI balance on Liquidity Provider for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceSender}, expected: ${expectedLiquidityProviderDAIBalance}`
        ).to.be.eql(actualDAIBalanceSender);

        const actualIpUSDTBalanceSender = BigInt(
            await testData.ipTokenUsdt.balanceOf(liquidityProvider.address)
        );
        const actualUSDTBalanceMilton = BigInt(
            await testData.tokenUsdt.balanceOf(testData.miltonUsdt.address)
        );

        const actualLiquidityPoolUSDTBalanceMilton = BigInt(
            await (
                await testData.miltonUsdt.getAccruedBalance()
            ).liquidityPool
        );
        const actualUSDTBalanceSender = BigInt(
            await testData.tokenUsdt.balanceOf(liquidityProvider.address)
        );

        expect(
            expectedIpUSDTBalanceSender,
            `Incorrect ipToken USDT balance on user for asset ${testData.tokenUsdt.address} actual: ${actualIpUSDTBalanceSender}, expected: ${expectedIpUSDTBalanceSender}`
        ).to.be.eql(actualIpUSDTBalanceSender);

        expect(
            expectedUSDTBalanceMilton,
            `Incorrect USDT balance on Milton for asset ${testData.tokenUsdt.address} actual: ${actualUSDTBalanceMilton}, expected: ${expectedUSDTBalanceMilton}`
        ).to.be.eql(actualUSDTBalanceMilton);

        expect(
            expectedLiquidityPoolUSDTBalanceMilton,
            `Incorrect USDT Liquidity Pool Balance on Milton for asset ${testData.tokenUsdt.address} actual: ${actualLiquidityPoolUSDTBalanceMilton}, expected: ${expectedLiquidityPoolUSDTBalanceMilton}`
        ).to.be.eql(actualLiquidityPoolUSDTBalanceMilton);

        expect(
            expectedLiquidityProviderUSDTBalance,
            `Incorrect USDT balance on Liquidity Provider for asset ${testData.tokenUsdt.address} actual: ${actualUSDTBalanceSender}, expected: ${expectedLiquidityProviderUSDTBalance}`
        ).to.be.eql(actualUSDTBalanceSender);
    });

    it("should redeem ipDAI, should redeem ipUSDT, two users - simple case 1", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI", "USDT"],
            data,
            0,
            0,
            0
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupIpTokenDaiInitialValues(testData, liquidityProvider, ZERO);
        await setupIpTokenUsdtInitialValues(testData, liquidityProvider, ZERO);

        const liquidityAmountDAI = USD_14_000_18DEC;
        const withdrawIpTokenAmountDAI = TC_TOTAL_AMOUNT_10_000_18DEC;
        const liquidityAmountUSDT = USD_14_000_6DEC;
        const withdrawIpTokenAmountUSDT = TC_TOTAL_AMOUNT_10_000_18DEC;

        const redeemFee18Dec = BigInt("50000000000000000000");
        const redeemFee6Dec = BigInt("50000000");
        const expectedIpDAIBalanceSender = BigInt("4000000000000000000000");
        const expectedDAIBalanceMilton = BigInt("4000000000000000000000") + redeemFee18Dec;
        const expectedLiquidityProviderDAIBalance =
            BigInt("9996000000000000000000000") - redeemFee18Dec;
        const expectedLiquidityPoolDAIBalanceMilton = expectedDAIBalanceMilton;

        const expectedIpUSDTBalanceSender = BigInt("4000000000000000000000");
        const expectedUSDTBalanceMilton = BigInt("4000000000") + redeemFee6Dec;
        const expectedLiquidityProviderUSDTBalance = BigInt("9996000000000") - redeemFee6Dec;
        const expectedLiquidityPoolUSDTBalanceMilton =
            BigInt("4000000000000000000000") + redeemFee18Dec;

        const daiUser = userOne;
        const usdtUser = userTwo;

        const timestamp = Math.floor(Date.now() / 1000);

        await testData.josephDai
            .connect(daiUser)
            .itfProvideLiquidity(liquidityAmountDAI, timestamp);

        await testData.josephUsdt
            .connect(usdtUser)
            .itfProvideLiquidity(liquidityAmountUSDT, timestamp);

        //when
        await testData.josephDai.connect(daiUser).itfRedeem(withdrawIpTokenAmountDAI, timestamp);
        await testData.josephUsdt.connect(usdtUser).itfRedeem(withdrawIpTokenAmountUSDT, timestamp);

        //then
        const actualIpDAIBalanceSender = BigInt(
            await testData.ipTokenDai.balanceOf(daiUser.address)
        );
        const actualDAIBalanceMilton = BigInt(
            await testData.tokenDai.balanceOf(testData.miltonDai.address)
        );
        const actualLiquidityPoolDAIBalanceMilton = BigInt(
            await (
                await testData.miltonDai.getAccruedBalance()
            ).liquidityPool
        );
        const actualDAIBalanceSender = BigInt(await testData.tokenDai.balanceOf(daiUser.address));

        expect(
            expectedIpDAIBalanceSender,
            `Incorrect ipToken DAI balance on user for asset ${testData.tokenDai.address} actual: ${actualIpDAIBalanceSender}, expected: ${expectedIpDAIBalanceSender}`
        ).to.be.eql(actualIpDAIBalanceSender);

        expect(
            expectedDAIBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceMilton}, expected: ${expectedDAIBalanceMilton}`
        ).to.be.eql(actualDAIBalanceMilton);

        expect(
            expectedLiquidityPoolDAIBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${testData.tokenDai.address} actual: ${actualLiquidityPoolDAIBalanceMilton}, expected: ${expectedLiquidityPoolDAIBalanceMilton}`
        ).to.be.eql(actualLiquidityPoolDAIBalanceMilton);

        expect(
            expectedLiquidityProviderDAIBalance,
            `Incorrect DAI balance on Liquidity Provider for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceSender}, expected: ${expectedLiquidityProviderDAIBalance}`
        ).to.be.eql(actualDAIBalanceSender);

        const actualIpUSDTBalanceSender = BigInt(
            await testData.ipTokenUsdt.balanceOf(usdtUser.address)
        );
        const actualUSDTBalanceMilton = BigInt(
            await testData.tokenUsdt.balanceOf(testData.miltonUsdt.address)
        );

        const actualLiquidityPoolUSDTBalanceMilton = BigInt(
            await (
                await testData.miltonUsdt.getAccruedBalance()
            ).liquidityPool
        );
        const actualUSDTBalanceSender = BigInt(
            await testData.tokenUsdt.balanceOf(usdtUser.address)
        );

        expect(
            expectedIpUSDTBalanceSender,
            `Incorrect ipToken USDT balance on user for asset ${testData.tokenUsdt.address} actual: ${actualIpUSDTBalanceSender}, expected: ${expectedIpUSDTBalanceSender}`
        ).to.be.eql(actualIpUSDTBalanceSender);

        expect(
            expectedUSDTBalanceMilton,
            `Incorrect USDT balance on Milton for asset ${testData.tokenUsdt.address} actual: ${actualUSDTBalanceMilton}, expected: ${expectedUSDTBalanceMilton}`
        ).to.be.eql(actualUSDTBalanceMilton);

        expect(
            expectedLiquidityPoolUSDTBalanceMilton,
            `Incorrect USDT Liquidity Pool Balance on Milton for asset ${testData.tokenUsdt.address} actual: ${actualLiquidityPoolUSDTBalanceMilton}, expected: ${expectedLiquidityPoolUSDTBalanceMilton}`
        ).to.be.eql(actualLiquidityPoolUSDTBalanceMilton);

        expect(
            expectedLiquidityProviderUSDTBalance,
            `Incorrect USDT balance on Liquidity Provider for asset ${testData.tokenUsdt.address} actual: ${actualUSDTBalanceSender}, expected: ${expectedLiquidityProviderUSDTBalance}`
        ).to.be.eql(actualUSDTBalanceSender);
    });

    it("should redeem - Liquidity Provider can transfer tokens to other user, user can redeem tokens", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupIpTokenDaiInitialValues(testData, liquidityProvider, ZERO);
        const timestamp = Math.floor(Date.now() / 1000);
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_10_400_18DEC, timestamp);

        await testData.ipTokenDai
            .connect(liquidityProvider)
            .transfer(userThree.address, TC_TOTAL_AMOUNT_10_000_18DEC);

        await testData.josephDai
            .connect(userThree)
            .itfRedeem(TC_TOTAL_AMOUNT_10_000_18DEC, timestamp);
        const redeemFee = BigInt("50000000000000000000");
        const expectedDAIBalanceMilton = BigInt("400000000000000000000") + redeemFee;
        const expectedDAIBalanceMiltonLiquidityPool = expectedDAIBalanceMilton;

        const expectedIpDAIBalanceLiquidityProvider = BigInt("400000000000000000000");
        const expectedDAIBalanceLiquidityProvider = BigInt("9989600000000000000000000");

        const expectedIpDAIBalanceUserThree = BigInt("0");
        const expectedDAIBalanceUserThree = BigInt("10010000000000000000000000") - redeemFee;

        const actualDAIBalanceMilton = BigInt(
            await testData.tokenDai.balanceOf(testData.miltonDai.address)
        );
        const actualDAIBalanceMiltonLiquidityPool = BigInt(
            await (
                await testData.miltonDai.getAccruedBalance()
            ).liquidityPool
        );

        const actualIpDAIBalanceLiquidityProvider = BigInt(
            await testData.ipTokenDai.balanceOf(liquidityProvider.address)
        );
        const actualDAIBalanceLiquidityProvider = BigInt(
            await testData.tokenDai.balanceOf(liquidityProvider.address)
        );

        const actualIpDAIBalanceUserThree = BigInt(
            await testData.ipTokenDai.balanceOf(userThree.address)
        );
        const actualDAIBalanceUserThree = BigInt(
            await testData.tokenDai.balanceOf(userThree.address)
        );

        expect(
            expectedDAIBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceMilton}, expected: ${expectedDAIBalanceMilton}`
        ).to.be.eql(actualDAIBalanceMilton);
        expect(
            expectedDAIBalanceMiltonLiquidityPool,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceMiltonLiquidityPool}, expected: ${expectedDAIBalanceMiltonLiquidityPool}`
        ).to.be.eql(actualDAIBalanceMiltonLiquidityPool);

        expect(
            expectedIpDAIBalanceLiquidityProvider,
            `Incorrect ipToken DAI balance on Liquidity Provider for asset ${testData.tokenDai.address} actual: ${actualIpDAIBalanceLiquidityProvider}, expected: ${expectedIpDAIBalanceLiquidityProvider}`
        ).to.be.eql(actualIpDAIBalanceLiquidityProvider);
        expect(
            expectedDAIBalanceLiquidityProvider,
            `Incorrect DAI balance on Liquidity Provider for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceLiquidityProvider}, expected: ${expectedDAIBalanceLiquidityProvider}`
        ).to.be.eql(actualDAIBalanceLiquidityProvider);

        expect(
            expectedIpDAIBalanceUserThree,
            `Incorrect ipToken DAI balance on user for asset ${testData.tokenDai.address} actual: ${actualIpDAIBalanceUserThree}, expected: ${expectedIpDAIBalanceUserThree}`
        ).to.be.eql(actualIpDAIBalanceUserThree);
        expect(
            expectedDAIBalanceUserThree,
            `Incorrect DAI balance on user for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceUserThree}, expected: ${expectedDAIBalanceUserThree}`
        ).to.be.eql(actualDAIBalanceUserThree);
    });

    it("should NOT redeem - Redeem Liquidity Pool Utilization already exceeded, Pay Fixed", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupIpTokenDaiInitialValues(testData, liquidityProvider, ZERO);

        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        const ipTokenAmount = BigInt("60000000000000000000000");
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(ipTokenAmount, params.openTimestamp);

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigInt("27000000000000000000000"),
                params.toleratedQuoteValue,
                params.collateralizationFactor
            );

        //BEGIN HACK - substract liquidity without  burn ipToken
        await testData.miltonStorageDai.setJoseph(admin.address);
        await testData.miltonStorageDai.subtractLiquidity(BigInt("45000000000000000000000"));
        await testData.miltonStorageDai.setJoseph(testData.josephDai.address);
        //END HACK - substract liquidity without  burn ipToken

        const balance = await testData.miltonDai.getAccruedBalance();
        const actualCollateral = BigInt(balance.payFixedSwaps) + BigInt(balance.receiveFixedSwaps);
        const actualLiquidityPoolBalance = BigInt(balance.liquidityPool);

        await assertError(
            //when
            testData.josephDai
                .connect(liquidityProvider)
                .itfRedeem(ipTokenAmount, params.openTimestamp),
            //then
            "IPOR_402"
        );

        //then
        assert(
            actualCollateral > actualLiquidityPoolBalance,
            "Actual collateral cannot be lower than actual Liquidity Pool Balance"
        );
    });

    it("should NOT redeem - Redeem Liquidity Pool Utilization already exceeded, Receive Fixed", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupIpTokenDaiInitialValues(testData, liquidityProvider, ZERO);

        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        const ipTokenAmount = BigInt("60000000000000000000000");
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(ipTokenAmount, params.openTimestamp);

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                BigInt("27000000000000000000000"),
                params.toleratedQuoteValue,
                params.collateralizationFactor
            );

        //BEGIN HACK - substract liquidity without  burn ipToken
        await testData.miltonStorageDai.setJoseph(admin.address);

        await testData.miltonStorageDai.subtractLiquidity(BigInt("45000000000000000000000"));
        await testData.miltonStorageDai.setJoseph(testData.josephDai.address);
        //END HACK - substract liquidity without  burn ipToken

        const balance = await testData.miltonDai.getAccruedBalance();
        const actualCollateral = BigInt(balance.payFixedSwaps) + BigInt(balance.receiveFixedSwaps);
        const actualLiquidityPoolBalance = BigInt(balance.liquidityPool);

        await assertError(
            //when
            testData.josephDai
                .connect(liquidityProvider)
                .itfRedeem(ipTokenAmount, params.openTimestamp),
            //then
            "IPOR_402"
        );

        //then
        assert(
            actualCollateral > actualLiquidityPoolBalance,
            "Actual collateral cannot be lower than actual Liquidity Pool Balance"
        );
    });

    it("should NOT redeem - Redeem Liquidity Pool Utilization exceeded, Pay Fixed", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupIpTokenDaiInitialValues(testData, liquidityProvider, ZERO);

        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        const ipTokenAmount = BigInt("41000000000000000000000");

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt("60000000000000000000000"), params.openTimestamp);

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigInt("27000000000000000000000"),
                params.toleratedQuoteValue,
                params.collateralizationFactor
            );

        const balance = await testData.miltonDai.getAccruedBalance();

        const actualCollateral = BigInt(balance.payFixedSwaps) + BigInt(balance.receiveFixedSwaps);
        const actualLiquidityPoolBalance = BigInt(balance.liquidityPool);

        await assertError(
            //when
            testData.josephDai
                .connect(liquidityProvider)
                .itfRedeem(ipTokenAmount, params.openTimestamp),
            //then
            "IPOR_402"
        );
        assert(
            actualCollateral < actualLiquidityPoolBalance,
            "Actual collateral cannot be higher than actual Liquidity Pool Balance"
        );
    });

    it("should NOT redeem - Redeem Liquidity Pool Utilization exceeded, Receive Fixed", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupIpTokenDaiInitialValues(testData, liquidityProvider, ZERO);

        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        const ipTokenAmount = BigInt("41000000000000000000000");

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt("60000000000000000000000"), params.openTimestamp);

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                BigInt("27000000000000000000000"),
                params.toleratedQuoteValue,
                params.collateralizationFactor
            );

        const balance = await testData.miltonDai.getAccruedBalance();

        const actualCollateral = BigInt(balance.payFixedSwaps) + BigInt(balance.receiveFixedSwaps);
        const actualLiquidityPoolBalance = BigInt(balance.liquidityPool);

        await assertError(
            //when
            testData.josephDai
                .connect(liquidityProvider)
                .itfRedeem(ipTokenAmount, params.openTimestamp),
            //then
            "IPOR_402"
        );
        assert(
            actualCollateral < actualLiquidityPoolBalance,
            "Actual collateral cannot be higher than actual Liquidity Pool Balance"
        );
    });

    it("should redeem - Liquidity Pool Utilization not exceedeed, Redeem Liquidity Pool Utilization not exceeded, Pay Fixed", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupIpTokenDaiInitialValues(testData, liquidityProvider, ZERO);

        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt("100000000000000000000000"), params.openTimestamp);

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigInt("27000000000000000000000"),
                params.toleratedQuoteValue,
                params.collateralizationFactor
            );

        const balance = await testData.miltonDai.getAccruedBalance();
        const actualCollateral = BigInt(balance.payFixedSwaps) + BigInt(balance.receiveFixedSwaps);
        const actualLiquidityPoolBalance = BigInt(balance.liquidityPool);

        //when
        await testData.josephDai
            .connect(liquidityProvider)
            .itfRedeem(BigInt("51000000000000000000000"), params.openTimestamp);

        //then
        //this line is not achieved if redeem failed
        const actualIpTokenBalanceSender = BigInt(
            await testData.ipTokenDai.balanceOf(liquidityProvider.address)
        );
        assert(
            actualCollateral < actualLiquidityPoolBalance,
            "Actual collateral cannot be higher than actual Liquidity Pool Balance"
        );

        expect(actualIpTokenBalanceSender).to.be.eq(BigInt("49000000000000000000000"));
    });

    it("should redeem - Liquidity Pool Utilization not exceedeed, Redeem Liquidity Pool Utilization not exceeded, Receive Fixed", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupIpTokenDaiInitialValues(testData, liquidityProvider, ZERO);

        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt("100000000000000000000000"), params.openTimestamp);

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                BigInt("40000000000000000000000"),
                params.toleratedQuoteValue,
                params.collateralizationFactor
            );

        const balance = await testData.miltonDai.getAccruedBalance();
        const actualCollateral = BigInt(balance.payFixedSwaps) + BigInt(balance.receiveFixedSwaps);
        const actualLiquidityPoolBalance = BigInt(balance.liquidityPool);

        //when
        await testData.josephDai
            .connect(liquidityProvider)
            .itfRedeem(BigInt("51000000000000000000000"), params.openTimestamp);

        //then
        //this line is not achieved if redeem failed
        const actualIpTokenBalanceSender = BigInt(
            await testData.ipTokenDai.balanceOf(liquidityProvider.address)
        );
        assert(
            actualCollateral < actualLiquidityPoolBalance,
            "Actual collateral cannot be higher than actual Liquidity Pool Balance"
        );

        expect(actualIpTokenBalanceSender).to.be.eq(BigInt("49000000000000000000000"));
    });

    it("should redeem - Liquidity Pool Utilization exceeded, Redeem Liquidity Pool Utilization not exceeded, Pay Fixed", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupIpTokenDaiInitialValues(testData, liquidityProvider, ZERO);

        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt("100000000000000000000000"), params.openTimestamp);

        //position which utilizates 48% per leg
        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigInt("48000000000000000000000"),
                params.toleratedQuoteValue,
                params.collateralizationFactor
            );

        //first small redeem
        await testData.josephDai
            .connect(liquidityProvider)
            .itfRedeem(BigInt("10000000000000000000000"), params.openTimestamp);

        //presentation that currently liquidity pool utilization for opening position is achieved
        await assertError(
            testData.miltonDai
                .connect(userTwo)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    BigInt("50000000000000000000"),
                    params.toleratedQuoteValue,
                    params.collateralizationFactor
                ),
            "IPOR_302"
        );

        //when
        await testData.josephDai
            .connect(liquidityProvider)
            .itfRedeem(BigInt("10300000000000000000000"), params.openTimestamp);

        //then
        //this line is not achieved if redeem failed
        const actualIpTokenBalanceSender = BigInt(
            await testData.ipTokenDai.balanceOf(liquidityProvider.address)
        );
        expect(actualIpTokenBalanceSender).to.be.eq(BigInt("79700000000000000000000"));
    });
    it("should redeem - Liquidity Pool Utilization exceeded, Redeem Liquidity Pool Utilization not exceeded, Receive Fixed", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await setupIpTokenDaiInitialValues(testData, liquidityProvider, ZERO);

        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt("100000000000000000000000"), params.openTimestamp);

        //position which utilizates 48% per leg
        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                BigInt("48000000000000000000000"),
                params.toleratedQuoteValue,
                params.collateralizationFactor
            );

        //first small redeem
        await testData.josephDai
            .connect(liquidityProvider)
            .itfRedeem(BigInt("10000000000000000000000"), params.openTimestamp);

        //presentation that currently liquidity pool utilization for opening position is achieved
        await assertError(
            testData.miltonDai
                .connect(userTwo)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    BigInt("50000000000000000000"),
                    params.toleratedQuoteValue,
                    params.collateralizationFactor
                ),
            "IPOR_302"
        );

        //when
        await testData.josephDai
            .connect(liquidityProvider)
            .itfRedeem(BigInt("10300000000000000000000"), params.openTimestamp);

        //then
        //this line is not achieved if redeem failed
        const actualIpTokenBalanceSender = BigInt(
            await testData.ipTokenDai.balanceOf(liquidityProvider.address)
        );
        expect(actualIpTokenBalanceSender).to.be.eq(BigInt("79700000000000000000000"));
    });
});
