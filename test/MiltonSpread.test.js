const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");
const { utils } = require("web3");

const {
    USER_SUPPLY_6_DECIMALS,
    USER_SUPPLY_18_DECIMALS,
    COLLATERALIZATION_FACTOR_6DEC,
    COLLATERALIZATION_FACTOR_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_3_6DEC,
    PERCENTAGE_5_18DEC,
    PERCENTAGE_6_6DEC,
    PERCENTAGE_6_18DEC,
    PERCENTAGE_10_18DEC,
    PERCENTAGE_50_18DEC,
    PERCENTAGE_100_18DEC,
    PERCENTAGE_120_18DEC,
    PERCENTAGE_160_18DEC,
    PERCENTAGE_365_18DEC,
    USD_10_6DEC,
    USD_1_18DEC,
    USD_20_18DEC,
	USD_2_000_18DEC,
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
    PERIOD_1_DAY_IN_SECONDS,
    PERIOD_25_DAYS_IN_SECONDS,
    PERIOD_14_DAYS_IN_SECONDS,
    PERIOD_28_DAYS_IN_SECONDS,
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
    setupIpTokenDaiInitialValues,
    setupIpTokenUsdtInitialValues,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdtInitialValuesForUsers,
    grantAllSpreadRolesForDAI,
} = require("./Utils");

