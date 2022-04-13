import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    N0__01_18DEC,
    ZERO,
    YEAR_IN_SECONDS,
    PERIOD_25_DAYS_IN_SECONDS,
    N1__0_18DEC,
} from "./utils/Constants";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    prepareMockMiltonSpreadModel,
    prepareMiltonSpreadBase,
} from "./utils/MiltonUtils";
import {
    prepareSoapIndicatorPayFixedCaseD18,
    prepareInitialDefaultSoapIndicator,
} from "./utils/DataUtils";
import { assertError, SoapIndicatorsMemory, assertSoapIndicator } from "./utils/AssertUtils";
import { MockSoapIndicatorLogic } from "../types";

const { expect } = chai;

describe("SoapIndicatorLogic", () => {
    let mockSoapIndicatorLogic: MockSoapIndicatorLogic;

    before(async () => {
        const MockSoapIndicatorLogic = await hre.ethers.getContractFactory(
            "MockSoapIndicatorLogic"
        );
        mockSoapIndicatorLogic = (await MockSoapIndicatorLogic.deploy()) as MockSoapIndicatorLogic;
    });

    it("should calculate interest rate when open position - simple case - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareSoapIndicatorPayFixedCaseD18();
        const derivativeNotional = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapFixedInterestRate = BigNumber.from("4").mul(N0__01_18DEC);
        //when

        const actualInterestRate =
            await mockSoapIndicatorLogic.calculateAverageInterestRateWhenOpenSwap(
                soapIndicator.totalNotional,
                soapIndicator.averageInterestRate,
                derivativeNotional,
                swapFixedInterestRate
            );

        //then
        const expectedInterestRate = BigNumber.from("66666666666666666");
        expect(expectedInterestRate, "Wrong interest rate when open position").to.be.eq(
            actualInterestRate
        );
    });

    it("should calculate interest rate when close position - simple case - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareSoapIndicatorPayFixedCaseD18();
        const derivativeNotional = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapFixedInterestRate = BigNumber.from("4").mul(N0__01_18DEC);

        //when

        const actualInterestRate =
            await mockSoapIndicatorLogic.calculateAverageInterestRateWhenCloseSwap(
                soapIndicator.totalNotional,
                soapIndicator.averageInterestRate,
                derivativeNotional,
                swapFixedInterestRate
            );

        //then
        const expectedInterestRate = BigNumber.from("12").mul(N0__01_18DEC);
        expect(
            expectedInterestRate,
            "Wrong hypothetical interest rate when close position"
        ).to.be.eq(actualInterestRate);
    });

    it("should calculate interest rate when close position - notional too high - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareSoapIndicatorPayFixedCaseD18();
        const derivativeNotional = BigNumber.from(40000).mul(N1__0_18DEC);
        const swapFixedInterestRate = BigNumber.from("4").mul(N0__01_18DEC);

        //when
        await assertError(
            //when
            mockSoapIndicatorLogic.calculateAverageInterestRateWhenCloseSwap(
                soapIndicator.totalNotional,
                soapIndicator.averageInterestRate,
                derivativeNotional,
                swapFixedInterestRate
            ),
            //then
            "IPOR_313"
        );
    });

    it("should calculate interest delta - simple case 1 - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareSoapIndicatorPayFixedCaseD18();
        const timestamp = soapIndicator.rebalanceTimestamp.add(
            BigNumber.from(PERIOD_25_DAYS_IN_SECONDS)
        );

        //when

        const actualQuasiInterestRate =
            await mockSoapIndicatorLogic.calculateQuasiHypotheticalInterestDelta(
                timestamp,
                soapIndicator.rebalanceTimestamp,
                soapIndicator.totalNotional,
                soapIndicator.averageInterestRate
            );

        //then
        const expectedQuasiInterestDelta = BigNumber.from("3456000000")
            .mul(N1__0_18DEC)
            .mul(N1__0_18DEC)
            .mul(N1__0_18DEC);
        expect(expectedQuasiInterestDelta, "Incorrect quasi interest in delta time").to.be.eq(
            actualQuasiInterestRate
        );
    });

    it("should calculate hypothetical interest delta - simple case 1 - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareSoapIndicatorPayFixedCaseD18();
        const timestamp = soapIndicator.rebalanceTimestamp.add(
            BigNumber.from(PERIOD_25_DAYS_IN_SECONDS)
        );

        //when

        const actualQuasiHypotheticalInterestTotal =
            await mockSoapIndicatorLogic.calculateQuasiHyphoteticalInterestTotal(
                soapIndicator,
                timestamp
            );

        //then
        const expectedQuasiHypotheticalInterestTotal = BigNumber.from("19224000000")
            .mul(N1__0_18DEC)
            .mul(N1__0_18DEC)
            .mul(N1__0_18DEC);
        expect(
            expectedQuasiHypotheticalInterestTotal,
            "Incorrect hypothetical interest total quasi"
        ).to.be.eq(actualQuasiHypotheticalInterestTotal);
    });

    it("should rebalance SOAP Indicators when open position - one rebalance - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareInitialDefaultSoapIndicator(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            0
        );
        const rebalanceTimestamp = soapIndicator.rebalanceTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotional = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapFixedInterestRate = BigNumber.from(5).mul(N0__01_18DEC);
        const derivativeIbtQuantity = BigNumber.from(95).mul(N1__0_18DEC);

        //when
        const actualSoapIndicator = (await mockSoapIndicatorLogic.rebalanceWhenOpenSwap(
            soapIndicator,
            rebalanceTimestamp,
            derivativeNotional,
            swapFixedInterestRate,
            derivativeIbtQuantity
        )) as SoapIndicatorsMemory;

        //then
        await assertSoapIndicator(
            actualSoapIndicator,
            rebalanceTimestamp,
            derivativeNotional,
            derivativeIbtQuantity,
            swapFixedInterestRate,
            ZERO
        );
    });

    it("should rebalance SOAP Indicators when open position - two rebalances - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareInitialDefaultSoapIndicator(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            0
        );

        const rebalanceTimestamp = soapIndicator.rebalanceTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotional = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapFixedInterestRate = BigNumber.from("5").mul(N0__01_18DEC);
        const derivativeIbtQuantity = BigNumber.from("95").mul(N1__0_18DEC);

        const actualSoapIndicatorFirst = await mockSoapIndicatorLogic.rebalanceWhenOpenSwap(
            soapIndicator,
            rebalanceTimestamp,
            derivativeNotional,
            swapFixedInterestRate,
            derivativeIbtQuantity
        );

        const rebalanceTimestampSecond =
            actualSoapIndicatorFirst.rebalanceTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        const derivativeNotionalSecond = BigNumber.from("20000").mul(N1__0_18DEC);
        const swapFixedInterestRateSecond = BigNumber.from("8").mul(N0__01_18DEC);
        const derivativeIbtQuantitySecond = BigNumber.from("173").mul(N1__0_18DEC);

        //when
        const actualSoapIndicatorSecond = await mockSoapIndicatorLogic.rebalanceWhenOpenSwap(
            actualSoapIndicatorFirst,
            rebalanceTimestampSecond,
            derivativeNotionalSecond,
            swapFixedInterestRateSecond,
            derivativeIbtQuantitySecond
        );

        //then
        const expectedRebalanceTimestamp = rebalanceTimestampSecond;
        const expectedTotalNotional = BigNumber.from("30000").mul(N1__0_18DEC);
        const expectedTotalIbtQuantity = BigNumber.from("268").mul(N1__0_18DEC);
        const expectedAverageInterestRate = BigNumber.from("7").mul(N0__01_18DEC);

        const expectedQuasiHypotheticalInterestCumulative = BigNumber.from("1080000000")
            .mul(N1__0_18DEC)
            .mul(N1__0_18DEC)
            .mul(N1__0_18DEC);

        await assertSoapIndicator(
            actualSoapIndicatorSecond,
            expectedRebalanceTimestamp,
            expectedTotalNotional,
            expectedTotalIbtQuantity,
            expectedAverageInterestRate,
            expectedQuasiHypotheticalInterestCumulative
        );
    });

    it("should rebalance SOAP Indicators when close position - one rebalance - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareInitialDefaultSoapIndicator(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            0
        );
        const rebalanceTimestampWhenOpen =
            soapIndicator.rebalanceTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotional = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapFixedInterestRate = BigNumber.from(5).mul(N0__01_18DEC);
        const derivativeIbtQuantity = BigNumber.from(95).mul(N1__0_18DEC);

        const soapIndicatorAfterOpen = await mockSoapIndicatorLogic.rebalanceWhenOpenSwap(
            soapIndicator,
            rebalanceTimestampWhenOpen,
            derivativeNotional,
            swapFixedInterestRate,
            derivativeIbtQuantity
        );

        const closeTimestamp = BigNumber.from(soapIndicatorAfterOpen.rebalanceTimestamp).add(
            PERIOD_25_DAYS_IN_SECONDS
        );

        //when
        const actualSoapIndicatorAfterClose = await mockSoapIndicatorLogic.rebalanceWhenCloseSwap(
            soapIndicatorAfterOpen,
            closeTimestamp,
            rebalanceTimestampWhenOpen,
            derivativeNotional,
            swapFixedInterestRate,
            derivativeIbtQuantity
        );

        //then
        const expectedRebalanceTimestamp = closeTimestamp;
        const expectedTotalNotional = ZERO;
        const expectedTotalIbtQuantity = ZERO;
        const expectedAverageInterestRate = ZERO;
        const expectedHypotheticalInterestCumulative = ZERO;

        await assertSoapIndicator(
            actualSoapIndicatorAfterClose,
            expectedRebalanceTimestamp,
            expectedTotalNotional,
            expectedTotalIbtQuantity,
            expectedAverageInterestRate,
            expectedHypotheticalInterestCumulative
        );
    });

    it("should rebalance SOAP Indicators when open two positions and close one position - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareInitialDefaultSoapIndicator(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            0
        );
        const rebalanceTimestampFirst =
            soapIndicator.rebalanceTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotionalFirst = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapFixedInterestRateFirst = BigNumber.from("5").mul(N0__01_18DEC);
        const derivativeIbtQuantityFirst = BigNumber.from("95").mul(N1__0_18DEC);

        const soapIndicatorAfterOpenFirst = await mockSoapIndicatorLogic.rebalanceWhenOpenSwap(
            soapIndicator,
            rebalanceTimestampFirst,
            derivativeNotionalFirst,
            swapFixedInterestRateFirst,
            derivativeIbtQuantityFirst
        );

        const averageInterestRateAfterFirstOpen = BigNumber.from(
            soapIndicatorAfterOpenFirst.averageInterestRate
        );

        const rebalanceTimestampSecond = BigNumber.from(
            soapIndicatorAfterOpenFirst.rebalanceTimestamp
        ).add(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotionalSecond = BigNumber.from("20000").mul(N1__0_18DEC);
        const swapFixedInterestRateSecond = BigNumber.from("8").mul(N0__01_18DEC);
        const derivativeIbtQuantitySecond = BigNumber.from("173").mul(N1__0_18DEC);

        const soapIndicatorAfterOpenSecond = await mockSoapIndicatorLogic.rebalanceWhenOpenSwap(
            soapIndicatorAfterOpenFirst,
            rebalanceTimestampSecond,
            derivativeNotionalSecond,
            swapFixedInterestRateSecond,
            derivativeIbtQuantitySecond
        );

        const closeTimestamp = BigNumber.from(soapIndicatorAfterOpenSecond.rebalanceTimestamp).add(
            PERIOD_25_DAYS_IN_SECONDS
        );

        //when
        const actualSoapIndicatorAfterClose = await mockSoapIndicatorLogic.rebalanceWhenCloseSwap(
            soapIndicatorAfterOpenSecond,
            closeTimestamp,
            rebalanceTimestampSecond,
            derivativeNotionalSecond,
            swapFixedInterestRateSecond,
            derivativeIbtQuantitySecond
        );

        //then
        const expectedRebalanceTimestamp = closeTimestamp;
        const expectedTotalNotional = BigNumber.from("10000").mul(N1__0_18DEC);
        const expectedTotalIbtQuantity = BigNumber.from("95").mul(N1__0_18DEC);
        const expectedAverageInterestRate = averageInterestRateAfterFirstOpen;
        const expectedHypotheticalInterestCumulative = BigNumber.from("2160000000")
            .mul(N1__0_18DEC)
            .mul(N1__0_18DEC)
            .mul(N1__0_18DEC);

        await assertSoapIndicator(
            actualSoapIndicatorAfterClose,
            expectedRebalanceTimestamp,
            expectedTotalNotional,
            expectedTotalIbtQuantity,
            expectedAverageInterestRate,
            expectedHypotheticalInterestCumulative
        );
    });

    it("should rebalance SOAP Indicators when open two positions and close two positions - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareInitialDefaultSoapIndicator(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            0
        );
        const rebalanceTimestampFirst =
            soapIndicator.rebalanceTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotionalFirst = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapFixedInterestRateFirst = BigNumber.from("5").mul(N0__01_18DEC);
        const derivativeIbtQuantityFirst = BigNumber.from("95").mul(N1__0_18DEC);

        const soapIndicatorAfterOpenFirst = await mockSoapIndicatorLogic.rebalanceWhenOpenSwap(
            soapIndicator,
            rebalanceTimestampFirst,
            derivativeNotionalFirst,
            swapFixedInterestRateFirst,
            derivativeIbtQuantityFirst
        );

        const rebalanceTimestampSecond = BigNumber.from(
            soapIndicatorAfterOpenFirst.rebalanceTimestamp
        ).add(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotionalSecond = BigNumber.from("20000").mul(N1__0_18DEC);
        const swapFixedInterestRateSecond = BigNumber.from("8").mul(N0__01_18DEC);
        const derivativeIbtQuantitySecond = BigNumber.from("173").mul(N1__0_18DEC);

        const soapIndicatorAfterOpenSecond = await mockSoapIndicatorLogic.rebalanceWhenOpenSwap(
            soapIndicatorAfterOpenFirst,
            rebalanceTimestampSecond,
            derivativeNotionalSecond,
            swapFixedInterestRateSecond,
            derivativeIbtQuantitySecond
        );

        const closeTimestampSecondPosition = BigNumber.from(
            soapIndicatorAfterOpenSecond.rebalanceTimestamp
        ).add(PERIOD_25_DAYS_IN_SECONDS);

        const soapIndicatorAfterCloseSecond = await mockSoapIndicatorLogic.rebalanceWhenCloseSwap(
            soapIndicatorAfterOpenSecond,
            closeTimestampSecondPosition,
            rebalanceTimestampSecond,
            derivativeNotionalSecond,
            swapFixedInterestRateSecond,
            derivativeIbtQuantitySecond
        );

        const closeTimestampFirstPosition = BigNumber.from(
            soapIndicatorAfterCloseSecond.rebalanceTimestamp
        ).add(PERIOD_25_DAYS_IN_SECONDS);

        //when
        const soapIndicatorAfterCloseFirst = await mockSoapIndicatorLogic.rebalanceWhenCloseSwap(
            soapIndicatorAfterCloseSecond,
            closeTimestampFirstPosition,
            rebalanceTimestampFirst,
            derivativeNotionalFirst,
            swapFixedInterestRateFirst,
            derivativeIbtQuantityFirst
        );

        //then
        const expectedRebalanceTimestamp = closeTimestampFirstPosition;
        const expectedTotalNotional = ZERO;
        const expectedTotalIbtQuantity = ZERO;
        const expectedAverageInterestRate = ZERO;
        const expectedHypotheticalInterestCumulative = ZERO;

        await assertSoapIndicator(
            soapIndicatorAfterCloseFirst,
            expectedRebalanceTimestamp,
            expectedTotalNotional,
            expectedTotalIbtQuantity,
            expectedAverageInterestRate,
            expectedHypotheticalInterestCumulative
        );
    });
});
