const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");
const { utils } = require("web3");

const {
    USD_20_18DEC,
    USD_1_000_18DEC,
    USD_2_000_18DEC,
    USD_10_000_18DEC,
    USD_14_000_18DEC,
    ZERO,
} = require("./Const.js");

const {
    prepareData,
    prepareMiltonSpreadCase2,
    prepareMiltonSpreadCase3,
    prepareMiltonSpreadCase4,
    prepareMiltonSpreadCase5,
} = require("./Utils");

describe("MiltonSpreadModel - Spread Premium Demand Component", () => {
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

    it("should calculate spread - demand component - Pay Fixed Swap, PayFix Balance > RecFix Balance, SOAP+=0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const liquidityPoolBalance = BigInt("1000000000000000000000000");
        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const payFixedSwapsBalance = BigInt("2000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4222145503127467");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
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
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("1000000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4221122120887343");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
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
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("1000000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("2000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4221122120887343");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
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
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = BigInt("1000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("1000000000000000000000");
        const payFixedSwapsBalance = USD_20_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("300000000000000000");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
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
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("6461082251082251");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
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
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");
        const soap = BigInt("100000000000000000000");

        const expectedSpreadDemandComponentValue = BigInt("6490531792366655");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
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
        const miltonSpread = await prepareMiltonSpreadCase2();
        const spreadPremiumsMaxValue = BigInt("300000000000000000");

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");
        const soap = payFixedSwapsBalance + swapCollateral;

        const expectedSpreadDemandComponentValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
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
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = ZERO;
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("5747162162162162");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateDemandComponentPayFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
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
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = ZERO;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = ZERO;
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("5752372881355932");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateDemandComponentPayFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
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
        const miltonSpread = await prepareMiltonSpreadCase3();
        const spreadPremiumsMaxValue = BigInt("300000000000000000");

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = USD_14_000_18DEC;
        const payFixedSwapsBalance = USD_2_000_18DEC;
        const receiveFixedSwapsBalance = USD_1_000_18DEC;
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = spreadPremiumsMaxValue;
        const expectedAdjustedUtilizationRate = BigInt("855920114122681883");

        let actualAdjustedUtilizationRate = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateAdjustedUtilizationRatePayFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    BigInt("300000000000000000")
                )
        );

        //when
        const actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateDemandComponentPayFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then
        expect(actualAdjustedUtilizationRate).to.be.eq(
            expectedAdjustedUtilizationRate
        );
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, PayFix Balance > RecFix Balance, SOAP+=0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase4();

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("13000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("6940360965820754");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
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
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("5000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("5000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("754210000000000270");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
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
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("3000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("10645643564356436");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
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
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = BigInt("1000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("1000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = USD_20_18DEC;
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("300000000000000000");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
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
        const miltonSpread = await prepareMiltonSpreadCase4();

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("13000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("6940360965820754");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
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
        const miltonSpread = await prepareMiltonSpreadCase4();

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("13000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("100000000000000000000");

        const expectedSpreadDemandComponentValue = BigInt("6969810507105158");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
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
        const miltonSpread = await prepareMiltonSpreadCase2();
        const spreadPremiumsMaxValue = BigInt("300000000000000000");

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("13000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = receiveFixedSwapsBalance + swapCollateral;

        const expectedSpreadDemandComponentValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
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
        const miltonSpread = await prepareMiltonSpreadCase4();

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("13000000000000000000000");
        const receiveFixedSwapsBalance = ZERO;
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("6196303167429811");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
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
        const miltonSpread = await prepareMiltonSpreadCase4();

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = ZERO;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("13000000000000000000000");
        const receiveFixedSwapsBalance = ZERO;
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("6204233107035849");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
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

        const miltonSpread = await prepareMiltonSpreadCase5();
        const spreadPremiumsMaxValue = BigInt("300000000000000000");

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = USD_14_000_18DEC;
        const payFixedSwapsBalance = USD_2_000_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = spreadPremiumsMaxValue;
        const expectedAdjustedUtilizationRate = BigInt("784593437945791726");

        let actualAdjustedUtilizationRate = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateAdjustedUtilizationRateRecFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
                    BigInt("300000000000000000")
                )
        );

        //when
        const actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
                    soap
                )
        );

        //then
        expect(actualAdjustedUtilizationRate).to.be.eq(
            expectedAdjustedUtilizationRate
        );

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });
});
