import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { assertError } from "../utils/AssertUtils";
import {
    N1__0_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    N0__1_18DEC,
    N0__01_18DEC,
    N0__001_18DEC,
    USD_1_000_18DEC,
    USD_2_000_18DEC,
    USD_14_000_18DEC,
    USD_20_18DEC,
    USD_13_000_18DEC,
    ZERO,
} from "../utils/Constants";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    prepareMockMiltonSpreadModel,
    prepareMiltonSpreadCase2,
    prepareMiltonSpreadCase3,
    prepareMiltonSpreadCase4,
    prepareMiltonSpreadCase5,
    prepareMiltonSpreadCase6,
} from "../utils/MiltonUtils";

const { expect } = chai;

describe("MiltonSpreadModel - Spread Premium Demand Component", () => {
    let miltonSpreadModel: MockMiltonSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer,
        miltonStorageAddress: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress] =
            await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockMiltonSpreadModel(MiltonSpreadModels.BASE);
    });

    it("should NOT calculate Spread Premiums Rec Fixed - Liquidity Pool + Opening Fee = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();

        const liquidityPoolBalance = ZERO;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = ZERO;

        const totalCollateralPayFixedBalance = USD_13_000_18DEC;
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);

        const soap = BigNumber.from("500").mul(N1__0_18DEC);

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: BigNumber.from("1").mul(N1__0_18DEC),
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };
        //when
        await assertError(
            //when
            miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance,
                    totalCollateralReceiveFixedBalance.add(swapCollateral)
                ),
            //then
            "IPOR_320"
        );
    });

    it("should calculate spread - demand component - Pay Fixed Swap, PayFix Balance > RecFix Balance, SOAP+=0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const liquidityPoolBalance = BigNumber.from("1000000").mul(N1__0_18DEC);
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const totalCollateralPayFixedBalance = BigNumber.from("2000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("4222145503127467");

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateDemandComponentPayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance.add(swapCollateral),
                totalCollateralReceiveFixedBalance,
                soap
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

        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("1000000").mul(N1__0_18DEC);
        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("4221122120887343");

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateDemandComponentPayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance.add(swapCollateral),
                totalCollateralReceiveFixedBalance,
                soap
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

        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("1000000").mul(N1__0_18DEC);
        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("2000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("4221122120887343");

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateDemandComponentPayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance.add(swapCollateral),
                totalCollateralReceiveFixedBalance,
                soap
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

        const swapCollateral = BigNumber.from("1000").mul(N1__0_18DEC);
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralPayFixedBalance = USD_20_18DEC;
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("3").mul(N0__1_18DEC);

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateDemandComponentPayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance.add(swapCollateral),
                totalCollateralReceiveFixedBalance,
                soap
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

        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("6461082251082251");

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateDemandComponentPayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance.add(swapCollateral),
                totalCollateralReceiveFixedBalance,
                soap
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

        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const soap = BigNumber.from("100").mul(N1__0_18DEC);

        const expectedSpreadDemandComponentValue = BigNumber.from("6490531792366655");

        //when
        let actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateDemandComponentPayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance.add(swapCollateral),
                totalCollateralReceiveFixedBalance,
                soap
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
        const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const soap = totalCollateralPayFixedBalance.add(swapCollateral);

        const expectedSpreadDemandComponentValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateDemandComponentPayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance.add(swapCollateral),
                totalCollateralReceiveFixedBalance,
                soap
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

        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const totalCollateralPayFixedBalance = ZERO;
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("5747162162162162");

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(userOne)
            .testCalculateDemandComponentPayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance.add(swapCollateral),
                totalCollateralReceiveFixedBalance,
                soap
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

        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = ZERO;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const totalCollateralPayFixedBalance = ZERO;
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("5752372881355932");

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(userOne)
            .testCalculateDemandComponentPayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance.add(swapCollateral),
                totalCollateralReceiveFixedBalance,
                soap
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
        const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = USD_14_000_18DEC;
        const totalCollateralPayFixedBalance = USD_2_000_18DEC;
        const totalCollateralReceiveFixedBalance = USD_1_000_18DEC;
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = spreadPremiumsMaxValue;
        const expectedAdjustedUtilizationRate = BigNumber.from("855920114122681883");

        const actualAdjustedUtilizationRate = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateAdjustedUtilizationRatePayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance.add(swapCollateral),
                totalCollateralReceiveFixedBalance,
                BigNumber.from("3").mul(N0__1_18DEC)
            );

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(userOne)
            .testCalculateDemandComponentPayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance.add(swapCollateral),
                totalCollateralReceiveFixedBalance,
                soap
            );

        //then
        expect(actualAdjustedUtilizationRate).to.be.eq(expectedAdjustedUtilizationRate);
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, PayFix Balance > RecFix Balance, SOAP+=0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase4();

        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const totalCollateralPayFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("6940360965820754");

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateDemandComponentRecFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance,
                totalCollateralReceiveFixedBalance.add(swapCollateral),
                soap
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

        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const totalCollateralPayFixedBalance = BigNumber.from("5000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("5000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("754210000000000270");

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateDemandComponentRecFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance,
                totalCollateralReceiveFixedBalance.add(swapCollateral),
                soap
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

        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("3000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("10645643564356436");

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateDemandComponentRecFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance,
                totalCollateralReceiveFixedBalance.add(swapCollateral),
                soap
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

        const swapCollateral = BigNumber.from("1000").mul(N1__0_18DEC);
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = USD_20_18DEC;
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("3").mul(N0__1_18DEC);

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateDemandComponentRecFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance,
                totalCollateralReceiveFixedBalance.add(swapCollateral),
                soap
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

        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const totalCollateralPayFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("6940360965820754");

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateDemandComponentRecFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance,
                totalCollateralReceiveFixedBalance.add(swapCollateral),
                soap
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

        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const totalCollateralPayFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const soap = BigNumber.from("100").mul(N1__0_18DEC);

        const expectedSpreadDemandComponentValue = BigNumber.from("6969810507105158");

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateDemandComponentRecFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance,
                totalCollateralReceiveFixedBalance.add(swapCollateral),
                soap
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
        const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const totalCollateralPayFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const soap = totalCollateralReceiveFixedBalance.add(swapCollateral);

        const expectedSpreadDemandComponentValue = spreadPremiumsMaxValue;

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateDemandComponentRecFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance,
                totalCollateralReceiveFixedBalance.add(swapCollateral),
                soap
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

        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const totalCollateralPayFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = ZERO;
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("6196303167429811");

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateDemandComponentRecFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance,
                totalCollateralReceiveFixedBalance.add(swapCollateral),
                soap
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

        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = ZERO;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const totalCollateralPayFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = ZERO;
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("6204233107035849");

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateDemandComponentRecFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance,
                totalCollateralReceiveFixedBalance.add(swapCollateral),
                soap
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
        const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = USD_14_000_18DEC;
        const totalCollateralPayFixedBalance = USD_2_000_18DEC;
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = spreadPremiumsMaxValue;
        const expectedAdjustedUtilizationRate = BigNumber.from("784593437945791726");

        const actualAdjustedUtilizationRate = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateAdjustedUtilizationRateRecFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance,
                totalCollateralReceiveFixedBalance.add(swapCollateral),
                BigNumber.from("3").mul(N0__1_18DEC)
            );

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(userOne)
            .testCalculateDemandComponentRecFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                totalCollateralPayFixedBalance,
                totalCollateralReceiveFixedBalance.add(swapCollateral),
                soap
            );

        //then
        expect(actualAdjustedUtilizationRate).to.be.eq(expectedAdjustedUtilizationRate);

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });
});
