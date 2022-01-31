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

    it("should calculate spread - demand component - Pay Fixed Swap, PayFix Balance > RecFix Balance, SOAP+=0", async () => {
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

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("1000000000000000000000000");
        const payFixedSwapsBalance = BigInt("2000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("86545000000000000");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Swap, PayFix Balance = RecFix Balance, SOAP+=0", async () => {
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

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("1000000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("94120909090909091");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Swap, PayFix Balance < RecFix Balance, SOAP+=0", async () => {
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

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("1000000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("2000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("94120909090909091");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Swap, 100% utilization rate including position, SOAP+=0 ", async () => {
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

        const swapCollateral = BigInt("1000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("1000000000000000000000");
        const payFixedSwapsBalance = USD_20_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4210000000000000");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Swap, imbalance factor > 0, opening fee > 0, pay fixed swap balance > 0, SOAP+=0", async () => {
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

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4654230769230769");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Swap, imbalance factor > 0, opening fee > 0, pay fixed swap balance > 0, SOAP+>0", async () => {
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

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");
        const soap = BigInt("100000000000000000000");

        const expectedSpreadDemandComponentValue = BigInt("5010897435897436");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Swap, imbalance factor > 0, opening fee > 0, pay fixed swap balance > 0, SOAP+=1", async () => {
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
        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");
        const soap = payFixedSwapsBalance;

        const expectedSpreadDemandComponentValue = spreadMaxValue;

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Swap, imbalance factor > 0, opening fee > 0, pay fixed swap balance = 0, SOAP+=0", async () => {
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

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = ZERO;
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4860549450549451");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Swap, imbalance factor > 0, opening fee = 0, pay fixed swap balance = 0, SOAP+=0", async () => {
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

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = ZERO;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = ZERO;
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4858351648351648");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Swap, Adjusted Utilization Rate equal M , Kf denominator = 0, SOAP+=0", async () => {
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

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = USD_14_000_18DEC;
        const payFixedSwapsBalance = USD_2_000_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = spreadMaxValue;

        //when
        const actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, PayFix Balance > RecFix Balance, SOAP+=0", async () => {
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

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("13000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4576251939768483");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, PayFix Balance = RecFix Balance, SOAP+=0", async () => {
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

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("5000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("5000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4211333333333333");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, PayFix Balance < RecFix Balance, SOAP+=0", async () => {
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

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("3000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4365384615384615");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, 100% utilization rate including position, SOAP+=0 ", async () => {
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

        const swapCollateral = BigInt("1000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("1000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = USD_20_18DEC;
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4210000000000000");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, imbalance factor > 0, opening fee > 0, rec fixed swap balance > 0, SOAP+=0 ", async () => {
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

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("13000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4576251939768483");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, imbalance factor > 0, opening fee > 0, rec fixed swap balance > 0, SOAP+>0 ", async () => {
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

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("13000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("100000000000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4932918606435150");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, imbalance factor > 0, opening fee > 0, rec fixed swap balance > 0, SOAP+=1 ", async () => {
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

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("13000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = receiveFixedSwapsBalance;

        const expectedSpreadDemandComponentValue = spreadMaxValue;

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, imbalance factor > 0, opening fee > 0, rec fixed swap balance = 0, SOAP+=0", async () => {
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

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("13000000000000000000000");
        const receiveFixedSwapsBalance = ZERO;
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4713447820250902");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, imbalance factor > 0, opening fee = 0, rec fixed swap balance = 0, SOAP+=0", async () => {
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

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = ZERO;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("13000000000000000000000");
        const receiveFixedSwapsBalance = ZERO;
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4711445892394376");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, Adjusted Utilization Rate equal M , Kf denominator = 0, KOmega denominator != 0, SOAP+=0 ", async () => {
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

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = USD_14_000_18DEC;
        const payFixedSwapsBalance = USD_2_000_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = spreadMaxValue;

        //when
        const actualSpreadDemandComponentValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    swapOpeningFee,
                    liquidityPoolBalance,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance,
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
