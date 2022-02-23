const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");

const {
    PERCENTAGE_2_18DEC,
    PERCENTAGE_2_5_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_8_18DEC,
    PERCENTAGE_50_18DEC,
    PERCENTAGE_160_18DEC,
    PERCENTAGE_365_18DEC,
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
    absValue,
} = require("./Utils");

describe("Joseph", () => {
    let data = null;
    let admin, userOne, userTwo, userThree, liquidityProvider;
    let libraries;

    before(async () => {
        libraries = await getLibraries();
        [admin, userOne, userTwo, userThree, liquidityProvider] =
            await ethers.getSigners();
        data = await prepareData(
            libraries,
            [admin, userOne, userTwo, userThree, liquidityProvider],
            1
        );
    });

    it("should pause Smart Contract, sender is an admin", async () => {
        //when
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
        );
        await testData.josephDai.connect(admin).pause();

        //then
        await assertError(
            testData.josephDai.connect(userOne).provideLiquidity(123),
            "Pausable: paused"
        );
    });

    it("should pause Smart Contract specific methods", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
        );
        await testData.josephDai.connect(admin).pause();

        //when
        await assertError(
            testData.josephDai.connect(userOne).provideLiquidity(123),
            "Pausable: paused"
        );

        await assertError(
            testData.josephDai.connect(userOne).redeem(123),
            "Pausable: paused"
        );
    });

    it("should NOT pause Smart Contract specific methods when paused", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
        );
        await testData.josephDai.connect(admin).pause();

        //when
        await testData.josephDai.connect(userOne).decimals();
        await testData.josephDai.connect(userOne).asset();
    });

    it("should NOT pause Smart Contract, sender is NOT an admin", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
        );

        //when
        await assertError(
            testData.josephDai.connect(userThree).pause(),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should unpause Smart Contract, sender is an admin", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
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

        await testData.josephDai.connect(admin).pause();

        await assertError(
            testData.josephDai.connect(userOne).provideLiquidity(123),
            "Pausable: paused"
        );

        const expectedIpTokenBalance = BigInt("123");

        //when
        await testData.josephDai.connect(admin).unpause();
        await testData.josephDai.connect(userOne).provideLiquidity(123);

        //then
        const actualIpTokenBalance = BigInt(
            await testData.ipTokenDai.balanceOf(userOne.address)
        );
        expect(actualIpTokenBalance, "Incorrect IpToken balance.").to.be.eql(
            expectedIpTokenBalance
        );
    });

    it("should NOT unpause Smart Contract, sender is NOT an admin", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
        );

        await testData.josephDai.connect(admin).pause();

        //when
        await assertError(
            testData.josephDai.connect(userThree).unpause(),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should transfer ownership - simple case 1", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
        );
        const expectedNewOwner = userTwo;

        //when
        await testData.josephDai
            .connect(admin)
            .transferOwnership(expectedNewOwner.address);

        await testData.josephDai
            .connect(expectedNewOwner)
            .confirmTransferOwnership();

        //then
        const actualNewOwner = await testData.josephDai
            .connect(userOne)
            .owner();
        expect(expectedNewOwner.address).to.be.eql(actualNewOwner);
    });

    it("should NOT transfer ownership - sender not current owner", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
        );
        const expectedNewOwner = userTwo;

        //when
        await assertError(
            testData.josephDai
                .connect(userThree)
                .transferOwnership(expectedNewOwner.address),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT confirm transfer ownership - sender not appointed owner", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
        );
        const expectedNewOwner = userTwo;

        //when
        await testData.josephDai
            .connect(admin)
            .transferOwnership(expectedNewOwner.address);

        await assertError(
            testData.josephDai.connect(userThree).confirmTransferOwnership(),
            //then
            "IPOR_6"
        );
    });

    it("should NOT confirm transfer ownership twice - sender not appointed owner", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
        );
        const expectedNewOwner = userTwo;

        //when
        await testData.josephDai
            .connect(admin)
            .transferOwnership(expectedNewOwner.address);

        await testData.josephDai
            .connect(expectedNewOwner)
            .confirmTransferOwnership();

        await assertError(
            testData.josephDai
                .connect(expectedNewOwner)
                .confirmTransferOwnership(),
            "IPOR_6"
        );
    });

    it("should NOT transfer ownership - sender already lost ownership", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
        );
        const expectedNewOwner = userTwo;

        await testData.josephDai
            .connect(admin)
            .transferOwnership(expectedNewOwner.address);

        await testData.josephDai
            .connect(expectedNewOwner)
            .confirmTransferOwnership();

        //when
        await assertError(
            testData.josephDai
                .connect(admin)
                .transferOwnership(expectedNewOwner.address),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should have rights to transfer ownership - sender still have rights", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
        );
        const expectedNewOwner = userTwo;

        await testData.josephDai
            .connect(admin)
            .transferOwnership(expectedNewOwner.address);

        //when
        await testData.josephDai
            .connect(admin)
            .transferOwnership(expectedNewOwner.address);

        //then
        const actualNewOwner = await testData.josephDai
            .connect(userOne)
            .owner();
        expect(admin.address).to.be.eql(actualNewOwner);
    });

    it("should setup init value for Redeem LP Max Utilization Percentage", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI", "USDT", "USDC"],
            data,
            0
        );

        //when
        let actualValueUsdt =
            await testData.josephUsdt.getRedeemLpMaxUtilizationPercentage();
        let actualValueUsdc =
            await testData.josephUsdc.getRedeemLpMaxUtilizationPercentage();
        let actualValueDai =
            await testData.josephDai.getRedeemLpMaxUtilizationPercentage();

        //then
        expect(actualValueUsdt).to.be.eq(BigInt("1000000000000000000"));
        expect(actualValueUsdc).to.be.eq(BigInt("1000000000000000000"));
        expect(actualValueDai).to.be.eq(BigInt("1000000000000000000"));
    });

    it("should provide liquidity and take ipToken - simple case 1 - 18 decimals", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
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

        const expectedLiquidityProviderStableBalance = BigInt(
            "9986000000000000000000000"
        );
        const expectedLiquidityPoolBalanceMilton = USD_14_000_18DEC;

        //when
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(liquidityAmount, params.openTimestamp);

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
            liquidityAmount,
            `Incorrect ipToken balance on user for asset ${params.asset} actual: ${actualIpTokenBalanceSender}, expected: ${liquidityAmount}`
        ).to.be.eql(actualIpTokenBalanceSender);

        expect(
            liquidityAmount,
            `Incorrect DAI balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${liquidityAmount}`
        ).to.be.eql(actualUnderlyingBalanceMilton);

        expect(
            expectedLiquidityPoolBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
        ).to.be.eql(actualLiquidityPoolBalanceMilton);

        expect(
            expectedLiquidityProviderStableBalance,
            `Incorrect DAI balance on user for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
        ).to.be.eql(actualUnderlyingBalanceSender);
    });

    it("should provide liquidity and take ipToken - simple case 1 - USDT 6 decimals", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
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
        const wadLiquidityAmount = USD_14_000_18DEC;

        const expectedLiquidityProviderStableBalance = BigInt("9986000000000");
        const expectedLiquidityPoolBalanceMilton = USD_14_000_18DEC;

        //when
        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(liquidityAmount, params.openTimestamp);

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
            wadLiquidityAmount,
            `Incorrect ipToken balance on user for asset ${params.asset} actual: ${actualIpTokenBalanceSender}, expected: ${wadLiquidityAmount}`
        ).to.be.eql(actualIpTokenBalanceSender);

        expect(
            liquidityAmount,
            `Incorrect USDT balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${liquidityAmount}`
        ).to.be.eql(actualUnderlyingBalanceMilton);

        expect(
            expectedLiquidityPoolBalanceMilton,
            `Incorrect USDT Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
        ).to.be.eql(actualLiquidityPoolBalanceMilton);

        expect(
            expectedLiquidityProviderStableBalance,
            `Incorrect USDT balance on user for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
        ).to.be.eql(actualUnderlyingBalanceSender);
    });

    it("should calculate Exchange Rate when Liquidity Pool Balance and ipToken Total Supply is zero", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
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

        const expectedExchangeRate = BigInt("1000000000000000000");

        //when
        const actualExchangeRate = BigInt(
            await testData.miltonDai.calculateExchangeRate(
                Math.floor(Date.now() / 1000)
            )
        );

        //then
        expect(
            expectedExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should calculate Exchange Rate when Liquidity Pool Balance is NOT zero and ipToken Total Supply is NOT zero, DAI 18 decimals", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
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

        const expectedExchangeRate = BigInt("1000000000000000000");

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_14_000_18DEC, params.openTimestamp);

        //when
        let actualExchangeRate = BigInt(
            await testData.miltonDai.calculateExchangeRate(params.openTimestamp)
        );

        //then
        expect(
            expectedExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should calculate Exchange Rate when Liquidity Pool Balance is NOT zero and ipToken Total Supply is NOT zero, USDT 6 decimals", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
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

        const expectedExchangeRate = BigInt("1000000000000000000");

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_14_000_6DEC, params.openTimestamp);

        //when
        let actualExchangeRate = BigInt(
            await testData.miltonUsdt.calculateExchangeRate(
                params.openTimestamp
            )
        );

        //then
        expect(
            expectedExchangeRate,
            `Incorrect exchange rate for USDT, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should calculate Exchange Rate when Liquidity Pool Balance is zero and ipToken Total Supply is NOT zero", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
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

        const expectedExchangeRate = BigInt("0");

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_10_000_18DEC, params.openTimestamp);

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned

        await testData.miltonStorageDai.setJoseph(userOne.address);
        await testData.miltonStorageDai
            .connect(userOne)
            .subtractLiquidity(USD_10_000_18DEC);
        await testData.miltonStorageDai.setJoseph(testData.josephDai.address);

        //when
        const actualExchangeRate = BigInt(
            await testData.miltonDai.calculateExchangeRate(params.openTimestamp)
        );

        //then
        expect(
            expectedExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
      expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should calculate Exchange Rate, Exchange Rate greater than 1, DAI 18 decimals", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
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

        let expectedExchangeRate = BigInt("1000747756729810568");

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigInt("40000000000000000000"),
                params.openTimestamp
            );

        //open position to have something in Liquidity Pool
        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigInt("40000000000000000000"),
                params.slippageValue,
                params.collateralizationFactor
            );

        //when
        let actualExchangeRate = BigInt(
            await testData.miltonDai.calculateExchangeRate(params.openTimestamp)
        );

        //then
        expect(
            expectedExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should calculate Exchange Rate when SOAP changed, SOAP < 0 and |SOAP| < Liquidity Pool Balance, Pay Fixed", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
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

        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        //required to have IBT Price higher than 0
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigInt("60000000000000000000000"),
                params.openTimestamp
            );

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigInt("26000000000000000000000"),
                params.slippageValue,
                params.collateralizationFactor
            );

        const calculateTimestamp =
            params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        const soap = await testData.miltonDai.itfCalculateSoap(
            calculateTimestamp
        );
        const balance = await testData.miltonStorageDai.getBalance();

        const expectedExchangeRate = BigInt("1004250360789776789");

        //when
        let actualExchangeRate = BigInt(
            await testData.miltonDai.calculateExchangeRate(calculateTimestamp)
        );

        //then
        expect(soap.soap).to.be.lte(0);
        const absSoap = BigInt(-soap.soap);
        expect(absSoap).to.be.lte(balance.liquidityPool);
        expect(
            expectedExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should calculate Exchange Rate when SOAP changed, SOAP < 0 and |SOAP| < Liquidity Pool Balance, Receive Fixed", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
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

        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        //required to have IBT Price higher than 0
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigInt("60000000000000000000000"),
                params.openTimestamp
            );

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                BigInt("27000000000000000000000"),
                params.slippageValue,
                params.collateralizationFactor
            );

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_2_5_18DEC,
                params.openTimestamp
            );
        const calculateTimestamp =
            params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        const soap = await testData.miltonDai.itfCalculateSoap(
            calculateTimestamp
        );
        const balance = await testData.miltonStorageDai.getBalance();

        const expectedExchangeRate = BigInt("1002879245824171323");

        //when
        let actualExchangeRate = BigInt(
            await testData.miltonDai.calculateExchangeRate(calculateTimestamp)
        );

        //then
        expect(soap.soap).to.be.lte(0);
        const absSoap = BigInt(-soap.soap);
        expect(absSoap).to.be.lte(balance.liquidityPool);

        expect(
            expectedExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should calculate Exchange Rate when SOAP changed, SOAP > 0 and |SOAP| < Liquidity Pool Balance, Pay Fixed", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
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

        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        //required to have IBT Price higher than 0
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigInt("60000000000000000000000"),
                params.openTimestamp
            );

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigInt("27000000000000000000000"),
                params.slippageValue,
                params.collateralizationFactor
            );

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_8_18DEC,
                params.openTimestamp
            );

        const calculateTimestamp =
            params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        const soap = await testData.miltonDai.itfCalculateSoap(
            calculateTimestamp
        );
        const balance = await testData.miltonStorageDai.getBalance();

        const expectedExchangeRate = BigInt("989066232808424041");

        //when
        let actualExchangeRate = BigInt(
            await testData.miltonDai.calculateExchangeRate(calculateTimestamp)
        );

        //then
        expect(soap.soap).to.be.gte(0);
        expect(soap.soap).to.be.lte(balance.liquidityPool);

        expect(
            expectedExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should calculate Exchange Rate when SOAP changed, SOAP > 0 and |SOAP| < Liquidity Pool Balance, Receive Fixed", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
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

        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        //required to have IBT Price higher than 0
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_8_18DEC,
                params.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigInt("60000000000000000000000"),
                params.openTimestamp
            );

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                BigInt("27000000000000000000000"),
                params.slippageValue,
                params.collateralizationFactor
            );

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        const calculateTimestamp =
            params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        const soap = await testData.miltonDai.itfCalculateSoap(
            calculateTimestamp
        );
        const balance = await testData.miltonStorageDai.getBalance();

        const expectedExchangeRate = BigInt("989066232808424042");

        //when
        let actualExchangeRate = BigInt(
            await testData.miltonDai.calculateExchangeRate(calculateTimestamp)
        );

        //then
        expect(soap.soap).to.be.gte(0);
        expect(soap.soap).to.be.lte(balance.liquidityPool);
        expect(
            expectedExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should NOT calculate Exchange Rate when SOAP changed, SOAP > 0 and |SOAP| > Liquidity Pool Balance, Pay Fixed", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
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

        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        //required to have IBT Price higher than 0
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigInt("60000000000000000000000"),
                params.openTimestamp
            );

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigInt("27000000000000000000000"),
                params.slippageValue,
                params.collateralizationFactor
            );

        //BEGIN HACK - substract liquidity without  burn ipToken
        await testData.miltonStorageDai.setJoseph(admin.address);
        await testData.miltonStorageDai.subtractLiquidity(
            BigInt("55000000000000000000000")
        );
        await testData.miltonStorageDai.setJoseph(testData.josephDai.address);
        //END HACK - substract liquidity without  burn ipToken

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_50_18DEC,
                params.openTimestamp
            );

        const calculateTimestamp =
            params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        // Notice! |SOAP| > Liquidity Pool Balance
        const expectedSoap = BigInt("8471981316324997495722");
        const expectedLiquidityPoolBalance = BigInt("5080667996011964107677");

        const soap = await testData.miltonDai.itfCalculateSoap(
            calculateTimestamp
        );
        const balance = await testData.miltonStorageDai.getBalance();
        const actualSoap = BigInt(soap.soap);
        const actualLiquidityPoolBalance = BigInt(balance.liquidityPool);

        await assertError(
            //when
            testData.miltonDai.calculateExchangeRate(calculateTimestamp),
            //then
            "IPOR_47"
        );

        //then
        expect(soap.soap).to.be.gte(0);
        expect(actualSoap).to.be.gte(balance.liquidityPool);
        expect(actualSoap).to.be.eql(expectedSoap);
        expect(actualLiquidityPoolBalance).to.be.eql(
            expectedLiquidityPoolBalance
        );
    });

    it("should NOT calculate Exchange Rate when SOAP changed, SOAP > 0 and |SOAP| > Liquidity Pool Balance, Receive Fixed", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
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

        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        //required to have IBT Price higher than 0
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_50_18DEC,
                params.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigInt("60000000000000000000000"),
                params.openTimestamp
            );

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                BigInt("27000000000000000000000"),
                params.slippageValue,
                params.collateralizationFactor
            );

        //BEGIN HACK - substract liquidity without  burn ipToken
        await testData.miltonStorageDai.setJoseph(admin.address);
        await testData.miltonStorageDai.subtractLiquidity(
            BigInt("55000000000000000000000")
        );
        await testData.miltonStorageDai.setJoseph(testData.josephDai.address);
        //END HACK - substract liquidity without  burn ipToken

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        const calculateTimestamp =
            params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //Notice! |SOAP| > Liquidity Pool Balance
        const expectedSoap = BigInt("8471981316324997665162");
        const expectedLiquidityPoolBalance = BigInt("5080667996011964107677");

        const soap = await testData.miltonDai.itfCalculateSoap(
            calculateTimestamp
        );
        const balance = await testData.miltonStorageDai.getBalance();
        const actualSoap = BigInt(soap.soap);
        const actualLiquidityPoolBalance = BigInt(balance.liquidityPool);

        await assertError(
            //when
            testData.miltonDai.calculateExchangeRate(calculateTimestamp),
            //then
            "IPOR_47"
        );

        //then

        expect(actualSoap).to.be.eql(expectedSoap);
        expect(actualLiquidityPoolBalance).to.be.eql(
            expectedLiquidityPoolBalance
        );
    });

    it("should calculate Exchange Rate when SOAP changed, SOAP < 0 and |SOAP| > Liquidity Pool Balance, Pay Fixed", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
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

        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        //required to have IBT Price higher than 0
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_50_18DEC,
                params.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigInt("60000000000000000000000"),
                params.openTimestamp
            );

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigInt("27000000000000000000000"),
                params.slippageValue,
                params.collateralizationFactor
            );

        //BEGIN HACK - substract liquidity without  burn ipToken. Notice! This affect ipToken price!
        await testData.miltonStorageDai.setJoseph(admin.address);
        await testData.miltonStorageDai.subtractLiquidity(
            BigInt("55000000000000000000000")
        );
        await testData.miltonStorageDai.setJoseph(testData.josephDai.address);
        //END HACK - substract liquidity without  burn ipToken. Notice! This affect ipToken price!

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        const calculateTimestamp =
            params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        let actualExchangeRate = BigInt(
            await testData.miltonDai.calculateExchangeRate(calculateTimestamp)
        );
        const expectedExchangeRate = BigInt("232016605434837042");
        //Notice! |SOAP| > Liquidity Pool Balance
        const expectedSoap = BigInt("-8840328330078258430809");
        const expectedLiquidityPoolBalance = BigInt("5080667996011964107677");

        const soap = await testData.miltonDai.itfCalculateSoap(
            calculateTimestamp
        );
        const balance = await testData.miltonStorageDai.getBalance();
        const actualSoap = BigInt(soap.soap);
        const actualLiquidityPoolBalance = BigInt(balance.liquidityPool);

        // then
        expect(
            expectedExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);

        expect(actualSoap).to.be.eql(expectedSoap);
        expect(actualLiquidityPoolBalance).to.be.eql(
            expectedLiquidityPoolBalance
        );
    });

    it("should calculate Exchange Rate when SOAP changed, SOAP < 0 and |SOAP| > Liquidity Pool Balance, Receive Fixed", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
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

        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        //required to have IBT Price higher than 0
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigInt("60000000000000000000000"),
                params.openTimestamp
            );

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                BigInt("27000000000000000000000"),
                params.slippageValue,
                params.collateralizationFactor
            );

        //BEGIN HACK - substract liquidity without  burn ipToken. Notice! This affect ipToken price!
        await testData.miltonStorageDai.setJoseph(admin.address);
        await testData.miltonStorageDai.subtractLiquidity(
            BigInt("55000000000000000000000")
        );
        await testData.miltonStorageDai.setJoseph(testData.josephDai.address);
        //END HACK - substract liquidity without  burn ipToken. Notice! This affect ipToken price!

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_50_18DEC,
                params.openTimestamp
            );

        const calculateTimestamp =
            params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        let actualExchangeRate = BigInt(
            await testData.miltonDai.calculateExchangeRate(calculateTimestamp)
        );
        const expectedExchangeRate = BigInt("232016605434837039");

        //Notice! |SOAP| > Liquidity Pool Balance
        const expectedSoap = BigInt("-8840328330078258261370");
        const expectedLiquidityPoolBalance = BigInt("5080667996011964107677");

        const soap = await testData.miltonDai.itfCalculateSoap(
            calculateTimestamp
        );
        const balance = await testData.miltonStorageDai.getBalance();
        const actualSoap = BigInt(soap.soap);
        const actualLiquidityPoolBalance = BigInt(balance.liquidityPool);

        // then
        expect(
            expectedExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);

        expect(actualSoap).to.be.eql(expectedSoap);
        expect(actualLiquidityPoolBalance).to.be.eql(
            expectedLiquidityPoolBalance
        );
    });

    it("should calculate Exchange Rate, Exchange Rate greater than 1, USDT 6 decimals", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
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

        let expectedExchangeRate = BigInt("1000747756729810568");

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );
        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt("40000000"), params.openTimestamp);

        //open position to have something in Liquidity Pool
        await testData.miltonUsdt
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigInt("40000000"),
                params.slippageValue,
                params.collateralizationFactor
            );

        //when
        let actualExchangeRate = BigInt(
            await testData.miltonUsdt.calculateExchangeRate(
                params.openTimestamp
            )
        );

        //then
        expect(
            expectedExchangeRate,
            `Incorrect exchange rate for USDT, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should calculate Exchange Rate when Liquidity Pool Balance is NOT zero and ipToken Total Supply is zero", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
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

        const amount = BigInt("40000000000000000000");
        const expectedExchangeRate = BigInt("1000000000000000000");

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        //BEGIN HACK - provide liquidity without mint ipToken
        await testData.miltonStorageDai.setJoseph(admin.address);
        await testData.miltonStorageDai.addLiquidity(
            BigInt("2000000000000000000000")
        );
        await testData.tokenDai.transfer(
            testData.miltonDai.address,
            BigInt("2000000000000000000000")
        );
        await testData.miltonStorageDai.setJoseph(testData.josephDai.address);
        //END HACK - provide liquidity without mint ipToken

        let balance = await testData.miltonStorageDai.getBalance();

        const expectedIpTokenDaiBalance = ZERO;

        const actualIpTokenDaiBalance = BigInt(
            await testData.tokenDai.balanceOf(testData.ipTokenDai.address)
        );
        const actualLiquidityPoolBalance = balance.liquidityPool;

        //when
        let actualExchangeRate = BigInt(
            await testData.miltonDai.calculateExchangeRate(params.openTimestamp)
        );

        //then
        expect(expectedIpTokenDaiBalance).to.be.eql(actualIpTokenDaiBalance);
        expect(actualLiquidityPoolBalance).to.be.gte(ZERO);

        expect(
            expectedExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should NOT change Exchange Rate when Liquidity Provider provide liquidity, initial Exchange Rate equal to 1.5", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            1
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

        const amount = BigInt("180000000000000000000");
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(amount, params.openTimestamp);

        //open position to have something in Liquidity Pool
        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                amount,
                params.slippageValue,
                params.collateralizationFactor
            );

        //after this withdraw initial exchange rate is 1,5
        const expectedExchangeRate = BigInt("1714285714285714286");
        const exchangeRateBeforeProvideLiquidity = BigInt(
            await testData.miltonDai.calculateExchangeRate(params.openTimestamp)
        );
        const expectedIpTokenBalanceForUserThree = BigInt(
            "874999999999999999854"
        );

        // //when
        await testData.josephDai
            .connect(userThree)
            .itfProvideLiquidity(
                BigInt("1500000000000000000000"),
                params.openTimestamp
            );

        const actualIpTokenBalanceForUserThree = BigInt(
            await testData.ipTokenDai.balanceOf(userThree.address)
        );
        const actualExchangeRate = BigInt(
            await testData.miltonDai.calculateExchangeRate(params.openTimestamp)
        );

        //then
        expect(
            expectedIpTokenBalanceForUserThree,
            `Incorrect ipToken Balance for asset ${params.asset} for user ${userThree}, actual:  ${actualIpTokenBalanceForUserThree},
             expected: ${expectedIpTokenBalanceForUserThree}`
        ).to.be.eql(actualIpTokenBalanceForUserThree);

        expect(
            expectedExchangeRate,
            `Incorrect exchange rate before providing liquidity for DAI, actual:  ${exchangeRateBeforeProvideLiquidity},
            expected: ${expectedExchangeRate}`
        ).to.be.eql(exchangeRateBeforeProvideLiquidity);

        expect(
            expectedExchangeRate,
            `Incorrect exchange rate after providing liquidity for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should NOT change Exchange Rate when Liquidity Provider provide liquidity and redeem, initial Exchange Rate equal to 1.5, DAI 18 decimals", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            1
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

        const amount = BigInt("180000000000000000000");

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(amount, params.openTimestamp);

        //open position to have something in Liquidity Pool
        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                amount,
                params.slippageValue,
                params.collateralizationFactor
            );

        //after this withdraw initial exchange rate is 1,5
        const expectedExchangeRate = BigInt("1714285714285714286");
        const exchangeRateBeforeProvideLiquidity = BigInt(
            await testData.miltonDai.calculateExchangeRate(params.openTimestamp)
        );
        const expectedIpTokenBalanceForUserThree = BigInt("0");

        //when
        await testData.josephDai
            .connect(userThree)
            .itfProvideLiquidity(
                BigInt("1500000000000000000000"),
                params.openTimestamp
            );
        await testData.josephDai
            .connect(userThree)
            .itfRedeem(BigInt("874999999999999999854"), params.openTimestamp);

        const actualIpTokenBalanceForUserThree = BigInt(
            await testData.ipTokenDai.balanceOf(userThree.address)
        );
        const actualExchangeRate = BigInt(
            await testData.miltonDai.calculateExchangeRate(params.openTimestamp)
        );

        //then
        expect(
            expectedIpTokenBalanceForUserThree,
            `Incorrect ipToken Balance for DAI asset ${params.asset} for user ${userThree}, actual:  ${actualIpTokenBalanceForUserThree},
             expected: ${expectedIpTokenBalanceForUserThree}`
        ).to.be.eql(actualIpTokenBalanceForUserThree);

        expect(
            expectedExchangeRate,
            `Incorrect exchange rate before providing liquidity for DAI, actual:  ${exchangeRateBeforeProvideLiquidity},
            expected: ${expectedExchangeRate}`
        ).to.be.eql(exchangeRateBeforeProvideLiquidity);

        expect(
            expectedExchangeRate,
            `Incorrect exchange rate after providing liquidity for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should NOT change Exchange Rate when Liquidity Provider provide liquidity and redeem, initial Exchange Rate equal to 1.5, USDT 6 decimals", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
            1
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

        const amount = BigInt("180000000");
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );
        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(amount, params.openTimestamp);

        //open position to have something in Liquidity Pool
        await testData.miltonUsdt
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                amount,
                params.slippageValue,
                params.collateralizationFactor
            );

        //after this withdraw initial exchange rate is 1,5
        const expectedExchangeRate = BigInt("1714285714285714286");
        const exchangeRateBeforeProvideLiquidity = BigInt(
            await testData.miltonUsdt.calculateExchangeRate(
                params.openTimestamp
            )
        );
        const expectedIpTokenBalanceForUserThree = BigInt("0");

        //when
        await testData.josephUsdt
            .connect(userThree)
            .itfProvideLiquidity(BigInt("1500000000"), params.openTimestamp);
        await testData.josephUsdt
            .connect(userThree)
            .itfRedeem(BigInt("874999999999999999854"), params.openTimestamp);

        let actualIpTokenBalanceForUserThree = BigInt(
            await testData.ipTokenUsdt.balanceOf(userThree.address)
        );
        let actualExchangeRate = BigInt(
            await testData.miltonUsdt.calculateExchangeRate(
                params.openTimestamp
            )
        );

        //then
        expect(
            expectedIpTokenBalanceForUserThree,
            `Incorrect ipToken Balance for USDT asset ${params.asset} for user ${userThree}, actual:  ${actualIpTokenBalanceForUserThree},
             expected: ${expectedIpTokenBalanceForUserThree}`
        ).to.be.eql(actualIpTokenBalanceForUserThree);

        expect(
            expectedExchangeRate,
            `Incorrect exchange rate before providing liquidity for USDT, actual:  ${exchangeRateBeforeProvideLiquidity},
            expected: ${expectedExchangeRate}`
        ).to.be.eql(exchangeRateBeforeProvideLiquidity);

        expect(
            expectedExchangeRate,
            `Incorrect exchange rate after providing liquidity for USDT, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should NOT provide liquidity because of empty Liquidity Pool", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
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
        await testData.miltonStorageDai
            .connect(userOne)
            .subtractLiquidity(params.totalAmount);
        await testData.miltonStorageDai.setJoseph(testData.josephDai.address);

        //when
        await assertError(
            //when
            testData.josephDai
                .connect(liquidityProvider)
                .itfProvideLiquidity(params.totalAmount, params.openTimestamp),
            //then
            "IPOR_45"
        );
    });
});
