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
    grantAllSpreadRoles,
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
        await grantAllSpreadRoles(data, admin, userOne);
    });

    it("should calculate spread - demand component - Pay Fixed Derivative, PayFix Balance > RecFix Balance, SOAP+=0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        const derivativeDeposit = USD_10_000_18DEC;
        const derivativeOpeningFee = USD_20_18DEC;
        const liquidityPool = BigInt("1000000000000000000000000");
        const payFixedDerivativesBalance = BigInt("2000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("86545000000000000");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Derivative, PayFix Balance = RecFix Balance, SOAP+=0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        const derivativeDeposit = USD_10_000_18DEC;
        const derivativeOpeningFee = USD_20_18DEC;
        const liquidityPool = BigInt("1000000000000000000000000");
        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("94120909090909091");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Derivative, PayFix Balance < RecFix Balance, SOAP+=0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        const derivativeDeposit = USD_10_000_18DEC;
        const derivativeOpeningFee = USD_20_18DEC;
        const liquidityPool = BigInt("1000000000000000000000000");
        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("2000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("94120909090909091");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Derivative, 100% utilization rate including position, SOAP+=0 ", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        const derivativeDeposit = BigInt("1000000000000000000000");
        const derivativeOpeningFee = USD_20_18DEC;
        const liquidityPool = BigInt("1000000000000000000000");
        const payFixedDerivativesBalance = USD_20_18DEC;
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4210000000000000");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Derivative, imbalance factor > 0, opening fee > 0, pay fixed derivative balance > 0, SOAP+=0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = USD_20_18DEC;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4654230769230769");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Derivative, imbalance factor > 0, opening fee > 0, pay fixed derivative balance > 0, SOAP+>0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = USD_20_18DEC;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");
        const soap = BigInt("100000000000000000000");

        const expectedSpreadDemandComponentValue = BigInt("5010897435897436");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Derivative, imbalance factor > 0, opening fee > 0, pay fixed derivative balance > 0, SOAP+=1", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = USD_20_18DEC;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");
        const soap = payFixedDerivativesBalance;

        const expectedSpreadDemandComponentValue = spreadMaxValue;

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Derivative, imbalance factor > 0, opening fee > 0, pay fixed derivative balance = 0, SOAP+=0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = USD_20_18DEC;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = ZERO;
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4860549450549451");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateDemandComponentPayFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Derivative, imbalance factor > 0, opening fee = 0, pay fixed derivative balance = 0, SOAP+=0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = ZERO;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = ZERO;
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4858351648351648");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateDemandComponentPayFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Derivative, Adjusted Utilization Rate equal M , Kf denominator = 0, SOAP+=0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("3210000000000000"));

        //Max Liquidity Redemption Value equal to Adjusted Utilization Rate
        const maxLiquidityRedemptionValue = BigInt("144079885877318117");
        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                maxLiquidityRedemptionValue
            );

        const derivativeDeposit = USD_10_000_18DEC;
        const derivativeOpeningFee = USD_20_18DEC;
        const liquidityPool = USD_14_000_18DEC;
        const payFixedDerivativesBalance = USD_2_000_18DEC;
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = spreadMaxValue;

        //when
        const actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateDemandComponentPayFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Derivative, PayFix Balance > RecFix Balance, SOAP+=0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        const derivativeDeposit = USD_10_000_18DEC;
        const derivativeOpeningFee = USD_20_18DEC;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4576251939768483");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Derivative, PayFix Balance = RecFix Balance, SOAP+=0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        const derivativeDeposit = USD_10_000_18DEC;
        const derivativeOpeningFee = USD_20_18DEC;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = BigInt("5000000000000000000000");
        const recFixedDerivativesBalance = BigInt("5000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4211333333333333");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Derivative, PayFix Balance < RecFix Balance, SOAP+=0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        const derivativeDeposit = USD_10_000_18DEC;
        const derivativeOpeningFee = USD_20_18DEC;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("3000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4365384615384615");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Derivative, 100% utilization rate including position, SOAP+=0 ", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        const derivativeDeposit = BigInt("1000000000000000000000");
        const derivativeOpeningFee = USD_20_18DEC;
        const liquidityPool = BigInt("1000000000000000000000");
        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = USD_20_18DEC;
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4210000000000000");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Derivative, imbalance factor > 0, opening fee > 0, rec fixed derivative balance > 0, SOAP+=0 ", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = USD_20_18DEC;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4576251939768483");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Derivative, imbalance factor > 0, opening fee > 0, rec fixed derivative balance > 0, SOAP+>0 ", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = USD_20_18DEC;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");
        const soap = BigInt("100000000000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4932918606435150");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Derivative, imbalance factor > 0, opening fee > 0, rec fixed derivative balance > 0, SOAP+=1 ", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = USD_20_18DEC;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");
        const soap = recFixedDerivativesBalance;

        const expectedSpreadDemandComponentValue = spreadMaxValue;

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Derivative, imbalance factor > 0, opening fee > 0, rec fixed derivative balance = 0, SOAP+=0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = USD_20_18DEC;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = ZERO;
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4713447820250902");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Derivative, imbalance factor > 0, opening fee = 0, rec fixed derivative balance = 0, SOAP+=0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("3210000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = ZERO;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = ZERO;
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4711445892394376");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Derivative, Adjusted Utilization Rate equal M , Kf denominator = 0, KOmega denominator != 0, SOAP+=0 ", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        //Max Liquidity Redemption Value equal to Adjusted Utilization Rate value=215406562054208274
        const maxLiquidityRedemptionValue = BigInt("215406562054208274");
        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                maxLiquidityRedemptionValue
            );

        const derivativeDeposit = USD_10_000_18DEC;
        const derivativeOpeningFee = USD_20_18DEC;
        const liquidityPool = USD_14_000_18DEC;
        const payFixedDerivativesBalance = USD_2_000_18DEC;
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = spreadMaxValue;

        //when
        const actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateDemandComponentRecFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - at par component - Pay Fixed, EMAi > Ii, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateAtParComponentPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = BigInt("46265766473020359");
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Pay Fixed, EMAi > Ii, KVol denominator != 0, KHist denominator == 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const maxSpreadValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(maxSpreadValue);

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const iporIndexValue = BigInt("50000000000000000");
        const exponentialMovingAverage = BigInt("1050000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateAtParComponentPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = maxSpreadValue;

        //then
        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Pay Fixed, EMAi > Ii, KVol denominator == 0, KHist denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const maxSpreadValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(maxSpreadValue);

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = USD_1_18DEC;

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateAtParComponentPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = maxSpreadValue;

        //then
        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Pay Fixed, EMAi > Ii, KVol denominator == 0, KHist denominator == 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const maxSpreadValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(maxSpreadValue);

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const iporIndexValue = BigInt("50000000000000000");
        const exponentialMovingAverage = BigInt("1050000000000000000");
        const exponentialWeightedMovingVariance = USD_1_18DEC;

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateAtParComponentPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = maxSpreadValue;

        //then
        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Pay Fixed, EMAi < Ii, KVol denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const iporIndexValue = BigInt("60000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateAtParComponentPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = BigInt("32124352331606218");
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Pay Fixed, EMAi < Ii, KVol denominator == 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const iporIndexValue = BigInt("60000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = USD_1_18DEC;

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateAtParComponentPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = spreadMaxValue;
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Pay Fixed, EMAi == Ii, KVol denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const iporIndexValue = BigInt("60000000000000000");
        const exponentialMovingAverage = iporIndexValue;
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateAtParComponentPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = BigInt("46124352331606218");
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Pay Fixed, EMAi == Ii, KVol denominator == 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const iporIndexValue = BigInt("60000000000000000");
        const exponentialMovingAverage = iporIndexValue;
        const exponentialWeightedMovingVariance = USD_1_18DEC;

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateAtParComponentPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = spreadMaxValue;
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Rec Fixed, EMAi < Ii, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const iporIndexValue = BigInt("60000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateAtParComponentRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = BigInt("46410066617320504");
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Rec Fixed, EMAi < Ii, KVol denominator != 0, KHist denominator == 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const iporIndexValue = BigInt("1050000000000000000");
        const exponentialMovingAverage = BigInt("50000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateAtParComponentRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = spreadMaxValue;
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Rec Fixed, EMAi < Ii, KVol denominator == 0, KHist denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const iporIndexValue = BigInt("60000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = USD_1_18DEC;

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateAtParComponentRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = spreadMaxValue;
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Rec Fixed, EMAi < Ii, KVol denominator == 0, KHist denominator == 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const iporIndexValue = BigInt("1050000000000000000");
        const exponentialMovingAverage = BigInt("50000000000000000");
        const exponentialWeightedMovingVariance = USD_1_18DEC;

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateAtParComponentRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = spreadMaxValue;
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Rec Fixed, EMAi > Ii, KVol denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const iporIndexValue = BigInt("33000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateAtParComponentRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = BigInt("32124352331606218");
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Rec Fixed, EMAi > Ii, KVol denominator == 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const iporIndexValue = BigInt("33000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = USD_1_18DEC;

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateAtParComponentRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = spreadMaxValue;
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Rec Fixed, EMAi == Ii, KVol denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const iporIndexValue = BigInt("33000000000000000");
        const exponentialMovingAverage = iporIndexValue;
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateAtParComponentRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = BigInt("46124352331606218");
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Rec Fixed, EMAi == Ii, KVol denominator == 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const iporIndexValue = BigInt("33000000000000000");
        const exponentialMovingAverage = iporIndexValue;
        const exponentialWeightedMovingVariance = USD_1_18DEC;

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateAtParComponentRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = spreadMaxValue;
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate Spread Pay Fixed Value - Kf part + KOmega part + KVol part + KHist < Spread Max Value", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("30000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = BigInt("107709997242251128");

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate spread Rec Fixed - Kf part + Komega part + KVol part + KHist < Spread Max Value", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("30000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("30000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = BigInt("93497295658845706");

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Rec Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf denominator = 0, Komega denominator != 0, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("307589880159786950")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Rec Fixed = Spread Max Value - Kf denominator = 0, Komega denominator != 0, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("307589880159786950")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("307589880159786950")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = payFixedDerivativesBalance;

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Rec Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("307589880159786950")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");

        const soap = recFixedDerivativesBalance;

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator = 0, KHist denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("307589880159786950")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = payFixedDerivativesBalance;

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("1000000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Rec Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator = 0, KHist denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("307589880159786950")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");

        const soap = recFixedDerivativesBalance;

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("1000000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("307589880159786950")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = payFixedDerivativesBalance;

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage =
            BigInt("1000000000000000000") + iporIndexValue;
        const exponentialWeightedMovingVariance = BigInt("1000000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Rec Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("307589880159786950")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");

        const soap = recFixedDerivativesBalance;

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage =
            BigInt("1000000000000000000") + iporIndexValue;
        const exponentialWeightedMovingVariance = BigInt("1000000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf denominator != 0, Komega denominator = 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = payFixedDerivativesBalance;

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage =
            BigInt("1000000000000000000") + iporIndexValue;
        const exponentialWeightedMovingVariance = BigInt("1000000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Rec Fixed = Spread Max Value - Kf denominator != 0, Komega denominator = 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");

        const soap = recFixedDerivativesBalance;

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage =
            BigInt("1000000000000000000") + iporIndexValue;
        const exponentialWeightedMovingVariance = BigInt("1000000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage =
            BigInt("1000000000000000000") + iporIndexValue;
        const exponentialWeightedMovingVariance = BigInt("1000000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Rec Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage =
            BigInt("1000000000000000000") + iporIndexValue;
        const exponentialWeightedMovingVariance = BigInt("1000000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator != 0, KHist denominator = 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage =
            BigInt("1000000000000000000") + iporIndexValue;
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Rec Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator != 0, KHist denominator = 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage =
            BigInt("1000000000000000000") + iporIndexValue;
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf part very high, Komega part normal, KVol part normal, KHist part normal", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("0"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("30000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("100000000000000001500");
        const derivativeDeposit = BigInt("1000");
        const derivativeOpeningFee = BigInt("0");

        const payFixedDerivativesBalance = BigInt("1000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("100");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                // .callStatic
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Rec Fixed = Spread Max Value - Kf part very high, KOmega part normal, KVol part normal, KHist part normal", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("0"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("30000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("100000000000000001500");
        const derivativeDeposit = BigInt("10000");
        const derivativeOpeningFee = BigInt("0");

        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000");

        const soap = BigInt("100");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf part normal, KOmega part very high, KVol part normal, KHist part normal", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("30000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("999999999999999999000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Rec Fixed = Spread Max Value - Kf part normal, KOmega part very high, KVol part normal, KHist part normal", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("30000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");

        const soap = BigInt("999999999999999999000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf part normal, KOmega part normal, KVol part very high, KHist part normal", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("30000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("999999999999999899");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Rec Fixed = Spread Max Value - Kf part normal, KOmega part normal, KVol part very high, KHist part normal", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("30000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");

        const exponentialWeightedMovingVariance = BigInt("999999999999999899");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf part normal, KOmega part normal, KVol part normal, KHist very high", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("30000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("2000000000000000010");
        const exponentialMovingAverage = BigInt("3000000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Rec Fixed = Spread Max Value - Kf part normal, KOmega part normal, KVol part normal, KHist very high", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("30000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("3000000000000000000");
        const exponentialMovingAverage = BigInt("2000000000000000010");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed Value - Kf part + KOmega part + KVol part + KHist > Spread Max Value", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000009000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate spread Rec Fixed - Kf part + Komega part + KVol part + KHist > Spread Max Value", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000600000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should NOT calculate Spread Pay Fixed - Liquidity Pool + Opening Fee = 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("30000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("0");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("0");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        await assertError(
            //when
            data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                ),
            //then
            "IPOR_49"
        );
    });

    it("should NOT calculate Spread Rec Fixed - Liquidity Pool + Opening Fee = 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("30000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("0");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("0");

        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        //when
        await assertError(
            //when
            data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                ),
            //then
            "IPOR_49"
        );
    });
});
