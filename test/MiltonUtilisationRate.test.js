const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");

const {
    USER_SUPPLY_6_DECIMALS,
    USER_SUPPLY_10MLN_18DEC,
    COLLATERALIZATION_FACTOR_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_5_18DEC,
    PERCENTAGE_6_18DEC,
    PERCENTAGE_10_18DEC,
    PERCENTAGE_50_18DEC,
    PERCENTAGE_100_18DEC,
    PERCENTAGE_120_18DEC,
    PERCENTAGE_160_18DEC,
    PERCENTAGE_365_18DEC,
    USD_10_6DEC,
    USD_10_18DEC,
    USD_20_18DEC,
    USD_10_000_18DEC,
    USD_10_000_6DEC,
    USD_10_400_18DEC,
    USD_14_000_18DEC,
    USD_28_000_18DEC,
    USD_14_000_6DEC,
    USD_9063__63_18DEC,
    USD_10_000_000_6DEC,

    USD_10_000_000_18DEC,
    TC_OPENING_FEE_6DEC,
    TC_OPENING_FEE_18DEC,
    TC_COLLATERAL_6DEC,
    TC_COLLATERAL_18DEC,
    TC_LP_BALANCE_BEFORE_CLOSE_6DEC,
    TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
    TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC,
    TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC,
    TC_IPOR_PUBLICATION_AMOUNT_6DEC,
    TC_IPOR_PUBLICATION_AMOUNT_18DEC,
    ZERO,
    SPECIFIC_INTEREST_AMOUNT_CASE_1,
    SPECIFIC_INCOME_TAX_CASE_1,
    PERIOD_25_DAYS_IN_SECONDS,
    PERIOD_14_DAYS_IN_SECONDS,
    PERIOD_50_DAYS_IN_SECONDS,
} = require("./Const.js");

const {
    assertError,
    getLibraries,
    getStandardDerivativeParamsDAI,
    getStandardDerivativeParamsUSDT,
    getPayFixedDerivativeParamsDAICase1,
    getPayFixedDerivativeParamsUSDTCase1,
    prepareApproveForUsers,
    prepareData,
    prepareTestData,
    grantAllSpreadRoles,
    setupDefaultSpreadConstants,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdtInitialValuesForUsers,
} = require("./Utils");

