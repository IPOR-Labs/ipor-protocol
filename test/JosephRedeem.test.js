const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");

const {
    PERCENTAGE_2_18DEC,
    PERCENTAGE_2_5_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_8_18DEC,
    PERCENTAGE_50_18DEC,
    USD_10_000_18DEC,
    USD_10_18DEC,
    USD_10_400_18DEC,
    USD_14_000_18DEC,
    USD_14_000_6DEC,
    ZERO,

    PERIOD_25_DAYS_IN_SECONDS,
} = require("./Const.js");

const {
    assertError,
    getLibraries,
    getStandardDerivativeParamsDAI,
    getStandardDerivativeParamsUSDT,
    prepareApproveForUsers,
    prepareData,
    prepareTestData,
    setupIpTokenDaiInitialValues,
    setupIpTokenUsdtInitialValues,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdtInitialValuesForUsers,
    grantAllSpreadRoles,
    setupDefaultSpreadConstants,
} = require("./Utils");

describe("Joseph - redeem", () => {
    let data = null;
    let admin, userOne, userTwo, userThree, liquidityProvider;
    let libraries;

    before(async () => {
        libraries = await getLibraries();
        [admin, userOne, userTwo, userThree, liquidityProvider] =
            await ethers.getSigners();
        data = await prepareData(libraries, [
            admin,
            userOne,
            userTwo,
            userThree,
            liquidityProvider,
        ]);
        await grantAllSpreadRoles(data, admin, userOne);
        await setupDefaultSpreadConstants(data, userOne);
    });

    it("should redeem ipToken - simple case 1 - DAI 18 decimals", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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
        const withdrawAmount = USD_10_000_18DEC;
        const expectedIpTokenBalanceSender = BigInt("4000000000000000000000");
        const expectedStableBalanceMilton = BigInt("4000000000000000000000");
        const expectedLiquidityProviderStableBalance = BigInt(
            "9996000000000000000000000"
        );
        const expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(liquidityAmount, params.openTimestamp);

        //when
        await testData.josephDai
            .connect(liquidityProvider)
            .itfRedeem(withdrawAmount, params.openTimestamp);

        // //then
        const actualIpTokenBalanceSender = BigInt(
            await testData.ipTokenDai.balanceOf(liquidityProvider.address)
        );

        const actualUnderlyingBalanceMilton = BigInt(
            await testData.tokenDai.balanceOf(testData.miltonDai.address)
        );
        const actualLiquidityPoolBalanceMilton = BigInt(
            await (
                await testData.miltonStorageDai.getBalance()
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
            libraries
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
        const withdrawIpTokenAmount = USD_10_000_18DEC;
        const expectedIpTokenBalanceSender = BigInt("4000000000000000000000");
        const expectedStableBalanceMilton = BigInt("4000000000");
        const expectedLiquidityProviderStableBalance = BigInt("9996000000000");
        const expectedLiquidityPoolBalanceMilton = BigInt(
            "4000000000000000000000"
        );

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
                await testData.miltonStorageUsdt.getBalance()
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
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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
        await testData.iporAssetConfigurationDai.setJoseph(userOne.address);
        await testData.miltonStorageDai
            .connect(userOne)
            .subtractLiquidity(params.totalAmount);
        await testData.iporAssetConfigurationDai.setJoseph(
            testData.josephDai.address
        );

        //when
        await assertError(
            //when
            testData.josephDai
                .connect(liquidityProvider)
                .itfRedeem(
                    BigInt("1000000000000000000000"),
                    params.openTimestamp
                ),
            //then
            "IPOR_45"
        );
    });

    it("should NOT redeem ipTokens because redeem value higher than Liquidity Pool Balance", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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
        await testData.iporAssetConfigurationDai.setJoseph(userOne.address);
        await testData.miltonStorageDai
            .connect(userOne)
            .subtractLiquidity(USD_10_18DEC);
        await testData.iporAssetConfigurationDai.setJoseph(
            testData.josephDai.address
        );

        //when
        await assertError(
            //when
            testData.josephDai
                .connect(liquidityProvider)
                .itfRedeem(params.totalAmount, params.openTimestamp),
            //then
            "IPOR_43"
        );
    });

    it("should NOT redeem ipTokens because after redeem Liquidity Pool will be empty", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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
            "IPOR_43"
        );
    });

    it("should redeem ipTokens because NO validation for cool off period", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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
        const withdrawAmount = USD_10_000_18DEC;

        const timestamp = Math.floor(Date.now() / 1000);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(liquidityAmount, timestamp);

        //when
        await testData.josephDai
            .connect(liquidityProvider)
            .itfRedeem(withdrawAmount, timestamp);

        const expectedIpTokenBalanceSender = BigInt("4000000000000000000000");
        const expectedStableBalanceMilton = BigInt("4000000000000000000000");
        const expectedLiquidityProviderStableBalance = BigInt(
            "9996000000000000000000000"
        );
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
                await testData.miltonStorageDai.getBalance()
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
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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
            .itfProvideLiquidity(USD_10_000_18DEC, timestamp);
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_10_000_18DEC, timestamp);

        //when
        await testData.josephDai
            .connect(liquidityProvider)
            .itfRedeem(USD_14_000_18DEC, timestamp);

        //then
        const expectedIpTokenBalanceSender = BigInt("6000000000000000000000");
        const expectedStableBalanceMilton = BigInt("6000000000000000000000");
        const expectedLiquidityProviderStableBalance = BigInt(
            "9994000000000000000000000"
        );
        const expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

        const actualIpTokenBalanceSender = BigInt(
            await testData.ipTokenDai.balanceOf(liquidityProvider.address)
        );

        const actualUnderlyingBalanceMilton = BigInt(
            await testData.tokenDai.balanceOf(testData.miltonDai.address)
        );
        const actualLiquidityPoolBalanceMilton = BigInt(
            await (
                await testData.miltonStorageDai.getBalance()
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
            libraries
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
        const withdrawAmountDAI = USD_10_000_18DEC;

        const liquidityAmountUSDT = USD_14_000_6DEC;
        const withdrawIpTokenAmountUSDT = USD_10_000_18DEC;

        const expectedipDAIBalanceSender = BigInt("4000000000000000000000");
        const expectedDAIBalanceMilton = BigInt("4000000000000000000000");
        const expectedLiquidityProviderDAIBalance = BigInt(
            "9996000000000000000000000"
        );
        const expectedLiquidityPoolDAIBalanceMilton = expectedDAIBalanceMilton;

        const expectedipUSDTBalanceSender = BigInt("4000000000000000000000");
        const expectedUSDTBalanceMilton = BigInt("4000000000");
        const expectedLiquidityProviderUSDTBalance = BigInt("9996000000000");
        const expectedLiquidityPoolUSDTBalanceMilton = BigInt(
            "4000000000000000000000"
        );

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
            .itfRedeem(withdrawAmountDAI, timestamp);
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
                await testData.miltonStorageDai.getBalance()
            ).liquidityPool
        );
        const actualDAIBalanceSender = BigInt(
            await testData.tokenDai.balanceOf(liquidityProvider.address)
        );

        expect(
            expectedipDAIBalanceSender,
            `Incorrect ipToken DAI balance on user for asset ${testData.tokenDai.address} actual: ${actualIpDAIBalanceSender}, expected: ${expectedipDAIBalanceSender}`
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
                await testData.miltonStorageUsdt.getBalance()
            ).liquidityPool
        );
        const actualUSDTBalanceSender = BigInt(
            await testData.tokenUsdt.balanceOf(liquidityProvider.address)
        );

        expect(
            expectedipUSDTBalanceSender,
            `Incorrect ipToken USDT balance on user for asset ${testData.tokenUsdt.address} actual: ${actualIpUSDTBalanceSender}, expected: ${expectedipUSDTBalanceSender}`
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
            libraries
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
        const withdrawAmountDAI = USD_10_000_18DEC;
        const liquidityAmountUSDT = USD_14_000_6DEC;
        const withdrawIpTokenAmountUSDT = USD_10_000_18DEC;

        const expectedipDAIBalanceSender = BigInt("4000000000000000000000");
        const expectedDAIBalanceMilton = BigInt("4000000000000000000000");
        const expectedLiquidityProviderDAIBalance = BigInt(
            "9996000000000000000000000"
        );
        const expectedLiquidityPoolDAIBalanceMilton = expectedDAIBalanceMilton;

        const expectedipUSDTBalanceSender = BigInt("4000000000000000000000");
        const expectedUSDTBalanceMilton = BigInt("4000000000");
        const expectedLiquidityProviderUSDTBalance = BigInt("9996000000000");
        const expectedLiquidityPoolUSDTBalanceMilton = BigInt(
            "4000000000000000000000"
        );

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
        await testData.josephDai
            .connect(daiUser)
            .itfRedeem(withdrawAmountDAI, timestamp);
        await testData.josephUsdt
            .connect(usdtUser)
            .itfRedeem(withdrawIpTokenAmountUSDT, timestamp);

        //then
        const actualIpDAIBalanceSender = BigInt(
            await testData.ipTokenDai.balanceOf(daiUser.address)
        );
        const actualDAIBalanceMilton = BigInt(
            await testData.tokenDai.balanceOf(testData.miltonDai.address)
        );
        const actualLiquidityPoolDAIBalanceMilton = BigInt(
            await (
                await testData.miltonStorageDai.getBalance()
            ).liquidityPool
        );
        const actualDAIBalanceSender = BigInt(
            await testData.tokenDai.balanceOf(daiUser.address)
        );

        expect(
            expectedipDAIBalanceSender,
            `Incorrect ipToken DAI balance on user for asset ${testData.tokenDai.address} actual: ${actualIpDAIBalanceSender}, expected: ${expectedipDAIBalanceSender}`
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
                await testData.miltonStorageUsdt.getBalance()
            ).liquidityPool
        );
        const actualUSDTBalanceSender = BigInt(
            await testData.tokenUsdt.balanceOf(usdtUser.address)
        );

        expect(
            expectedipUSDTBalanceSender,
            `Incorrect ipToken USDT balance on user for asset ${testData.tokenUsdt.address} actual: ${actualIpUSDTBalanceSender}, expected: ${expectedipUSDTBalanceSender}`
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
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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
            .transfer(userThree.address, USD_10_000_18DEC);

        await testData.josephDai
            .connect(userThree)
            .itfRedeem(USD_10_000_18DEC, timestamp);

        const expectedDAIBalanceMilton = BigInt("400000000000000000000");
        const expectedDAIBalanceMiltonLiquidityPool = expectedDAIBalanceMilton;

        const expectedIpDAIBalanceLiquidityProvider = BigInt(
            "400000000000000000000"
        );
        const expectedDAIBalanceLiquidityProvider = BigInt(
            "9989600000000000000000000"
        );

        const expectedIpDAIBalanceUserThree = BigInt("0");
        const expectedDAIBalanceUserThree = BigInt(
            "10010000000000000000000000"
        );

        const actualDAIBalanceMilton = BigInt(
            await testData.tokenDai.balanceOf(testData.miltonDai.address)
        );
        const actualDAIBalanceMiltonLiquidityPool = BigInt(
            await (
                await testData.miltonStorageDai.getBalance()
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

    // it("should NOT redeem - redeem liquidity pool utilisation already exceeded", async () => {
    // });

    // it("should NOT redeem - redeem liquidity pool utilisation exceeded", async () => {
    // });

    // it("should redeem - Liquidity Pool utilisation not exceedeed, Redeem Liquidity Pool Utilisation not exceeded, ", async () => {
    // });

    // it("should redeem - Liquidity Pool utilisation exceedeed, Redeem Liquidity Pool Utilisation not exceeded, ", async () => {
    // });
});