describe("MiltonSpreadModel", () => {
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
    });

    // it("should calculate spread - demand component - Pay Fixed Derivative, PayFix Balance > RecFix Balance", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const spreadMaxValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(spreadMaxValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentKfValue(BigInt("1000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentLambdaValue(BigInt("300000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentKOmegaValue(BigInt("300000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentMaxLiquidityRedemptionValue(
    //             BigInt("1000000000000000000")
    //         );

    //     const asset = await testData.tokenDai.address;
    //     const derivativeDeposit = USD_10_000_18DEC;
    //     const derivativeOpeningFee = USD_20_18DEC;
    //     const liquidityPool = BigInt("1000000000000000000000000");
    //     const payFixedDerivativesBalance = BigInt("2000000000000000000000");
    //     const recFixedDerivativesBalance = BigInt("1000000000000000000000");
    //     const expectedSpreadDemandComponentValue = BigInt("83335000000000000");

    //     //when
    //     let actualSpreadDemandComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(liquidityProvider)
    //             .calculateDemandComponentPayFixed(
    //                 asset,
    //                 derivativeDeposit,
    //                 derivativeOpeningFee,
    //                 liquidityPool,
    //                 payFixedDerivativesBalance,
    //                 recFixedDerivativesBalance
    //             )
    //     );

    //     //then

    //     expect(
    //         expectedSpreadDemandComponentValue,
    //         `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
    //     ).to.be.eq(actualSpreadDemandComponentValue);
    // });

    // it("should calculate spread - demand component - Pay Fixed Derivative, PayFix Balance = RecFix Balance", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );
    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const spreadMaxValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(spreadMaxValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentKfValue(BigInt("1000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentLambdaValue(BigInt("300000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentKOmegaValue(BigInt("300000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentMaxLiquidityRedemptionValue(
    //             BigInt("1000000000000000000")
    //         );

    //     const asset = await testData.tokenDai.address;
    //     const derivativeDeposit = USD_10_000_18DEC;
    //     const derivativeOpeningFee = USD_20_18DEC;
    //     const liquidityPool = BigInt("1000000000000000000000000");
    //     const payFixedDerivativesBalance = BigInt("1000000000000000000000");
    //     const recFixedDerivativesBalance = BigInt("1000000000000000000000");

    //     const expectedSpreadDemandComponentValue = BigInt("90910909090909091");

    //     //when
    //     let actualSpreadDemandComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(liquidityProvider)
    //             .calculateDemandComponentPayFixed(
    //                 asset,
    //                 derivativeDeposit,
    //                 derivativeOpeningFee,
    //                 liquidityPool,
    //                 payFixedDerivativesBalance,
    //                 recFixedDerivativesBalance
    //             )
    //     );

    //     //then

    //     expect(
    //         expectedSpreadDemandComponentValue,
    //         `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
    //     ).to.be.eq(actualSpreadDemandComponentValue);
    // });

    // it("should calculate spread - demand component - Pay Fixed Derivative, PayFix Balance < RecFix Balance", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );
    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const spreadMaxValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(spreadMaxValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentKfValue(BigInt("1000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentLambdaValue(BigInt("300000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentKOmegaValue(BigInt("300000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentMaxLiquidityRedemptionValue(
    //             BigInt("1000000000000000000")
    //         );

    //     const asset = await testData.tokenDai.address;
    //     const derivativeDeposit = USD_10_000_18DEC;
    //     const derivativeOpeningFee = USD_20_18DEC;
    //     const liquidityPool = BigInt("1000000000000000000000000");
    //     const payFixedDerivativesBalance = BigInt("1000000000000000000000");
    //     const recFixedDerivativesBalance = BigInt("2000000000000000000000");

    //     const expectedSpreadDemandComponentValue = BigInt("90910909090909091");

    //     //when
    //     let actualSpreadDemandComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(liquidityProvider)
    //             .calculateDemandComponentPayFixed(
    //                 asset,
    //                 derivativeDeposit,
    //                 derivativeOpeningFee,
    //                 liquidityPool,
    //                 payFixedDerivativesBalance,
    //                 recFixedDerivativesBalance
    //             )
    //     );

    //     //then

    //     expect(
    //         expectedSpreadDemandComponentValue,
    //         `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
    //     ).to.be.eq(actualSpreadDemandComponentValue);
    // });

    // it("should calculate spread - demand component - Pay Fixed Derivative, 100% utilization rate including position ", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );
    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const spreadMaxValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(spreadMaxValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentKfValue(BigInt("1000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentKOmegaValue(BigInt("300000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentMaxLiquidityRedemptionValue(
    //             BigInt("1000000000000000000")
    //         );

    //     const asset = await testData.tokenDai.address;
    //     const derivativeDeposit = BigInt("1000000000000000000000");
    //     const derivativeOpeningFee = USD_20_18DEC;
    //     const liquidityPool = BigInt("1000000000000000000000");
    //     const payFixedDerivativesBalance = USD_20_18DEC;
    //     const recFixedDerivativesBalance = BigInt("1000000000000000000000");

    //     const expectedSpreadDemandComponentValue = BigInt("1000000000000000");

    //     //when
    //     let actualSpreadDemandComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(liquidityProvider)
    //             .calculateDemandComponentPayFixed(
    //                 asset,
    //                 derivativeDeposit,
    //                 derivativeOpeningFee,
    //                 liquidityPool,
    //                 payFixedDerivativesBalance,
    //                 recFixedDerivativesBalance
    //             )
    //     );

    //     //then
    //     expect(
    //         expectedSpreadDemandComponentValue,
    //         `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
    //     ).to.be.eq(actualSpreadDemandComponentValue);
    // });

    // it("should calculate spread - demand component - Pay Fixed Derivative, imbalance factor > 0, opening fee > 0, pay fixed derivative balance > 0 ", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );
    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const spreadMaxValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(spreadMaxValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentKfValue(BigInt("1000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentLambdaValue(BigInt("300000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentKOmegaValue(BigInt("300000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentMaxLiquidityRedemptionValue(
    //             BigInt("1000000000000000000")
    //         );

    //     const asset = await testData.tokenDai.address;
    //     const derivativeDeposit = BigInt("10000000000000000000000");
    //     const derivativeOpeningFee = USD_20_18DEC;
    //     const liquidityPool = BigInt("15000000000000000000000");
    //     const payFixedDerivativesBalance = BigInt("1000000000000000000000");
    //     const recFixedDerivativesBalance = BigInt("13000000000000000000000");

    //     const expectedSpreadDemandComponentValue = BigInt("1444230769230769");

    //     //when
    //     let actualSpreadDemandComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(liquidityProvider)
    //             .calculateDemandComponentPayFixed(
    //                 asset,
    //                 derivativeDeposit,
    //                 derivativeOpeningFee,
    //                 liquidityPool,
    //                 payFixedDerivativesBalance,
    //                 recFixedDerivativesBalance
    //             )
    //     );

    //     //then
    //     expect(
    //         expectedSpreadDemandComponentValue,
    //         `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
    //     ).to.be.eq(actualSpreadDemandComponentValue);
    // });

    // it("should calculate spread - demand component - Pay Fixed Derivative, imbalance factor > 0, opening fee > 0, pay fixed derivative balance = 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );
    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const spreadMaxValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(spreadMaxValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentKfValue(BigInt("1000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentLambdaValue(BigInt("300000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentKOmegaValue(BigInt("300000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentMaxLiquidityRedemptionValue(
    //             BigInt("1000000000000000000")
    //         );

    //     const asset = await testData.tokenDai.address;
    //     const derivativeDeposit = BigInt("10000000000000000000000");
    //     const derivativeOpeningFee = USD_20_18DEC;
    //     const liquidityPool = BigInt("15000000000000000000000");
    //     const payFixedDerivativesBalance = ZERO;
    //     const recFixedDerivativesBalance = BigInt("13000000000000000000000");

    //     const expectedSpreadDemandComponentValue = BigInt("1650549450549451");

    //     //when
    //     let actualSpreadDemandComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(liquidityProvider)
    //             .calculateDemandComponentPayFixed(
    //                 asset,
    //                 derivativeDeposit,
    //                 derivativeOpeningFee,
    //                 liquidityPool,
    //                 payFixedDerivativesBalance,
    //                 recFixedDerivativesBalance
    //             )
    //     );

    //     //then
    //     expect(
    //         expectedSpreadDemandComponentValue,
    //         `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
    //     ).to.be.eq(actualSpreadDemandComponentValue);
    // });

    // it("should calculate spread - demand component - Pay Fixed Derivative, imbalance factor > 0, opening fee = 0, pay fixed derivative balance = 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );
    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const spreadMaxValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(spreadMaxValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentKfValue(BigInt("1000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentLambdaValue(BigInt("300000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentKOmegaValue(BigInt("300000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadDemandComponentMaxLiquidityRedemptionValue(
    //             BigInt("1000000000000000000")
    //         );

    //     const asset = await testData.tokenDai.address;
    //     const derivativeDeposit = BigInt("10000000000000000000000");
    //     const derivativeOpeningFee = ZERO;
    //     const liquidityPool = BigInt("15000000000000000000000");
    //     const payFixedDerivativesBalance = ZERO;
    //     const recFixedDerivativesBalance = BigInt("13000000000000000000000");

    //     const expectedSpreadDemandComponentValue = BigInt("1648351648351648");

    //     //when
    //     let actualSpreadDemandComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(liquidityProvider)
    //             .calculateDemandComponentPayFixed(
    //                 asset,
    //                 derivativeDeposit,
    //                 derivativeOpeningFee,
    //                 liquidityPool,
    //                 payFixedDerivativesBalance,
    //                 recFixedDerivativesBalance
    //             )
    //     );

    //     //then
    //     expect(
    //         expectedSpreadDemandComponentValue,
    //         `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
    //     ).to.be.eq(actualSpreadDemandComponentValue);
    // });


	it("should calculate spread - demand component - Pay Fixed Derivative, Adjusted Utilization Rate equal M , Kf denominator = 0 ", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        await grantAllSpreadRolesForDAI(testData, admin, userOne);

        const spreadMaxValue = BigInt("300000000000000000");

        await testData.iporAssetConfigurationDai
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await testData.iporAssetConfigurationDai
            .connect(userOne)
            .setSpreadDemandComponentKfValue(BigInt("1000000000000000"));

        await testData.iporAssetConfigurationDai
            .connect(userOne)
            .setSpreadDemandComponentLambdaValue(BigInt("300000000000000000"));

        await testData.iporAssetConfigurationDai
            .connect(userOne)
            .setSpreadDemandComponentKOmegaValue(BigInt("300000000000000000"));

        const maxLiquidityRedemptionValue = BigInt("1230000000000000000");
        await testData.iporAssetConfigurationDai
            .connect(userOne)
            .setSpreadDemandComponentMaxLiquidityRedemptionValue(
                maxLiquidityRedemptionValue
            );

        const asset = await testData.tokenDai.address;
        const derivativeDeposit = USD_10_000_18DEC;
        const derivativeOpeningFee = USD_20_18DEC;
        const liquidityPool = USD_14_000_18DEC;
        const payFixedDerivativesBalance = USD_2_000_18DEC;
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");
        const expectedSpreadDemandComponentValue = BigInt("83335000000000000");
		
        //when
		let x = await testData.miltonSpread
		.connect(liquidityProvider)
		.calculateDemandComponentPayFixed(
			asset,
			derivativeDeposit,
			derivativeOpeningFee,
			liquidityPool,
			payFixedDerivativesBalance,
			recFixedDerivativesBalance
		);
		console.log(x);
        const actualSpreadDemandComponentValue = BigInt(x
        );

        //then
		
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    // it("should calculate spread - demand component - Rec Fixed Derivative, PayFix Balance > RecFix Balance", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     const asset = await testData.tokenDai.address;
    //     const derivativeDeposit = USD_10_000_18DEC;
    //     const derivativeOpeningFee = USD_20_18DEC;
    //     const liquidityPool = BigInt("15000000000000000000000");
    //     const payFixedDerivativesBalance = BigInt("13000000000000000000000");
    //     const recFixedDerivativesBalance = BigInt("1000000000000000000000");

    //     const expectedSpreadDemandComponentValue = BigInt("1444230769230769");

    //     //when
    //     let actualSpreadDemandComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(liquidityProvider)
    //             .calculateDemandComponentRecFixed(
    //                 asset,
    //                 derivativeDeposit,
    //                 derivativeOpeningFee,
    //                 liquidityPool,
    //                 payFixedDerivativesBalance,
    //                 recFixedDerivativesBalance
    //             )
    //     );

    //     //then

    //     expect(
    //         expectedSpreadDemandComponentValue,
    //         `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
    //     ).to.be.eq(actualSpreadDemandComponentValue);
    // });

    // it("should calculate spread - demand component - Rec Fixed Derivative, PayFix Balance = RecFix Balance", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     const asset = await testData.tokenDai.address;
    //     const derivativeDeposit = USD_10_000_18DEC;
    //     const derivativeOpeningFee = USD_20_18DEC;
    //     const liquidityPool = BigInt("15000000000000000000000");
    //     const payFixedDerivativesBalance = BigInt("5000000000000000000000");
    //     const recFixedDerivativesBalance = BigInt("5000000000000000000000");

    //     const expectedSpreadDemandComponentValue = BigInt("1001333333333333");

    //     //when
    //     let actualSpreadDemandComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(liquidityProvider)
    //             .calculateDemandComponentRecFixed(
    //                 asset,
    //                 derivativeDeposit,
    //                 derivativeOpeningFee,
    //                 liquidityPool,
    //                 payFixedDerivativesBalance,
    //                 recFixedDerivativesBalance
    //             )
    //     );

    //     //then

    //     expect(
    //         expectedSpreadDemandComponentValue,
    //         `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
    //     ).to.be.eq(actualSpreadDemandComponentValue);
    // });

    // it("should calculate spread - demand component - Rec Fixed Derivative, PayFix Balance < RecFix Balance", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     const asset = await testData.tokenDai.address;
    //     const derivativeDeposit = USD_10_000_18DEC;
    //     const derivativeOpeningFee = USD_20_18DEC;
    //     const liquidityPool = BigInt("15000000000000000000000");
    //     const payFixedDerivativesBalance = BigInt("1000000000000000000000");
    //     const recFixedDerivativesBalance = BigInt("3000000000000000000000");

    //     const expectedSpreadDemandComponentValue = BigInt("1155384615384615");

    //     //when
    //     let actualSpreadDemandComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(liquidityProvider)
    //             .calculateDemandComponentRecFixed(
    //                 asset,
    //                 derivativeDeposit,
    //                 derivativeOpeningFee,
    //                 liquidityPool,
    //                 payFixedDerivativesBalance,
    //                 recFixedDerivativesBalance
    //             )
    //     );

    //     //then

    //     expect(
    //         expectedSpreadDemandComponentValue,
    //         `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
    //     ).to.be.eq(actualSpreadDemandComponentValue);
    // });

    // it("should calculate spread - demand component - Rec Fixed Derivative, 100% utilization rate including position ", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     const asset = await testData.tokenDai.address;
    //     const derivativeDeposit = BigInt("1000000000000000000000");
    //     const derivativeOpeningFee = USD_20_18DEC;
    //     const liquidityPool = BigInt("1000000000000000000000");
    //     const payFixedDerivativesBalance = BigInt("1000000000000000000000");
    //     const recFixedDerivativesBalance = USD_20_18DEC;

    //     const expectedSpreadDemandComponentValue = BigInt("1000000000000000");

    //     //when
    //     let actualSpreadDemandComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(liquidityProvider)
    //             .calculateDemandComponentRecFixed(
    //                 asset,
    //                 derivativeDeposit,
    //                 derivativeOpeningFee,
    //                 liquidityPool,
    //                 payFixedDerivativesBalance,
    //                 recFixedDerivativesBalance
    //             )
    //     );

    //     //then

    //     expect(
    //         expectedSpreadDemandComponentValue,
    //         `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
    //     ).to.be.eq(actualSpreadDemandComponentValue);
    // });

    // it("should calculate spread - demand component - Rec Fixed Derivative, imbalance factor > 0, opening fee > 0, rec fixed derivative balance > 0 ", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     const asset = await testData.tokenDai.address;
    //     const derivativeDeposit = BigInt("10000000000000000000000");
    //     const derivativeOpeningFee = USD_20_18DEC;
    //     const liquidityPool = BigInt("15000000000000000000000");
    //     const payFixedDerivativesBalance = BigInt("13000000000000000000000");
    //     const recFixedDerivativesBalance = BigInt("1000000000000000000000");

    //     const expectedSpreadDemandComponentValue = BigInt("1444230769230769");

    //     //when
    //     let actualSpreadDemandComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(liquidityProvider)
    //             .calculateDemandComponentRecFixed(
    //                 asset,
    //                 derivativeDeposit,
    //                 derivativeOpeningFee,
    //                 liquidityPool,
    //                 payFixedDerivativesBalance,
    //                 recFixedDerivativesBalance
    //             )
    //     );

    //     //then
    //     expect(
    //         expectedSpreadDemandComponentValue,
    //         `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
    //     ).to.be.eq(actualSpreadDemandComponentValue);
    // });

    // it("should calculate spread - demand component - Rec Fixed Derivative, imbalance factor > 0, opening fee > 0, rec fixed derivative balance = 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     const asset = await testData.tokenDai.address;
    //     const derivativeDeposit = BigInt("10000000000000000000000");
    //     const derivativeOpeningFee = USD_20_18DEC;
    //     const liquidityPool = BigInt("15000000000000000000000");
    //     const payFixedDerivativesBalance = BigInt("13000000000000000000000");
    //     const recFixedDerivativesBalance = ZERO;

    //     const expectedSpreadDemandComponentValue = BigInt("1650549450549451");

    //     //when
    //     let actualSpreadDemandComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(liquidityProvider)
    //             .calculateDemandComponentRecFixed(
    //                 asset,
    //                 derivativeDeposit,
    //                 derivativeOpeningFee,
    //                 liquidityPool,
    //                 payFixedDerivativesBalance,
    //                 recFixedDerivativesBalance
    //             )
    //     );

    //     //then
    //     expect(
    //         expectedSpreadDemandComponentValue,
    //         `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
    //     ).to.be.eq(actualSpreadDemandComponentValue);
    // });

    // it("should calculate spread - demand component - Rec Fixed Derivative, imbalance factor > 0, opening fee = 0, rec fixed derivative balance = 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     const asset = await testData.tokenDai.address;
    //     const derivativeDeposit = BigInt("10000000000000000000000");
    //     const derivativeOpeningFee = ZERO;
    //     const liquidityPool = BigInt("15000000000000000000000");
    //     const payFixedDerivativesBalance = BigInt("13000000000000000000000");
    //     const recFixedDerivativesBalance = ZERO;

    //     const expectedSpreadDemandComponentValue = BigInt("1648351648351648");

    //     //when
    //     let actualSpreadDemandComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(liquidityProvider)
    //             .calculateDemandComponentRecFixed(
    //                 asset,
    //                 derivativeDeposit,
    //                 derivativeOpeningFee,
    //                 liquidityPool,
    //                 payFixedDerivativesBalance,
    //                 recFixedDerivativesBalance
    //             )
    //     );

    //     //then
    //     expect(
    //         expectedSpreadDemandComponentValue,
    //         `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
    //     ).to.be.eq(actualSpreadDemandComponentValue);
    // });

    // // it("should calculate spread - demand component - Rec Fixed Derivative, Adjusted Utilization Rate equal M , Kf denominator = 0 ", async () => {
    // //     //TODO: implement it
    // // });	

    // it("should calculate spread - at par component - Pay Fixed, EMAi > Ii, KVol denominator != 0, KHist denominator != 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(BigInt("300000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKVolValue(BigInt("31000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKHistValue(BigInt("14000000000000000"));

    //     const asset = await testData.tokenDai.address;
    //     const iporIndexValue = BigInt("30000000000000000");
    //     const exponentialMovingAverage = BigInt("40000000000000000");
    //     const exponentialWeightedMovingVariance = BigInt("35000000000000000");

    //     //when
    //     let actualSpreadAtParComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(userOne)
    //             .calculateAtParComponentPayFixed(
    //                 asset,
    //                 iporIndexValue,
    //                 exponentialMovingAverage,
    //                 exponentialWeightedMovingVariance
    //             )
    //     );

    //     const expectedSpreadAtParComponentValue = BigInt("46265766473020359");
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Pay Fixed, EMAi > Ii, KVol denominator != 0, KHist denominator == 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const maxSpreadValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(maxSpreadValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKVolValue(BigInt("31000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKHistValue(BigInt("14000000000000000"));

    //     const asset = await testData.tokenDai.address;
    //     const iporIndexValue = BigInt("50000000000000000");
    //     const exponentialMovingAverage = BigInt("1050000000000000000");
    //     const exponentialWeightedMovingVariance = BigInt("35000000000000000");

    //     //when
    //     let actualSpreadAtParComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(userOne)
    //             .calculateAtParComponentPayFixed(
    //                 asset,
    //                 iporIndexValue,
    //                 exponentialMovingAverage,
    //                 exponentialWeightedMovingVariance
    //             )
    //     );

    //     const expectedSpreadAtParComponentValue = maxSpreadValue;

    //     //then
    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Pay Fixed, EMAi > Ii, KVol denominator == 0, KHist denominator != 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const maxSpreadValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(maxSpreadValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKVolValue(BigInt("31000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKHistValue(BigInt("14000000000000000"));

    //     const asset = await testData.tokenDai.address;
    //     const iporIndexValue = BigInt("30000000000000000");
    //     const exponentialMovingAverage = BigInt("40000000000000000");
    //     const exponentialWeightedMovingVariance = USD_1_18DEC;

    //     //when
    //     let actualSpreadAtParComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(userOne)
    //             .calculateAtParComponentPayFixed(
    //                 asset,
    //                 iporIndexValue,
    //                 exponentialMovingAverage,
    //                 exponentialWeightedMovingVariance
    //             )
    //     );

    //     const expectedSpreadAtParComponentValue = maxSpreadValue;

    //     //then
    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Pay Fixed, EMAi > Ii, KVol denominator == 0, KHist denominator == 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const maxSpreadValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(maxSpreadValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKVolValue(BigInt("31000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKHistValue(BigInt("14000000000000000"));

    //     const asset = await testData.tokenDai.address;
    //     const iporIndexValue = BigInt("50000000000000000");
    //     const exponentialMovingAverage = BigInt("1050000000000000000");
    //     const exponentialWeightedMovingVariance = USD_1_18DEC;

    //     //when
    //     let actualSpreadAtParComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(userOne)
    //             .calculateAtParComponentPayFixed(
    //                 asset,
    //                 iporIndexValue,
    //                 exponentialMovingAverage,
    //                 exponentialWeightedMovingVariance
    //             )
    //     );

    //     const expectedSpreadAtParComponentValue = maxSpreadValue;

    //     //then
    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Pay Fixed, EMAi < Ii, KVol denominator != 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const spreadMaxValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(spreadMaxValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKVolValue(BigInt("31000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKHistValue(BigInt("14000000000000000"));

    //     const asset = await testData.tokenDai.address;
    //     const iporIndexValue = BigInt("60000000000000000");
    //     const exponentialMovingAverage = BigInt("40000000000000000");
    //     const exponentialWeightedMovingVariance = BigInt("35000000000000000");

    //     //when
    //     let actualSpreadAtParComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(userOne)
    //             .calculateAtParComponentPayFixed(
    //                 asset,
    //                 iporIndexValue,
    //                 exponentialMovingAverage,
    //                 exponentialWeightedMovingVariance
    //             )
    //     );

    //     const expectedSpreadAtParComponentValue = BigInt("32124352331606218");
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Pay Fixed, EMAi < Ii, KVol denominator == 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const spreadMaxValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(spreadMaxValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKVolValue(BigInt("31000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKHistValue(BigInt("14000000000000000"));

    //     const asset = await testData.tokenDai.address;
    //     const iporIndexValue = BigInt("60000000000000000");
    //     const exponentialMovingAverage = BigInt("40000000000000000");
    //     const exponentialWeightedMovingVariance = USD_1_18DEC;

    //     //when
    //     let actualSpreadAtParComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(userOne)
    //             .calculateAtParComponentPayFixed(
    //                 asset,
    //                 iporIndexValue,
    //                 exponentialMovingAverage,
    //                 exponentialWeightedMovingVariance
    //             )
    //     );

    //     const expectedSpreadAtParComponentValue = spreadMaxValue;
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Pay Fixed, EMAi == Ii, KVol denominator != 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const spreadMaxValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(spreadMaxValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKVolValue(BigInt("31000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKHistValue(BigInt("14000000000000000"));

    //     const asset = await testData.tokenDai.address;
    //     const iporIndexValue = BigInt("60000000000000000");
    //     const exponentialMovingAverage = iporIndexValue;
    //     const exponentialWeightedMovingVariance = BigInt("35000000000000000");

    //     //when
    //     let actualSpreadAtParComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(userOne)
    //             .calculateAtParComponentPayFixed(
    //                 asset,
    //                 iporIndexValue,
    //                 exponentialMovingAverage,
    //                 exponentialWeightedMovingVariance
    //             )
    //     );

    //     const expectedSpreadAtParComponentValue = BigInt("46124352331606218");
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Pay Fixed, EMAi == Ii, KVol denominator == 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const spreadMaxValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(spreadMaxValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKVolValue(BigInt("31000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKHistValue(BigInt("14000000000000000"));

    //     const asset = await testData.tokenDai.address;
    //     const iporIndexValue = BigInt("60000000000000000");
    //     const exponentialMovingAverage = iporIndexValue;
    //     const exponentialWeightedMovingVariance = USD_1_18DEC;

    //     //when
    //     let actualSpreadAtParComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(userOne)
    //             .calculateAtParComponentPayFixed(
    //                 asset,
    //                 iporIndexValue,
    //                 exponentialMovingAverage,
    //                 exponentialWeightedMovingVariance
    //             )
    //     );

    //     const expectedSpreadAtParComponentValue = spreadMaxValue;
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Rec Fixed, EMAi < Ii, KVol denominator != 0, KHist denominator != 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const spreadMaxValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(spreadMaxValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKVolValue(BigInt("31000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKHistValue(BigInt("14000000000000000"));

    //     const asset = await testData.tokenDai.address;
    //     const iporIndexValue = BigInt("60000000000000000");
    //     const exponentialMovingAverage = BigInt("40000000000000000");
    //     const exponentialWeightedMovingVariance = BigInt("35000000000000000");

    //     //when
    //     let actualSpreadAtParComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(userOne)
    //             .calculateAtParComponentRecFixed(
    //                 asset,
    //                 iporIndexValue,
    //                 exponentialMovingAverage,
    //                 exponentialWeightedMovingVariance
    //             )
    //     );

    //     const expectedSpreadAtParComponentValue = BigInt("46410066617320504");
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Rec Fixed, EMAi < Ii, KVol denominator != 0, KHist denominator == 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const spreadMaxValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(spreadMaxValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKVolValue(BigInt("31000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKHistValue(BigInt("14000000000000000"));

    //     const asset = await testData.tokenDai.address;
    //     const iporIndexValue = BigInt("1050000000000000000");
    //     const exponentialMovingAverage = BigInt("50000000000000000");
    //     const exponentialWeightedMovingVariance = BigInt("35000000000000000");

    //     //when
    //     let actualSpreadAtParComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(userOne)
    //             .calculateAtParComponentRecFixed(
    //                 asset,
    //                 iporIndexValue,
    //                 exponentialMovingAverage,
    //                 exponentialWeightedMovingVariance
    //             )
    //     );

    //     const expectedSpreadAtParComponentValue = spreadMaxValue;
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Rec Fixed, EMAi < Ii, KVol denominator == 0, KHist denominator != 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const spreadMaxValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(spreadMaxValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKVolValue(BigInt("31000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKHistValue(BigInt("14000000000000000"));

    //     const asset = await testData.tokenDai.address;
    //     const iporIndexValue = BigInt("60000000000000000");
    //     const exponentialMovingAverage = BigInt("40000000000000000");
    //     const exponentialWeightedMovingVariance = USD_1_18DEC;

    //     //when
    //     let actualSpreadAtParComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(userOne)
    //             .calculateAtParComponentRecFixed(
    //                 asset,
    //                 iporIndexValue,
    //                 exponentialMovingAverage,
    //                 exponentialWeightedMovingVariance
    //             )
    //     );

    //     const expectedSpreadAtParComponentValue = spreadMaxValue;
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Rec Fixed, EMAi < Ii, KVol denominator == 0, KHist denominator == 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const spreadMaxValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(spreadMaxValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKVolValue(BigInt("31000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKHistValue(BigInt("14000000000000000"));

    //     const asset = await testData.tokenDai.address;
    //     const iporIndexValue = BigInt("1050000000000000000");
    //     const exponentialMovingAverage = BigInt("50000000000000000");
    //     const exponentialWeightedMovingVariance = USD_1_18DEC;

    //     //when
    //     let actualSpreadAtParComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(userOne)
    //             .calculateAtParComponentRecFixed(
    //                 asset,
    //                 iporIndexValue,
    //                 exponentialMovingAverage,
    //                 exponentialWeightedMovingVariance
    //             )
    //     );

    //     const expectedSpreadAtParComponentValue = spreadMaxValue;
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Rec Fixed, EMAi > Ii, KVol denominator != 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const spreadMaxValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(spreadMaxValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKVolValue(BigInt("31000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKHistValue(BigInt("14000000000000000"));

    //     const asset = await testData.tokenDai.address;
    //     const iporIndexValue = BigInt("33000000000000000");
    //     const exponentialMovingAverage = BigInt("40000000000000000");
    //     const exponentialWeightedMovingVariance = BigInt("35000000000000000");

    //     //when
    //     let actualSpreadAtParComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(userOne)
    //             .calculateAtParComponentRecFixed(
    //                 asset,
    //                 iporIndexValue,
    //                 exponentialMovingAverage,
    //                 exponentialWeightedMovingVariance
    //             )
    //     );

    //     const expectedSpreadAtParComponentValue = BigInt("32124352331606218");
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Rec Fixed, EMAi > Ii, KVol denominator == 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const spreadMaxValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(spreadMaxValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKVolValue(BigInt("31000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKHistValue(BigInt("14000000000000000"));

    //     const asset = await testData.tokenDai.address;
    //     const iporIndexValue = BigInt("33000000000000000");
    //     const exponentialMovingAverage = BigInt("40000000000000000");
    //     const exponentialWeightedMovingVariance = USD_1_18DEC;

    //     //when
    //     let actualSpreadAtParComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(userOne)
    //             .calculateAtParComponentRecFixed(
    //                 asset,
    //                 iporIndexValue,
    //                 exponentialMovingAverage,
    //                 exponentialWeightedMovingVariance
    //             )
    //     );

    //     const expectedSpreadAtParComponentValue = spreadMaxValue;
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Rec Fixed, EMAi == Ii, KVol denominator != 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const spreadMaxValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(spreadMaxValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKVolValue(BigInt("31000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKHistValue(BigInt("14000000000000000"));

    //     const asset = await testData.tokenDai.address;
    //     const iporIndexValue = BigInt("33000000000000000");
    //     const exponentialMovingAverage = iporIndexValue;
    //     const exponentialWeightedMovingVariance = BigInt("35000000000000000");

    //     //when
    //     let actualSpreadAtParComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(userOne)
    //             .calculateAtParComponentRecFixed(
    //                 asset,
    //                 iporIndexValue,
    //                 exponentialMovingAverage,
    //                 exponentialWeightedMovingVariance
    //             )
    //     );

    //     const expectedSpreadAtParComponentValue = BigInt("46124352331606218");
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Rec Fixed, EMAi == Ii, KVol denominator == 0", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data,
    //         libraries
    //     );

    //     await grantAllSpreadRolesForDAI(testData, admin, userOne);

    //     const spreadMaxValue = BigInt("300000000000000000");

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadMaxValue(spreadMaxValue);

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKVolValue(BigInt("31000000000000000"));

    //     await testData.iporAssetConfigurationDai
    //         .connect(userOne)
    //         .setSpreadAtParComponentKHistValue(BigInt("14000000000000000"));

    //     const asset = await testData.tokenDai.address;
    //     const iporIndexValue = BigInt("33000000000000000");
    //     const exponentialMovingAverage = iporIndexValue;
    //     const exponentialWeightedMovingVariance = USD_1_18DEC;

    //     //when
    //     let actualSpreadAtParComponentValue = BigInt(
    //         await testData.miltonSpread
    //             .connect(userOne)
    //             .calculateAtParComponentRecFixed(
    //                 asset,
    //                 iporIndexValue,
    //                 exponentialMovingAverage,
    //                 exponentialWeightedMovingVariance
    //             )
    //     );

    //     const expectedSpreadAtParComponentValue = spreadMaxValue;
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread equal max value - Kf denominator != 0, Komega denominator != 0, KVol denominator != 0, KHist denominator != 0", async () => {
    //     //TODO: implement it
    // });

    // it("should calculate spread equal max value - Kf denominator = 0, Komega denominator = 0, KVol denominator != 0, KHist denominator != 0", async () => {
    //     //TODO: implement it
    // });

    // it("should calculate spread equal max value - Kf denominator = 0, Komega denominator = 0, KVol denominator = 0, KHist denominator != 0", async () => {
    //     //TODO: implement it
    // });

    // it("should calculate spread equal max value - Kf denominator = 0, Komega denominator = 0, KVol denominator = 0, KHist denominator = 0", async () => {
    //     //TODO: implement it
    // });

    // it("should calculate spread equal max value - Kf denominator != 0, Komega denominator = 0, KVol denominator = 0, KHist denominator = 0", async () => {
    //     //TODO: implement it
    // });

    // it("should calculate spread equal max value - Kf denominator != 0, Komega denominator != 0, KVol denominator = 0, KHist denominator = 0", async () => {
    //     //TODO: implement it
    // });

    // it("should calculate spread equal max value - Kf denominator != 0, Komega denominator != 0, KVol denominator != 0, KHist denominator = 0", async () => {
    //     //TODO: implement it
    // });

    // it("should calculate spread equal max value - Kf part very high, Komega part normal, KVol part normal, KHist part normal", async () => {
    //     //TODO: implement it
    // });

    // it("should calculate spread equal max value - Kf part normal, Komega part very high, KVol part normal, KHist part normal", async () => {
    //     //TODO: implement it
    // });

    // it("should calculate spread equal max value - Kf part normal, Komega part normal, KVol part very high, KHist part normal", async () => {
    //     //TODO: implement it
    // });

    // it("should calculate spread equal max value - Kf part normal, Komega part normal, KVol part normal, KHist very high", async () => {
    //     //TODO: implement it
    // });

    // it("should calculate spread equal max value - Kf part + Komega part + KVol part + KHist > Spread Max Value", async () => {
    //     //TODO: implement it
    // });

    // it("should calculate spread - Kf part + Komega part + KVol part + KHist < Spread Max Value", async () => {
    //     //TODO: implement it
    // });

	// it("should NOT calculate spread - Liquidity Pool + Opening Fee = 0", async () => {
    //     //TODO: implement it
    // });
});