describe("Milton - Utilization Rate", () => {
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

    // it("should open pay fixed position - liquidity pool utilization not exceeded, custom utilization", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );
    //     await testData.iporAssetConfigurationDai.grantRole(
    //         keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"),
    //         admin.address
    //     );
    //     await testData.iporAssetConfigurationDai.grantRole(
    //         keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ROLE"),
    //         admin.address
    //     );
    //     await prepareApproveForUsers(
    //         [userOne, userTwo, userThree, liquidityProvider],
    //         "DAI",
    //         data,
    //         testData
    //     );
    //     await setupTokenDaiInitialValuesForUsers(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         testData
    //     );
    //     const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);

    //     let closerUserEarned = ZERO;
    //     let openerUserLost =
    //         TC_OPENING_FEE_18DEC +
    //         TC_IPOR_PUBLICATION_AMOUNT_18DEC +
    //         TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC +
    //         TC_COLLATERAL_18DEC;

    //     let closerUserLost = openerUserLost;
    //     let openerUserEarned = closerUserEarned;

    //     let expectedOpenerUserUnderlyingTokenBalanceAfterClose =
    //         USER_SUPPLY_10MLN_18DEC + openerUserEarned - openerUserLost;
    //     let expectedCloserUserUnderlyingTokenBalanceAfterClose =
    //         USER_SUPPLY_10MLN_18DEC + closerUserEarned - closerUserLost;

    //     let miltonBalanceBeforePayoutWad = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
    //     await testData.josephDai
    //         .connect(liquidityProvider)
    //         .itfProvideLiquidity(
    //             miltonBalanceBeforePayoutWad,
    //             params.openTimestamp
    //         );

    //     let expectedMiltonUnderlyingTokenBalance =
    //         miltonBalanceBeforePayoutWad +
    //         TC_OPENING_FEE_18DEC +
    //         TC_IPOR_PUBLICATION_AMOUNT_18DEC +
    //         TC_COLLATERAL_18DEC +
    //         TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;

    //     let expectedLiquidityPoolTotalBalanceWad =
    //         miltonBalanceBeforePayoutWad + TC_OPENING_FEE_18DEC;

    //     let oldLpMaxUtilizationPerLegPercentage =
    //         await testData.iporAssetConfigurationDai.getLiquidityPoolMaxUtilizationPerLegPercentage();

    //     let liquidityPoolMaxUtilizationEdge = BigInt("718503678605107622");

    //     await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPerLegPercentage(
    //         liquidityPoolMaxUtilizationEdge
    //     );

    //     await testData.warren
    //         .connect(userOne)
    //         .itfUpdateIndex(
    //             params.asset,
    //             PERCENTAGE_3_18DEC,
    //             params.openTimestamp
    //         );

    //     //when
    //     await testData.miltonDai
    //         .connect(userTwo)
    //         .itfOpenSwapPayFixed(
    //             params.openTimestamp,
    //             params.totalAmount,
    //             params.slippageValue,
    //             params.collateralizationFactor
    //         );

    //     //then
    //     await assertExpectedValues(
    //         testData,
    //         params.asset,
    //         0,
    //         userTwo,
    //         userTwo,
    //         miltonBalanceBeforePayoutWad,
    //         expectedMiltonUnderlyingTokenBalance,
    //         expectedOpenerUserUnderlyingTokenBalanceAfterClose,
    //         expectedCloserUserUnderlyingTokenBalanceAfterClose,
    //         expectedLiquidityPoolTotalBalanceWad,
    //         1,
    //         TC_COLLATERAL_18DEC,
    //         USD_20_18DEC,
    //         ZERO
    //     );

    //     await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPerLegPercentage(
    //         oldLpMaxUtilizationPerLegPercentage
    //     );
    // });

    //TODO: clarify when spread equasion will be clarified
    // it("should NOT open pay fixed position - liquidity pool utilization exceeded, liquidity pool and opening fee are ZERO", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data
    //     );
    //     await testData.iporAssetConfigurationDai.grantRole(
    //         keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE"),
    //         admin.address
    //     );
    //     await testData.iporAssetConfigurationDai.grantRole(
    //         keccak256("OPENING_FEE_PERCENTAGE_ROLE"),
    //         admin.address
    //     );
    //     await testData.iporAssetConfigurationDai.grantRole(
    //         keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"),
    //         admin.address
    //     );
    //     await testData.iporAssetConfigurationDai.grantRole(
    //         keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ROLE"),
    //         admin.address
    //     );
    //     await prepareApproveForUsers(
    //         [userOne, userTwo, userThree, liquidityProvider],
    //         "DAI",
    //         data,
    //         testData
    //     );
    //     await setupTokenDaiInitialValuesForUsers(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         testData
    //     );
    //     const params = getPayFixedDerivativeParamsDAICase1(
    //         userTwo,
    //         testData
    //     );

    //     let oldLpMaxUtilizationPercentage =
    //         await testData.iporAssetConfigurationDai.getLiquidityPoolMaxUtilizationPercentage();
    //     let oldOpeningFeePercentage =
    //         await testData.iporAssetConfigurationDai.getOpeningFeePercentage();

    //     await testData.warren.connect(userOne).itfUpdateIndex(
    //         params.asset,
    //         PERCENTAGE_3_18DEC,
    //         params.openTimestamp
    //     );

    //     await testData.iporAssetConfigurationDai.setOpeningFeePercentage(ZERO);
    //     //very high value
    //     await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(
    //         BigInt(99999999999999999999999999999999999999999)
    //     );

    //     await assertError(
    //         //when
    //         data.milton.connect(userTwo).itfOpenSwap(
    //             params.openTimestamp,
    //             params.asset,
    //             params.totalAmount,
    //             params.slippageValue,
    //             params.collateralizationFactor,
    //             params.direction
    //         ),
    //         //then
    //         "IPOR_35"
    //     );

    //     await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(
    //         oldLpMaxUtilizationPercentage
    //     );
    //     await testData.iporAssetConfigurationDai.setOpeningFeePercentage(
    //         oldOpeningFeePercentage
    //     );
    // });

    it("should open pay fixed position - liquidity pool utilization per leg not exceeded, default utilization", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        //when
        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor
            );
    });

    it("should open receive fixed position - liquidity pool utilization per leg not exceeded, default utilization", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        //when
        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor
            );
    });

    it("should open pay fixed position - liquidity pool utilization per leg not exceeded, custom utilization", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );

        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PER_LEG_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PER_LEG_PERCENTAGE_ROLE"),
            admin.address
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
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigInt("100000000000000000000000"),
                params.openTimestamp
            );

        let oldLpMaxUtilizationPerLegPercentage =
            await testData.iporAssetConfigurationDai.getLiquidityPoolMaxUtilizationPerLegPercentage();

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPerLegPercentage(
            BigInt("300000000000000000")
        );

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        //when
        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor
            );

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPerLegPercentage(
            oldLpMaxUtilizationPerLegPercentage
        );
    });

    it("should open receive fixed position - liquidity pool utilization per leg not exceeded, custom utilization", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );

        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PER_LEG_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PER_LEG_PERCENTAGE_ROLE"),
            admin.address
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
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigInt("100000000000000000000000"),
                params.openTimestamp
            );

        let oldLpMaxUtilizationPerLegPercentage =
            await testData.iporAssetConfigurationDai.getLiquidityPoolMaxUtilizationPerLegPercentage();

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPerLegPercentage(
            BigInt("300000000000000000")
        );

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        //when
        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor
            );

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPerLegPercentage(
            oldLpMaxUtilizationPerLegPercentage
        );
    });

	it("should NOT open pay fixed position - liquidity pool utilization per leg exceeded, default utilization", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await assertError(
            //when
            testData.miltonDai
                .connect(userTwo)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    USD_14_000_18DEC,
                    params.slippageValue,
                    params.collateralizationFactor
                ),
            //then
            "IPOR_35"
        );
    });

    it("should NOT open pay fixed position - liquidity pool utilization per leg exceeded, custom utilization", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );

        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PER_LEG_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PER_LEG_PERCENTAGE_ROLE"),
            admin.address
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
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        let oldLpMaxUtilizationPerLegPercentage =
            await testData.iporAssetConfigurationDai.getLiquidityPoolMaxUtilizationPerLegPercentage();

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPerLegPercentage(
            BigInt("300000000000000000")
        );

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await assertError(
            //when
            testData.miltonDai
                .connect(userTwo)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                ),
            //then
            "IPOR_35"
        );

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPerLegPercentage(
            oldLpMaxUtilizationPerLegPercentage
        );
    });

    it("should NOT open receive fixed position - liquidity pool utilization per leg exceeded, default utilization", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await assertError(
            //when
            testData.miltonDai
                .connect(userTwo)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    USD_14_000_18DEC,
                    params.slippageValue,
                    params.collateralizationFactor
                ),
            //then
            "IPOR_35"
        );
    });

    it("should NOT open pay fixed position - liquidity pool utilization per leg exceeded, custom utilization", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );

        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PER_LEG_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PER_LEG_PERCENTAGE_ROLE"),
            admin.address
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
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        let oldLpMaxUtilizationPerLegPercentage =
            await testData.iporAssetConfigurationDai.getLiquidityPoolMaxUtilizationPerLegPercentage();

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPerLegPercentage(
            BigInt("300000000000000000")
        );

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await assertError(
            //when
            testData.miltonDai
                .connect(userTwo)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                ),
            //then
            "IPOR_35"
        );

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPerLegPercentage(
            oldLpMaxUtilizationPerLegPercentage
        );
    });
});
