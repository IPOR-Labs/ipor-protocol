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
    PERCENTAGE_50_18DEC,
    PERCENTAGE_120_18DEC,
    PERCENTAGE_160_18DEC,
    PERCENTAGE_365_18DEC,
    USD_10_18DEC,
    USD_20_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USD_10_000_6DEC,
    USD_28_000_18DEC,
    USD_50_000_18DEC,
    USD_28_000_6DEC,

    TC_COLLATERAL_18DEC,
    USD_10_000_000_6DEC,

    USD_10_000_000_18DEC,
    TC_OPENING_FEE_6DEC,
    TC_OPENING_FEE_18DEC,
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
    TC_INCOME_TAX_18DEC,
    TC_COLLATERAL_6DEC,
} = require("./Const.js");

const {
    assertError,
    getStandardDerivativeParamsDAI,
    getStandardDerivativeParamsUSDT,
    getPayFixedDerivativeParamsDAICase1,
    getPayFixedDerivativeParamsUSDTCase1,
    prepareApproveForUsers,
    prepareData,
    prepareTestData,
    prepareTestDataDaiCase1,
    prepareComplexTestDataDaiCase00,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdtInitialValuesForUsers,
} = require("./Utils");

describe("Milton Maintenance", () => {
    let data = null;
    let admin, userOne, userTwo, userThree, liquidityProvider;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] =
            await ethers.getSigners();
        data = await prepareData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            1
        );
    });

    it("should pause Smart Contract, sender is an admin", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase00(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        //when
        await testData.miltonDai.connect(admin).pause();

        //then
        await assertError(
            testData.miltonDai
                .connect(userOne)
                .openSwapPayFixed(
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                ),
            "Pausable: paused"
        );
    });

    it("should pause Smart Contract specific methods", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase00(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        //simulate that userTwo is a Joseph
        await testData.miltonDai.connect(admin).setJoseph(userTwo.address);

        //when
        await testData.miltonDai.connect(admin).pause();

        //then
        await assertError(
            testData.miltonDai
                .connect(userOne)
                .openSwapPayFixed(
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                ),
            "Pausable: paused"
        );

        await assertError(
            testData.miltonDai
                .connect(userOne)
                .openSwapReceiveFixed(
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                ),
            "Pausable: paused"
        );

        await assertError(
            testData.miltonDai.connect(userOne).closeSwapPayFixed(1),
            "Pausable: paused"
        );

        await assertError(
            testData.miltonDai.connect(userOne).closeSwapReceiveFixed(1),
            "Pausable: paused"
        );

        await assertError(
            testData.miltonDai.connect(userTwo).depositToStanley(1),
            "Pausable: paused"
        );

        await assertError(
            testData.miltonDai.connect(userTwo).withdrawFromStanley(1),
            "Pausable: paused"
        );

        await assertError(
            testData.miltonDai
                .connect(admin)
                .setupMaxAllowance(userThree.address),
            "Pausable: paused"
        );

        await assertError(
            testData.miltonDai.connect(admin).setJoseph(userThree.address),
            "Pausable: paused"
        );
    });

    it("should NOT pause Smart Contract specific methods when paused", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase00(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_50_000_18DEC, params.openTimestamp);

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor
            );
        const swapPayFixed = await testData.miltonStorageDai
            .connect(userTwo)
            .getSwapPayFixed(1);

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor
            );

        const swapReceiveFixed = await testData.miltonStorageDai
            .connect(userTwo)
            .getSwapReceiveFixed(1);

        //when
        await testData.miltonDai.connect(admin).pause();

        //then
        await testData.miltonDai.connect(userOne).getVersion();
        await testData.miltonDai.connect(userOne).getAccruedBalance();
        await testData.miltonDai.connect(userOne).calculateSpread();
        await testData.miltonDai.connect(userOne).calculateSoap();
        await testData.miltonDai
            .connect(userOne)
            .calculateExchangeRate(params.openTimestamp);
        await testData.miltonDai
            .connect(userOne)
            .calculateSwapPayFixedValue(swapPayFixed);
        await testData.miltonDai
            .connect(userOne)
            .calculateSwapReceiveFixedValue(swapReceiveFixed);
        await testData.miltonDai.connect(userOne).getMiltonSpreadModel();
        await testData.miltonDai.connect(userOne).getMaxSwapCollateralAmount();
        await testData.miltonDai.connect(userOne).getMaxSlippagePercentage();
        await testData.miltonDai
            .connect(userOne)
            .getMaxLpUtilizationPercentage();
        await testData.miltonDai
            .connect(userOne)
            .getMaxLpUtilizationPerLegPercentage();
        await testData.miltonDai.connect(userOne).getIncomeTaxPercentage();
        await testData.miltonDai.connect(userOne).getOpeningFeePercentage();
        await testData.miltonDai
            .connect(userOne)
            .getOpeningFeeForTreasuryPercentage();
        await testData.miltonDai.connect(userOne).getIporPublicationFeeAmount();
        await testData.miltonDai.connect(userOne).getLiquidationDepositAmount();
        await testData.miltonDai
            .connect(userOne)
            .getMaxCollateralizationFactorValue();
        await testData.miltonDai
            .connect(userOne)
            .getMinCollateralizationFactorValue();
        await testData.miltonDai.connect(userOne).getJoseph();
    });

    it("should NOT pause Smart Contract, sender is NOT an admin", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        //when
        await assertError(
            testData.miltonDai.connect(userThree).pause(),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should unpause Smart Contract, sender is an admin", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase00(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);
        const timestamp = params.openTimestamp - 2000;
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, timestamp);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_50_000_18DEC, timestamp);

        await testData.miltonDai.connect(admin).pause();

        await assertError(
            testData.miltonDai
                .connect(userTwo)
                .openSwapPayFixed(
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                ),
            "Pausable: paused"
        );

        const expectedCollateral = BigInt("9967009897030890732780");

        //when
        await testData.miltonDai.connect(admin).unpause();
        await testData.miltonDai
            .connect(userTwo)
            .openSwapPayFixed(
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor
            );

        //then
        const swapPayFixed = await testData.miltonStorageDai
            .connect(userTwo)
            .getSwapPayFixed(1);
        const actualCollateral = BigInt(swapPayFixed.collateral);

        expect(actualCollateral, "Incorrect collateral").to.be.eql(
            expectedCollateral
        );
    });

    it("should NOT unpause Smart Contract, sender is NOT an admin", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        await testData.miltonDai.connect(admin).pause();

        //when
        await assertError(
            testData.miltonDai.connect(userThree).unpause(),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should transfer ownership - simple case 1", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        //when
        await testData.miltonDai
            .connect(admin)
            .transferOwnership(expectedNewOwner.address);

        await testData.miltonDai
            .connect(expectedNewOwner)
            .confirmTransferOwnership();

        //then
        const actualNewOwner = await testData.miltonDai
            .connect(userOne)
            .owner();
        expect(expectedNewOwner.address).to.be.eql(actualNewOwner);
    });

    it("should NOT transfer ownership - sender not current owner", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        //when
        await assertError(
            testData.miltonDai
                .connect(userThree)
                .transferOwnership(expectedNewOwner.address),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT confirm transfer ownership - sender not appointed owner", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        //when
        await testData.miltonDai
            .connect(admin)
            .transferOwnership(expectedNewOwner.address);

        await assertError(
            testData.miltonDai.connect(userThree).confirmTransferOwnership(),
            //then
            "IPOR_6"
        );
    });

    it("should NOT confirm transfer ownership twice - sender not appointed owner", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        //when
        await testData.miltonDai
            .connect(admin)
            .transferOwnership(expectedNewOwner.address);

        await testData.miltonDai
            .connect(expectedNewOwner)
            .confirmTransferOwnership();

        await assertError(
            testData.miltonDai
                .connect(expectedNewOwner)
                .confirmTransferOwnership(),
            "IPOR_6"
        );
    });

    it("should NOT transfer ownership - sender already lost ownership", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        await testData.miltonDai
            .connect(admin)
            .transferOwnership(expectedNewOwner.address);

        await testData.miltonDai
            .connect(expectedNewOwner)
            .confirmTransferOwnership();

        //when
        await assertError(
            testData.miltonDai
                .connect(admin)
                .transferOwnership(expectedNewOwner.address),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should have rights to transfer ownership - sender still have rights", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        await testData.miltonDai
            .connect(admin)
            .transferOwnership(expectedNewOwner.address);

        //when
        await testData.miltonDai
            .connect(admin)
            .transferOwnership(expectedNewOwner.address);

        //then
        const actualNewOwner = await testData.miltonDai
            .connect(userOne)
            .owner();
        expect(admin.address).to.be.eql(actualNewOwner);
    });
});
