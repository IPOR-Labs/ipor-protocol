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

describe("Milton", () => {
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

    it("should open pay fixed position - liquidity pool utilization not exceeded, custom utilization", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ROLE"),
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

        let closerUserEarned = ZERO;
        let openerUserLost =
            TC_OPENING_FEE_18DEC +
            TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC +
            TC_COLLATERAL_18DEC;

        let closerUserLost = openerUserLost;
        let openerUserEarned = closerUserEarned;

        let expectedOpenerUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_10MLN_18DEC + openerUserEarned - openerUserLost;
        let expectedCloserUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_10MLN_18DEC + closerUserEarned - closerUserLost;

        let miltonBalanceBeforePayoutWad = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                miltonBalanceBeforePayoutWad,
                params.openTimestamp
            );

        let expectedMiltonUnderlyingTokenBalance =
            miltonBalanceBeforePayoutWad +
            TC_OPENING_FEE_18DEC +
            TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            TC_COLLATERAL_18DEC +
            TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;

        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad + TC_OPENING_FEE_18DEC;

        let oldLpMaxUtilizationPerLegPercentage =
            await testData.iporAssetConfigurationDai.getLiquidityPoolMaxUtilizationPerLegPercentage();

        let liquidityPoolMaxUtilizationEdge = BigInt("718503678605107622");

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPerLegPercentage(
            liquidityPoolMaxUtilizationEdge
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

        //then
        await assertExpectedValues(
            testData,
            params.asset,
            0,
            userTwo,
            userTwo,
            miltonBalanceBeforePayoutWad,
            expectedMiltonUnderlyingTokenBalance,
            expectedOpenerUserUnderlyingTokenBalanceAfterClose,
            expectedCloserUserUnderlyingTokenBalanceAfterClose,
            expectedLiquidityPoolTotalBalanceWad,
            1,
            TC_COLLATERAL_18DEC,
            USD_20_18DEC,
            ZERO
        );

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPerLegPercentage(
            oldLpMaxUtilizationPerLegPercentage
        );
    });

    it("should NOT open pay fixed position - when new position opened then liquidity pool utilization exceeded, custom utilization", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("OPENING_FEE_PERCENTAGE_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ROLE"),
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

        let miltonBalanceBeforePayoutWad = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                miltonBalanceBeforePayoutWad,
                params.openTimestamp
            );

        let oldLpMaxUtilizationPercentage =
            await testData.iporAssetConfigurationDai.getLiquidityPoolMaxUtilizationPercentage();

        let liquidityPoolMaxUtilizationEdge = BigInt(608038055741904007);

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(
            liquidityPoolMaxUtilizationEdge
        );

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        //when
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

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(
            oldLpMaxUtilizationPercentage
        );
    });

    it("should NOT open pay fixed position - liquidity pool utilization already exceeded, custom utilization", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ROLE"),
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

        let oldLpMaxUtilizationPerLegPercentage =
            await testData.iporAssetConfigurationDai.getLiquidityPoolMaxUtilizationPerLegPercentage();
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        let miltonBalanceBeforePayoutWad = USD_14_000_18DEC;
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                miltonBalanceBeforePayoutWad,
                params.openTimestamp
            );

        let lpMaxUtilizationPerLegEdge = BigInt("758503678605107622");
        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPerLegPercentage(
            lpMaxUtilizationPerLegEdge
        );

        //First open position not exceeded liquidity utilization
        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor
            );

        //when
        //Second open position exceeded liquidity utilization
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

    const calculateSoap = async (testData, params) => {
        if (testData.tokenUsdt && params.asset === testData.tokenUsdt.address) {
            return await testData.miltonUsdt
                .connect(params.from)
                .itfCalculateSoap(params.calculateTimestamp);
        }

        if (testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
            return await testData.miltonUsdc
                .connect(params.from)
                .itfCalculateSoap(params.calculateTimestamp);
        }

        if (testData.tokenDai && params.asset === testData.tokenDai.address) {
            return await testData.miltonDai
                .connect(params.from)
                .itfCalculateSoap(params.calculateTimestamp);
        }
    };

    const openSwapPayFixed = async (testData, params) => {
        if (testData.tokenUsdt && params.asset === testData.tokenUsdt.address) {
            await testData.miltonUsdt
                .connect(params.from)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                );
        }
        if (testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
            await testData.miltonUsdc
                .connect(params.from)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                );
        }
        if (testData.tokenDai && params.asset === testData.tokenDai.address) {
            await testData.miltonDai
                .connect(params.from)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                );
        }
    };
    const openSwapReceiveFixed = async (testData, params) => {
        if (testData.tokenUsdt && params.asset === testData.tokenUsdt.address) {
            await testData.miltonUsdt
                .connect(params.from)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                );
        }

        if (testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
            await testData.miltonUsdc
                .connect(params.from)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                );
        }

        if (testData.tokenDai && params.asset === testData.tokenDai.address) {
            await testData.miltonDai
                .connect(params.from)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                );
        }
    };

    const countOpenSwaps = (derivatives) => {
        let count = 0;
        for (let i = 0; i < derivatives.length; i++) {
            if (derivatives[i].state == 1) {
                count++;
            }
        }
        return count;
    };

    const assertMiltonDerivativeItem = async (
        testData,
        asset,
        swapId,
        direction,
        expectedIdsIndex,
        expectedUserDerivativeIdsIndex
    ) => {
        let actualDerivativeItem = null;
        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            if (direction == 0) {
                actualDerivativeItem =
                    await testData.miltonStorageUsdt.getSwapPayFixed(swapId);
            }

            if (direction == 1) {
                actualDerivativeItem =
                    await testData.miltonStorageUsdt.getSwapReceiveFixed(
                        swapId
                    );
            }
        }
        if (testData.tokenUsdc && asset === testData.tokenUsdc.address) {
            if (direction == 0) {
                actualDerivativeItem =
                    await testData.miltonStorageUsdc.getSwapPayFixed(swapId);
            }

            if (direction == 1) {
                actualDerivativeItem =
                    await testData.miltonStorageUsdc.getSwapReceiveFixed(
                        swapId
                    );
            }
        }
        if (testData.tokenDai && asset === testData.tokenDai.address) {
            if (direction == 0) {
                actualDerivativeItem =
                    await testData.miltonStorageDai.getSwapPayFixed(swapId);
            }

            if (direction == 1) {
                actualDerivativeItem =
                    await testData.miltonStorageDai.getSwapReceiveFixed(swapId);
            }
        }

        expect(
            BigInt(expectedUserDerivativeIdsIndex),
            `Incorrect idsIndex for swap id ${actualDerivativeItem.id} actual: ${actualDerivativeItem.idsIndex}, expected: ${expectedUserDerivativeIdsIndex}`
        ).to.be.eq(BigInt(actualDerivativeItem.idsIndex));
    };

    const testCaseWhenMiltonEarnAndUserLost = async function (
        testData,
        asset,
        collateralizationFactor,
        direction,
        openerUser,
        closerUser,
        iporValueBeforeOpenSwap,
        iporValueAfterOpenSwap,
        periodOfTimeElapsedInSeconds,
        expectedOpenedPositions,
        expectedDerivativesTotalBalanceWad,
        expectedLiquidationDepositTotalBalanceWad,
        expectedTreasuryTotalBalanceWad,
        expectedSoap,
        openTimestamp,
        incomeTax,
        incomeTaxWad,
        interestAmount,
        interestAmountWad
    ) {
        let miltonBalanceBeforePayout = null;
        let miltonBalanceBeforePayoutWad = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
        let openerUserLost = null;
        let openerUserEarned = null;
        let closerUserLost = null;
        let closerUserEarned = null;
        let expectedOpenerUserUnderlyingTokenBalanceAfterClose = null;
        let expectedCloserUserUnderlyingTokenBalanceAfterClose = null;
        let expectedMiltonUnderlyingTokenBalance = null;
        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad +
            TC_OPENING_FEE_18DEC +
            interestAmountWad -
            incomeTaxWad;

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            miltonBalanceBeforePayout = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
            closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
            openerUserLost =
                TC_OPENING_FEE_18DEC +
                TC_IPOR_PUBLICATION_AMOUNT_18DEC +
                TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC +
                interestAmount;

            if (openerUser.address === closerUser.address) {
                closerUserLost = openerUserLost;
                openerUserEarned = closerUserEarned;
            } else {
                closerUserLost = ZERO;
                openerUserEarned = ZERO;
            }

            expectedOpenerUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_10MLN_18DEC + openerUserEarned - openerUserLost;
            expectedCloserUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_10MLN_18DEC + closerUserEarned - closerUserLost;
            expectedMiltonUnderlyingTokenBalance =
                TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
                TC_OPENING_FEE_18DEC +
                TC_IPOR_PUBLICATION_AMOUNT_18DEC +
                interestAmount;
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            miltonBalanceBeforePayout = TC_LP_BALANCE_BEFORE_CLOSE_6DEC;
            closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC;
            openerUserLost =
                TC_OPENING_FEE_6DEC +
                TC_IPOR_PUBLICATION_AMOUNT_6DEC +
                TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC +
                interestAmount;

            if (openerUser.address === closerUser.address) {
                closerUserLost = openerUserLost;
                openerUserEarned = closerUserEarned;
            } else {
                closerUserLost = ZERO;
                openerUserEarned = ZERO;
            }

            expectedOpenerUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_6_DECIMALS + openerUserEarned - openerUserLost;
            expectedCloserUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_6_DECIMALS + closerUserEarned - closerUserLost;
            expectedMiltonUnderlyingTokenBalance =
                TC_LP_BALANCE_BEFORE_CLOSE_6DEC +
                TC_OPENING_FEE_6DEC +
                TC_IPOR_PUBLICATION_AMOUNT_6DEC +
                interestAmount;
        }

        await exetuceCloseSwapTestCase(
            testData,
            asset,
            collateralizationFactor,
            direction,
            openerUser,
            closerUser,
            iporValueBeforeOpenSwap,
            iporValueAfterOpenSwap,
            periodOfTimeElapsedInSeconds,
            miltonBalanceBeforePayout,
            expectedMiltonUnderlyingTokenBalance,
            expectedOpenerUserUnderlyingTokenBalanceAfterClose,
            expectedCloserUserUnderlyingTokenBalanceAfterClose,
            expectedLiquidityPoolTotalBalanceWad,
            expectedOpenedPositions,
            expectedDerivativesTotalBalanceWad,
            expectedLiquidationDepositTotalBalanceWad,
            expectedTreasuryTotalBalanceWad,
            expectedSoap,
            openTimestamp
        );
    };

    const testCaseWhenMiltonLostAndUserEarn = async function (
        testData,
        asset,
        collateralizationFactor,
        direction,
        openerUser,
        closerUser,
        iporValueBeforeOpenSwap,
        iporValueAfterOpenSwap,
        periodOfTimeElapsedInSeconds,
        expectedOpenedPositions,
        expectedDerivativesTotalBalanceWad,
        expectedLiquidationDepositTotalBalanceWad,
        expectedTreasuryTotalBalanceWad,
        expectedSoap,
        openTimestamp,
        incomeTax,
        incomeTaxWad,
        interestAmount,
        interestAmountWad
    ) {
        let miltonBalanceBeforePayout = null;
        let miltonBalanceBeforePayoutWad = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
        let closerUserEarned = null;
        let openerUserLost = null;
        let closerUserLost = null;
        let openerUserEarned = null;
        let expectedMiltonUnderlyingTokenBalance = null;
        let expectedOpenerUserUnderlyingTokenBalanceAfterClose = null;
        let expectedCloserUserUnderlyingTokenBalanceAfterClose = null;

        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad -
            interestAmountWad +
            TC_OPENING_FEE_18DEC;

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            miltonBalanceBeforePayout = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
            closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
            openerUserLost =
                TC_OPENING_FEE_18DEC +
                TC_IPOR_PUBLICATION_AMOUNT_18DEC +
                TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC -
                interestAmount +
                incomeTax;

            if (openerUser.address === closerUser.address) {
                closerUserLost = openerUserLost;
                openerUserEarned = closerUserEarned;
            } else {
                closerUserLost = ZERO;
                openerUserEarned = ZERO;
            }

            expectedMiltonUnderlyingTokenBalance =
                TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
                TC_OPENING_FEE_18DEC +
                TC_IPOR_PUBLICATION_AMOUNT_18DEC -
                interestAmount +
                incomeTax;
            expectedOpenerUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_10MLN_18DEC + openerUserEarned - openerUserLost;
            expectedCloserUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_10MLN_18DEC + closerUserEarned - closerUserLost;
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            miltonBalanceBeforePayout = TC_LP_BALANCE_BEFORE_CLOSE_6DEC;
            closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC;
            openerUserLost =
                TC_OPENING_FEE_6DEC +
                TC_IPOR_PUBLICATION_AMOUNT_6DEC +
                TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC -
                interestAmount +
                incomeTax;

            if (openerUser.address === closerUser.address) {
                closerUserLost = openerUserLost;
                openerUserEarned = closerUserEarned;
            } else {
                closerUserLost = ZERO;
                openerUserEarned = ZERO;
            }

            expectedMiltonUnderlyingTokenBalance =
                TC_LP_BALANCE_BEFORE_CLOSE_6DEC +
                TC_OPENING_FEE_6DEC +
                TC_IPOR_PUBLICATION_AMOUNT_6DEC -
                interestAmount +
                incomeTax;
            expectedOpenerUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_6_DECIMALS + openerUserEarned - openerUserLost;
            expectedCloserUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_6_DECIMALS + closerUserEarned - closerUserLost;
        }

        await exetuceCloseSwapTestCase(
            testData,
            asset,
            collateralizationFactor,
            direction,
            openerUser,
            closerUser,
            iporValueBeforeOpenSwap,
            iporValueAfterOpenSwap,
            periodOfTimeElapsedInSeconds,
            miltonBalanceBeforePayout,
            expectedMiltonUnderlyingTokenBalance,
            expectedOpenerUserUnderlyingTokenBalanceAfterClose,
            expectedCloserUserUnderlyingTokenBalanceAfterClose,
            expectedLiquidityPoolTotalBalanceWad,
            expectedOpenedPositions,
            expectedDerivativesTotalBalanceWad,
            expectedLiquidationDepositTotalBalanceWad,
            expectedTreasuryTotalBalanceWad,
            expectedSoap,
            openTimestamp
        );
    };

    const exetuceCloseSwapTestCase = async function (
        testData,
        asset,
        collateralizationFactor,
        direction,
        openerUser,
        closerUser,
        iporValueBeforeOpenSwap,
        iporValueAfterOpenSwap,
        periodOfTimeElapsedInSeconds,
        providedLiquidityAmount,
        expectedMiltonUnderlyingTokenBalance,
        expectedOpenerUserUnderlyingTokenBalanceAfterPayOut,
        expectedCloserUserUnderlyingTokenBalanceAfterPayOut,
        expectedLiquidityPoolTotalBalanceWad,
        expectedOpenedPositions,
        expectedDerivativesTotalBalanceWad,
        expectedLiquidationDepositTotalBalanceWad,
        expectedTreasuryTotalBalanceWad,
        expectedSoap,
        openTimestamp
    ) {
        //given
        let localOpenTimestamp = null;
        if (openTimestamp != null) {
            localOpenTimestamp = openTimestamp;
        } else {
            localOpenTimestamp = Math.floor(Date.now() / 1000);
        }

        let totalAmount = null;

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            totalAmount = USD_10_000_18DEC;
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            totalAmount = USD_10_000_6DEC;
        }

        const params = {
            asset: asset,
            totalAmount: totalAmount,
            slippageValue: 3,
            collateralizationFactor: collateralizationFactor,
            direction: direction,
            openTimestamp: localOpenTimestamp,
            from: openerUser,
        };

        if (providedLiquidityAmount != null) {
            //in test we expect that Liquidity Pool is loosing and from its pool Milton has to paid out to closer user
            if (
                testData.tokenUsdt &&
                params.asset === testData.tokenUsdt.address
            ) {
                await testData.josephUsdt
                    .connect(liquidityProvider)
                    .itfProvideLiquidity(
                        providedLiquidityAmount,
                        params.openTimestamp
                    );
            }
            if (
                testData.tokenUsdc &&
                params.asset === testData.tokenUsdc.address
            ) {
                await testData.josephUsdc
                    .connect(liquidityProvider)
                    .itfProvideLiquidity(
                        providedLiquidityAmount,
                        params.openTimestamp
                    );
            }
            if (
                testData.tokenDai &&
                params.asset === testData.tokenDai.address
            ) {
                await testData.josephDai
                    .connect(liquidityProvider)
                    .itfProvideLiquidity(
                        providedLiquidityAmount,
                        params.openTimestamp
                    );
            }
        }

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                iporValueBeforeOpenSwap,
                params.openTimestamp
            );
        if (params.direction == 0) {
            await openSwapPayFixed(testData, params);
        } else if (params.direction == 1) {
            await openSwapReceiveFixed(testData, params);
        }

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                iporValueAfterOpenSwap,
                params.openTimestamp
            );

        let endTimestamp = params.openTimestamp + periodOfTimeElapsedInSeconds;

        //when
        if (testData.tokenUsdt && params.asset === testData.tokenUsdt.address) {
            if (params.direction == 0) {
                await testData.miltonUsdt
                    .connect(closerUser)
                    .itfCloseSwapPayFixed(1, endTimestamp);
            } else if (params.direction == 1) {
                await testData.miltonUsdt
                    .connect(closerUser)
                    .itfCloseSwapReceiveFixed(1, endTimestamp);
            }
        }

        if (testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
            if (params.direction == 0) {
                await testData.miltonUsdc
                    .connect(closerUser)
                    .itfCloseSwapPayFixed(1, endTimestamp);
            } else if (params.direction == 1) {
                await testData.miltonUsdc
                    .connect(closerUser)
                    .itfCloseSwapReceiveFixed(1, endTimestamp);
            }
        }

        if (testData.tokenDai && params.asset === testData.tokenDai.address) {
            if (params.direction == 0) {
                await testData.miltonDai
                    .connect(closerUser)
                    .itfCloseSwapPayFixed(1, endTimestamp);
            } else if (params.direction == 1) {
                await testData.miltonDai
                    .connect(closerUser)
                    .itfCloseSwapReceiveFixed(1, endTimestamp);
            }
        }

        //then
        await assertExpectedValues(
            testData,
            params.asset,
            params.direction,
            openerUser,
            closerUser,
            providedLiquidityAmount,
            expectedMiltonUnderlyingTokenBalance,
            expectedOpenerUserUnderlyingTokenBalanceAfterPayOut,
            expectedCloserUserUnderlyingTokenBalanceAfterPayOut,
            expectedLiquidityPoolTotalBalanceWad,
            expectedOpenedPositions,
            expectedDerivativesTotalBalanceWad,
            expectedLiquidationDepositTotalBalanceWad,
            expectedTreasuryTotalBalanceWad
        );

        const soapParams = {
            asset: params.asset,
            calculateTimestamp: endTimestamp,
            expectedSoap: expectedSoap,
            from: openerUser,
        };
        await assertSoap(testData, soapParams);
    };

    const assertExpectedValues = async function (
        testData,
        asset,
        direction,
        openerUser,
        closerUser,
        miltonBalanceBeforePayout,
        expectedMiltonUnderlyingTokenBalance,
        expectedOpenerUserUnderlyingTokenBalanceAfterPayOut,
        expectedCloserUserUnderlyingTokenBalanceAfterPayOut,
        expectedLiquidityPoolTotalBalanceWad,
        expectedOpenedPositions,
        expectedDerivativesTotalBalanceWad,
        expectedLiquidationDepositTotalBalanceWad,
        expectedTreasuryTotalBalanceWad
    ) {
        let actualDerivatives = null;
        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            if (direction == 0) {
                actualDerivatives =
                    await testData.miltonStorageUsdt.getSwapsPayFixed(
                        openerUser.address
                    );
            }
            if (direction == 1) {
                actualDerivatives =
                    await testData.miltonStorageUsdt.getSwapsReceiveFixed(
                        openerUser.address
                    );
            }
        }

        if (testData.tokenUsdc && asset === testData.tokenUsdc.address) {
            if (direction == 0) {
                actualDerivatives =
                    await testData.miltonStorageUsdc.getSwapsPayFixed(
                        openerUser.address
                    );
            }
            if (direction == 1) {
                actualDerivatives =
                    await testData.miltonStorageUsdc.getSwapsReceiveFixed(
                        openerUser.address
                    );
            }
        }

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            if (direction == 0) {
                actualDerivatives =
                    await testData.miltonStorageDai.getSwapsPayFixed(
                        openerUser.address
                    );
            }
            if (direction == 1) {
                actualDerivatives =
                    await testData.miltonStorageDai.getSwapsReceiveFixed(
                        openerUser.address
                    );
            }
        }

        let actualOpenSwapsVol = countOpenSwaps(actualDerivatives);

        expect(
            expectedOpenedPositions,
            `Incorrect number of opened derivatives, actual:  ${actualOpenSwapsVol}, expected: ${expectedOpenedPositions}`
        ).to.be.eq(actualOpenSwapsVol);

        let expectedOpeningFeeTotalBalanceWad = TC_OPENING_FEE_18DEC;
        let expectedPublicationFeeTotalBalanceWad = USD_10_18DEC;
        let openerUserUnderlyingTokenBalanceBeforePayout = null;
        let closerUserUnderlyingTokenBalanceBeforePayout = null;
        let miltonUnderlyingTokenBalanceAfterPayout = null;
        let openerUserUnderlyingTokenBalanceAfterPayout = null;
        let closerUserUnderlyingTokenBalanceAfterPayout = null;

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            openerUserUnderlyingTokenBalanceBeforePayout = USD_10_000_000_18DEC;
            closerUserUnderlyingTokenBalanceBeforePayout = USD_10_000_000_18DEC;

            miltonUnderlyingTokenBalanceAfterPayout = BigInt(
                await testData.tokenDai.balanceOf(testData.miltonDai.address)
            );
            openerUserUnderlyingTokenBalanceAfterPayout = BigInt(
                await testData.tokenDai.balanceOf(openerUser.address)
            );
            closerUserUnderlyingTokenBalanceAfterPayout = BigInt(
                await testData.tokenDai.balanceOf(closerUser.address)
            );
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            openerUserUnderlyingTokenBalanceBeforePayout = USD_10_000_000_6DEC;
            closerUserUnderlyingTokenBalanceBeforePayout = USD_10_000_000_6DEC;
            miltonUnderlyingTokenBalanceAfterPayout = BigInt(
                await testData.tokenUsdt.balanceOf(testData.miltonUsdt.address)
            );
            openerUserUnderlyingTokenBalanceAfterPayout = BigInt(
                await testData.tokenUsdt.balanceOf(openerUser.address)
            );
            closerUserUnderlyingTokenBalanceAfterPayout = BigInt(
                await testData.tokenUsdt.balanceOf(closerUser.address)
            );
        }

        await assertBalances(
            testData,
            asset,
            openerUser,
            closerUser,
            expectedOpenerUserUnderlyingTokenBalanceAfterPayOut,
            expectedCloserUserUnderlyingTokenBalanceAfterPayOut,
            expectedMiltonUnderlyingTokenBalance,
            expectedDerivativesTotalBalanceWad,
            expectedOpeningFeeTotalBalanceWad,
            expectedLiquidationDepositTotalBalanceWad,
            expectedPublicationFeeTotalBalanceWad,
            expectedLiquidityPoolTotalBalanceWad,
            expectedTreasuryTotalBalanceWad
        );

        let expectedSumOfBalancesBeforePayout = null;
        let actualSumOfBalances = null;

        if (openerUser.address === closerUser.address) {
            expectedSumOfBalancesBeforePayout =
                miltonBalanceBeforePayout +
                openerUserUnderlyingTokenBalanceBeforePayout;
            actualSumOfBalances =
                openerUserUnderlyingTokenBalanceAfterPayout +
                miltonUnderlyingTokenBalanceAfterPayout;
        } else {
            expectedSumOfBalancesBeforePayout =
                miltonBalanceBeforePayout +
                openerUserUnderlyingTokenBalanceBeforePayout +
                closerUserUnderlyingTokenBalanceBeforePayout;
            actualSumOfBalances =
                openerUserUnderlyingTokenBalanceAfterPayout +
                closerUserUnderlyingTokenBalanceAfterPayout +
                miltonUnderlyingTokenBalanceAfterPayout;
        }

        expect(
            expectedSumOfBalancesBeforePayout,
            `Incorrect balance between AMM Balance and Users Balance for asset ${asset}, actual: ${actualSumOfBalances}, expected ${expectedSumOfBalancesBeforePayout}`
        ).to.be.eql(actualSumOfBalances);
    };

    const assertSoap = async (testData, params) => {
        let actualSoapStruct = await calculateSoap(testData, params);
        let actualSoap = BigInt(actualSoapStruct.soap);

        //then
        expect(
            params.expectedSoap,
            `Incorrect SOAP for asset ${params.asset} actual: ${actualSoap}, expected: ${params.expectedSoap}`
        ).to.be.eql(actualSoap);
    };

    const assertBalances = async (
        testData,
        asset,
        openerUser,
        closerUser,
        expectedOpenerUserUnderlyingTokenBalance,
        expectedCloserUserUnderlyingTokenBalance,
        expectedMiltonUnderlyingTokenBalance,
        expectedDerivativesTotalBalanceWad,
        expectedOpeningFeeTotalBalanceWad,
        expectedLiquidationDepositTotalBalanceWad,
        expectedPublicationFeeTotalBalanceWad,
        expectedLiquidityPoolTotalBalanceWad,
        expectedTreasuryTotalBalanceWad
    ) => {
        let actualOpenerUserUnderlyingTokenBalance = null;
        let actualCloserUserUnderlyingTokenBalance = null;
        let balance = null;

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            actualOpenerUserUnderlyingTokenBalance = BigInt(
                await testData.tokenDai.balanceOf(openerUser.address)
            );
            actualCloserUserUnderlyingTokenBalance = BigInt(
                await testData.tokenDai.balanceOf(closerUser.address)
            );
            balance = await testData.miltonStorageDai.getBalance();
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            actualOpenerUserUnderlyingTokenBalance = BigInt(
                await testData.tokenUsdt.balanceOf(openerUser.address)
            );
            actualCloserUserUnderlyingTokenBalance = BigInt(
                await testData.tokenUsdt.balanceOf(closerUser.address)
            );
            balance = await testData.miltonStorageUsdt.getBalance();
        }

        let actualMiltonUnderlyingTokenBalance = null;
        if (testData.tokenDai && asset === testData.tokenDai.address) {
            actualMiltonUnderlyingTokenBalance = BigInt(
                await testData.tokenDai.balanceOf(testData.miltonDai.address)
            );
        }
        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            actualMiltonUnderlyingTokenBalance = BigInt(
                await testData.tokenUsdt.balanceOf(testData.miltonUsdt.address)
            );
        }
        if (testData.tokenUsdc && asset === testData.tokenUsdc.address) {
            actualMiltonUnderlyingTokenBalance = BigInt(
                await testData.tokenUsdc.balanceOf(testData.miltonUsdc.address)
            );
        }

        const actualPayFixedDerivativesBalance = BigInt(balance.payFixedSwaps);
        const actualRecFixedDerivativesBalance = BigInt(
            balance.receiveFixedSwaps
        );
        const actualDerivativesTotalBalance =
            actualPayFixedDerivativesBalance + actualRecFixedDerivativesBalance;
        const actualOpeningFeeTotalBalance = BigInt(balance.openingFee);
        const actualLiquidationDepositTotalBalance = BigInt(
            balance.liquidationDeposit
        );
        const actualPublicationFeeTotalBalance = BigInt(
            balance.iporPublicationFee
        );
        const actualLiquidityPoolTotalBalanceWad = BigInt(
            balance.liquidityPool
        );
        const actualTreasuryTotalBalanceWad = BigInt(balance.treasury);

        if (expectedMiltonUnderlyingTokenBalance !== null) {
            expect(
                actualMiltonUnderlyingTokenBalance,
                `Incorrect underlying token balance for ${asset} in Milton address, actual: ${actualMiltonUnderlyingTokenBalance}, expected: ${expectedMiltonUnderlyingTokenBalance}`
            ).to.be.eq(expectedMiltonUnderlyingTokenBalance);
        }

        if (expectedOpenerUserUnderlyingTokenBalance != null) {
            expect(
                actualOpenerUserUnderlyingTokenBalance,
                `Incorrect token balance for ${asset} in Opener User address, actual: ${actualOpenerUserUnderlyingTokenBalance}, expected: ${expectedOpenerUserUnderlyingTokenBalance}`
            ).to.be.eq(expectedOpenerUserUnderlyingTokenBalance);
        }

        if (expectedCloserUserUnderlyingTokenBalance != null) {
            expect(
                actualCloserUserUnderlyingTokenBalance,
                `Incorrect token balance for ${asset} in Closer User address, actual: ${actualCloserUserUnderlyingTokenBalance}, expected: ${expectedCloserUserUnderlyingTokenBalance}`
            ).to.be.eq(expectedCloserUserUnderlyingTokenBalance);
        }

        if (expectedDerivativesTotalBalanceWad != null) {
            expect(
                expectedDerivativesTotalBalanceWad,
                `Incorrect derivatives total balance for ${asset}, actual:  ${actualDerivativesTotalBalance}, expected: ${expectedDerivativesTotalBalanceWad}`
            ).to.be.eq(actualDerivativesTotalBalance);
        }

        if (expectedOpeningFeeTotalBalanceWad != null) {
            expect(
                expectedOpeningFeeTotalBalanceWad,
                `Incorrect opening fee total balance for ${asset}, actual:  ${actualOpeningFeeTotalBalance}, expected: ${expectedOpeningFeeTotalBalanceWad}`
            ).to.be.eq(actualOpeningFeeTotalBalance);
        }

        if (expectedLiquidationDepositTotalBalanceWad !== null) {
            expect(
                expectedLiquidationDepositTotalBalanceWad,
                `Incorrect liquidation deposit fee total balance for ${asset}, actual:  ${actualLiquidationDepositTotalBalance}, expected: ${expectedLiquidationDepositTotalBalanceWad}`
            ).to.be.eq(actualLiquidationDepositTotalBalance);
        }

        if (expectedPublicationFeeTotalBalanceWad != null) {
            expect(
                expectedPublicationFeeTotalBalanceWad,
                `Incorrect ipor publication fee total balance for ${asset}, actual: ${actualPublicationFeeTotalBalance}, expected: ${expectedPublicationFeeTotalBalanceWad}`
            ).to.be.eq(actualPublicationFeeTotalBalance);
        }

        if (expectedLiquidityPoolTotalBalanceWad != null) {
            expect(
                expectedLiquidityPoolTotalBalanceWad,
                `Incorrect Liquidity Pool total balance for ${asset}, actual:  ${actualLiquidityPoolTotalBalanceWad}, expected: ${expectedLiquidityPoolTotalBalanceWad}`
            ).to.be.eq(actualLiquidityPoolTotalBalanceWad);
        }

        if (expectedTreasuryTotalBalanceWad != null) {
            expect(
                expectedTreasuryTotalBalanceWad,
                `Incorrect Treasury total balance for ${asset}, actual:  ${actualTreasuryTotalBalanceWad}, expected: ${expectedTreasuryTotalBalanceWad}`
            ).to.be.eq(actualTreasuryTotalBalanceWad);
        }
    };
});
