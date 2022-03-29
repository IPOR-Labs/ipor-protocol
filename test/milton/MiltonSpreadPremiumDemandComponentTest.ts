import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    N1__0_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    N0__1_18DEC,
    USD_1_000_18DEC,
    USD_2_000_18DEC,
    USD_14_000_18DEC,
    USD_20_18DEC,
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
        miltonSpreadModel = await prepareMockMiltonSpreadModel(MiltonSpreadModels.CASE1);
    });

    it("should calculate spread - demand component - Pay Fixed Swap, PayFix Balance > RecFix Balance, SOAP+=0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const liquidityPoolBalance = BigNumber.from("1000000").mul(N1__0_18DEC);
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const payFixedTotalCollateralBalance = BigNumber.from("2000").mul(N1__0_18DEC);
        const receiveFixedTotalCollateralBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("4222145503127467");

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .calculateDemandComponentPayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                payFixedTotalCollateralBalance.add(swapCollateral),
                receiveFixedTotalCollateralBalance,
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
        const payFixedTotalCollateralBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const receiveFixedTotalCollateralBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("4221122120887343");

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .calculateDemandComponentPayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                payFixedTotalCollateralBalance.add(swapCollateral),
                receiveFixedTotalCollateralBalance,
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
        const payFixedTotalCollateralBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const receiveFixedTotalCollateralBalance = BigNumber.from("2000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("4221122120887343");

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .calculateDemandComponentPayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                payFixedTotalCollateralBalance.add(swapCollateral),
                receiveFixedTotalCollateralBalance,
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
        const payFixedTotalCollateralBalance = USD_20_18DEC;
        const receiveFixedTotalCollateralBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("3").mul(N0__1_18DEC);

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .calculateDemandComponentPayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                payFixedTotalCollateralBalance.add(swapCollateral),
                receiveFixedTotalCollateralBalance,
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
        const payFixedTotalCollateralBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const receiveFixedTotalCollateralBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("6461082251082251");

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .calculateDemandComponentPayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                payFixedTotalCollateralBalance.add(swapCollateral),
                receiveFixedTotalCollateralBalance,
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
        const payFixedTotalCollateralBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const receiveFixedTotalCollateralBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const soap = BigNumber.from("100").mul(N1__0_18DEC);

        const expectedSpreadDemandComponentValue = BigNumber.from("6490531792366655");

        //when
        let actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .calculateDemandComponentPayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                payFixedTotalCollateralBalance.add(swapCollateral),
                receiveFixedTotalCollateralBalance,
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
        const payFixedTotalCollateralBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const receiveFixedTotalCollateralBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const soap = payFixedTotalCollateralBalance.add(swapCollateral);

        const expectedSpreadDemandComponentValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadDemandComponentValue = await miltonSpread
            .connect(liquidityProvider)
            .calculateDemandComponentPayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                payFixedTotalCollateralBalance.add(swapCollateral),
                receiveFixedTotalCollateralBalance,
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
        const payFixedTotalCollateralBalance = ZERO;
        const receiveFixedTotalCollateralBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("5747162162162162");

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(userOne)
            .calculateDemandComponentPayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                payFixedTotalCollateralBalance.add(swapCollateral),
                receiveFixedTotalCollateralBalance,
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
        const payFixedTotalCollateralBalance = ZERO;
        const receiveFixedTotalCollateralBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("5752372881355932");

        //when
        const actualSpreadDemandComponentValue = await miltonSpread
            .connect(userOne)
            .calculateDemandComponentPayFixed(
                liquidityPoolBalance.add(swapOpeningFee),
                payFixedTotalCollateralBalance.add(swapCollateral),
                receiveFixedTotalCollateralBalance,
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
        const payFixedTotalCollateralBalance = USD_2_000_18DEC;
        const receiveFixedTotalCollateralBalance = USD_1_000_18DEC;
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = spreadPremiumsMaxValue;
        const expectedAdjustedUtilizationRate = BigNumber.from("855920114122681883");

        const actualAdjustedUtilizationRate = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateAdjustedUtilizationRatePayFixed(
                    liquidityPoolBalance.add(swapOpeningFee),
                    payFixedTotalCollateralBalance.add(swapCollateral),
                    receiveFixedTotalCollateralBalance,
                    BigNumber.from("3").mul(N0__1_18DEC)
                )
        );

        //when
        const actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateDemandComponentPayFixed(
                    liquidityPoolBalance.add(swapOpeningFee),
                    payFixedTotalCollateralBalance.add(swapCollateral),
                    receiveFixedTotalCollateralBalance,
                    soap
                )
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
        const payFixedTotalCollateralBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const receiveFixedTotalCollateralBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("6940360965820754");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance.add(swapOpeningFee),
                    payFixedTotalCollateralBalance,
                    receiveFixedTotalCollateralBalance.add(swapCollateral),
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

        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const payFixedTotalCollateralBalance = BigNumber.from("5000").mul(N1__0_18DEC);
        const receiveFixedTotalCollateralBalance = BigNumber.from("5000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("754210000000000270");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance.add(swapOpeningFee),
                    payFixedTotalCollateralBalance,
                    receiveFixedTotalCollateralBalance.add(swapCollateral),
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

        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const payFixedTotalCollateralBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const receiveFixedTotalCollateralBalance = BigNumber.from("3000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("10645643564356436");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance.add(swapOpeningFee),
                    payFixedTotalCollateralBalance,
                    receiveFixedTotalCollateralBalance.add(swapCollateral),
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

        const swapCollateral = BigNumber.from("1000").mul(N1__0_18DEC);
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const payFixedTotalCollateralBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const receiveFixedTotalCollateralBalance = USD_20_18DEC;
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("3").mul(N0__1_18DEC);

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance.add(swapOpeningFee),
                    payFixedTotalCollateralBalance,
                    receiveFixedTotalCollateralBalance.add(swapCollateral),
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

        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const payFixedTotalCollateralBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const receiveFixedTotalCollateralBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("6940360965820754");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance.add(swapOpeningFee),
                    payFixedTotalCollateralBalance,
                    receiveFixedTotalCollateralBalance.add(swapCollateral),
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

        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const payFixedTotalCollateralBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const receiveFixedTotalCollateralBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const soap = BigNumber.from("100").mul(N1__0_18DEC);

        const expectedSpreadDemandComponentValue = BigNumber.from("6969810507105158");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance.add(swapOpeningFee),
                    payFixedTotalCollateralBalance,
                    receiveFixedTotalCollateralBalance.add(swapCollateral),
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
        const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const payFixedTotalCollateralBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const receiveFixedTotalCollateralBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const soap = receiveFixedTotalCollateralBalance.add(swapCollateral);

        const expectedSpreadDemandComponentValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance.add(swapOpeningFee),
                    payFixedTotalCollateralBalance,
                    receiveFixedTotalCollateralBalance.add(swapCollateral),
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

        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const payFixedTotalCollateralBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const receiveFixedTotalCollateralBalance = ZERO;
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("6196303167429811");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance.add(swapOpeningFee),
                    payFixedTotalCollateralBalance,
                    receiveFixedTotalCollateralBalance.add(swapCollateral),
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

        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = ZERO;
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const payFixedTotalCollateralBalance = BigNumber.from("13000").mul(N1__0_18DEC);
        const receiveFixedTotalCollateralBalance = ZERO;
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigNumber.from("6204233107035849");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance.add(swapOpeningFee),
                    payFixedTotalCollateralBalance,
                    receiveFixedTotalCollateralBalance.add(swapCollateral),
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
        const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = USD_14_000_18DEC;
        const payFixedTotalCollateralBalance = USD_2_000_18DEC;
        const receiveFixedTotalCollateralBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const soap = BigNumber.from("-1234560000000000000");

        const expectedSpreadDemandComponentValue = spreadPremiumsMaxValue;
        const expectedAdjustedUtilizationRate = BigNumber.from("784593437945791726");

        let actualAdjustedUtilizationRate = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateAdjustedUtilizationRateRecFixed(
                    liquidityPoolBalance.add(swapOpeningFee),
                    payFixedTotalCollateralBalance,
                    receiveFixedTotalCollateralBalance.add(swapCollateral),
                    BigNumber.from("3").mul(N0__1_18DEC)
                )
        );

        //when
        const actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateDemandComponentRecFixed(
                    liquidityPoolBalance.add(swapOpeningFee),
                    payFixedTotalCollateralBalance,
                    receiveFixedTotalCollateralBalance.add(swapCollateral),
                    soap
                )
        );

        //then
        expect(actualAdjustedUtilizationRate).to.be.eq(expectedAdjustedUtilizationRate);

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });
});
