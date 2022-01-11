const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");
const { utils } = require("web3");

const {    
    USD_1_18DEC,
    USD_20_18DEC,
    USD_2_000_18DEC,
    USD_10_000_18DEC,    
    USD_14_000_18DEC,    
    ZERO,    
} = require("./Const.js");

const {
    assertError,
    getLibraries,    
    prepareData,
    prepareTestData,    
    grantAllSpreadRoles,
} = require("./Utils");

describe("MiltonSpreadModel - Demand Component", () => {
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
});
