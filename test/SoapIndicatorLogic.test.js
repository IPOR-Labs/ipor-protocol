const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const { ZERO, YEARS_IN_SECONDS, PERIOD_25_DAYS_IN_SECONDS } = require("./Const.js");

const { assertError } = require("./Utils");

const ONE_18DEC = BigInt("1000000000000000000");
const ONE_16DEC = BigInt("10000000000000000");

describe("SoapIndicatorLogic", () => {
    let mockSoapIndicatorLogic;

    before(async () => {
        const SoapIndicatorLogic = await ethers.getContractFactory("SoapIndicatorLogic");
        const soapIndicatorLogic = await SoapIndicatorLogic.deploy();
        await soapIndicatorLogic.deployed();

        const MockSoapIndicatorLogic = await ethers.getContractFactory("MockSoapIndicatorLogic");
        mockSoapIndicatorLogic = await MockSoapIndicatorLogic.deploy();
        await mockSoapIndicatorLogic.deployed();
    });

    it("should calculate interest rate when open position - simple case - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareSoapIndicatorPayFixedCaseD18();
        const derivativeNotional = BigInt(10000) * ONE_18DEC;
        const swapFixedInterestRate = BigInt(4) * ONE_16DEC;

        //when

        const actualInterestRate = await mockSoapIndicatorLogic.calculateInterestRateWhenOpenSwap(
            soapIndicator.totalNotional,
            soapIndicator.averageInterestRate,
            derivativeNotional,
            swapFixedInterestRate
        );

        //then
        const expectedInterestRate = BigInt("66666666666666667");
        expect(expectedInterestRate, "Wrong interest rate when open position").to.be.eq(
            actualInterestRate
        );
    });

    it("should calculate interest rate when close position - simple case - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareSoapIndicatorPayFixedCaseD18();
        const derivativeNotional = BigInt(10000) * ONE_18DEC;
        const swapFixedInterestRate = BigInt(4) * ONE_16DEC;

        //when

        const actualInterestRate = await mockSoapIndicatorLogic.calculateInterestRateWhenCloseSwap(
            soapIndicator.totalNotional,
            soapIndicator.averageInterestRate,
            derivativeNotional,
            swapFixedInterestRate
        );

        //then
        const expectedInterestRate = BigInt("120000000000000000");
        expect(
            expectedInterestRate,
            "Wrong hypothetical interest rate when close position"
        ).to.be.eq(actualInterestRate);
    });

    it("should calculate interest rate when close position - notional too high - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareSoapIndicatorPayFixedCaseD18();
        const derivativeNotional = BigInt(40000) * ONE_18DEC;
        const swapFixedInterestRate = BigInt(4) * ONE_16DEC;

        //when
        await assertError(
            //when
            mockSoapIndicatorLogic.calculateInterestRateWhenCloseSwap(
                soapIndicator.totalNotional,
                soapIndicator.averageInterestRate,
                derivativeNotional,
                swapFixedInterestRate
            ),
            //then
            "IPOR_312"
        );
    });

    it("should calculate interest delta - simple case 1 - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareSoapIndicatorPayFixedCaseD18();
        const timestamp = soapIndicator.rebalanceTimestamp + BigInt(PERIOD_25_DAYS_IN_SECONDS);

        //when

        const actualQuasiInterestRate =
            await mockSoapIndicatorLogic.calculateQuasiHypotheticalInterestDelta(
                timestamp,
                soapIndicator.rebalanceTimestamp,
                soapIndicator.totalNotional,
                soapIndicator.averageInterestRate
            );

        //then
        const expectedQuasiInterestDelta = BigInt("3456000000") * ONE_18DEC * ONE_18DEC * ONE_18DEC;
        expect(expectedQuasiInterestDelta, "Incorrect quasi interest in delta time").to.be.eq(
            actualQuasiInterestRate
        );
    });

    it("should calculate hypothetical interest delta - simple case 1 - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareSoapIndicatorPayFixedCaseD18();
        const timestamp = soapIndicator.rebalanceTimestamp + BigInt(PERIOD_25_DAYS_IN_SECONDS);

        //when

        const actualQuasiHypotheticalInterestTotal =
            await mockSoapIndicatorLogic.calculateQuasiHyphoteticalInterestTotal(
                soapIndicator,
                timestamp
            );

        //then
        const expectedQuasiHypotheticalInterestTotal =
            BigInt("19224000000") * ONE_18DEC * ONE_18DEC * ONE_18DEC;
        expect(
            expectedQuasiHypotheticalInterestTotal,
            "Incorrect hypothetical interest total quasi"
        ).to.be.eq(actualQuasiHypotheticalInterestTotal);
    });

    it("should rebalance SOAP Indicators when open position - one rebalance - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareInitialDefaultSoapIndicator(
            BigInt(Math.floor(Date.now() / 1000)),
            BigNumber.from(0)
        );
        const rebalanceTimestamp =
            soapIndicator.rebalanceTimestamp + BigInt(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotional = BigInt(10000) * ONE_18DEC;
        const swapFixedInterestRate = BigInt(5) * ONE_16DEC;
        const derivativeIbtQuantity = BigInt(95) * ONE_18DEC;

        //when
        const actualSoapIndicator = await mockSoapIndicatorLogic.rebalanceWhenOpenSwap(
            soapIndicator,
            rebalanceTimestamp,
            derivativeNotional,
            swapFixedInterestRate,
            derivativeIbtQuantity
        );

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
            BigInt(Math.floor(Date.now() / 1000)),
            BigNumber.from(0)
        );

        const rebalanceTimestamp =
            soapIndicator.rebalanceTimestamp + BigInt(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotional = BigInt("10000") * ONE_18DEC;
        const swapFixedInterestRate = BigInt("5") * ONE_16DEC;
        const derivativeIbtQuantity = BigInt("95") * ONE_18DEC;

        const actualSoapIndicatorFirst = await mockSoapIndicatorLogic.rebalanceWhenOpenSwap(
            soapIndicator,
            rebalanceTimestamp,
            derivativeNotional,
            swapFixedInterestRate,
            derivativeIbtQuantity
        );

        const rebalanceTimestampSecond =
            BigInt(actualSoapIndicatorFirst.rebalanceTimestamp) + BigInt(PERIOD_25_DAYS_IN_SECONDS);

        const derivativeNotionalSecond = BigInt("20000") * ONE_18DEC;
        const swapFixedInterestRateSecond = BigInt("8") * ONE_16DEC;
        const derivativeIbtQuantitySecond = BigInt("173") * ONE_18DEC;

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
        const expectedTotalNotional = BigInt("30000") * ONE_18DEC;
        const expectedTotalIbtQuantity = BigInt("268") * ONE_18DEC;
        const expectedAverageInterestRate = BigInt("7") * ONE_16DEC;
        const expectedQuasiHypotheticalInterestCumulative =
            BigInt("1080000000") * ONE_18DEC * ONE_18DEC * ONE_18DEC;

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
            BigInt(Math.floor(Date.now() / 1000)),
            BigNumber.from(0)
        );
        const rebalanceTimestampWhenOpen =
            soapIndicator.rebalanceTimestamp + BigInt(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotional = BigInt(10000) * ONE_18DEC;
        const swapFixedInterestRate = BigInt(5) * ONE_16DEC;
        const derivativeIbtQuantity = BigInt(95) * ONE_18DEC;

        const soapIndicatorAfterOpen = await mockSoapIndicatorLogic.rebalanceWhenOpenSwap(
            soapIndicator,
            rebalanceTimestampWhenOpen,
            derivativeNotional,
            swapFixedInterestRate,
            derivativeIbtQuantity
        );

        const closeTimestamp =
            BigInt(soapIndicatorAfterOpen.rebalanceTimestamp) + BigInt(PERIOD_25_DAYS_IN_SECONDS);

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
            BigInt(Math.floor(Date.now() / 1000)),
            BigNumber.from(0)
        );
        const rebalanceTimestampFirst =
            soapIndicator.rebalanceTimestamp + BigInt(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotionalFirst = BigInt("10000") * ONE_18DEC;
        const swapFixedInterestRateFirst = BigInt("5") * ONE_16DEC;
        const derivativeIbtQuantityFirst = BigInt("95") * ONE_18DEC;

        const soapIndicatorAfterOpenFirst = await mockSoapIndicatorLogic.rebalanceWhenOpenSwap(
            soapIndicator,
            rebalanceTimestampFirst,
            derivativeNotionalFirst,
            swapFixedInterestRateFirst,
            derivativeIbtQuantityFirst
        );

        const averageInterestRateAfterFirstOpen = BigInt(
            soapIndicatorAfterOpenFirst.averageInterestRate
        );

        const rebalanceTimestampSecond =
            BigInt(soapIndicatorAfterOpenFirst.rebalanceTimestamp) +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotionalSecond = BigInt("20000") * ONE_18DEC;
        const swapFixedInterestRateSecond = BigInt("8") * ONE_16DEC;
        const derivativeIbtQuantitySecond = BigInt("173") * ONE_18DEC;

        const soapIndicatorAfterOpenSecond = await mockSoapIndicatorLogic.rebalanceWhenOpenSwap(
            soapIndicatorAfterOpenFirst,
            rebalanceTimestampSecond,
            derivativeNotionalSecond,
            swapFixedInterestRateSecond,
            derivativeIbtQuantitySecond
        );

        const closeTimestamp =
            BigInt(soapIndicatorAfterOpenSecond.rebalanceTimestamp) +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);

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
        const expectedTotalNotional = BigInt("10000") * ONE_18DEC;
        const expectedTotalIbtQuantity = BigInt("95") * ONE_18DEC;
        const expectedAverageInterestRate = averageInterestRateAfterFirstOpen;
        const expectedHypotheticalInterestCumulative =
            BigInt("2160000000") * ONE_18DEC * ONE_18DEC * ONE_18DEC;

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
            BigInt(Math.floor(Date.now() / 1000)),
            BigNumber.from(0)
        );
        const rebalanceTimestampFirst =
            soapIndicator.rebalanceTimestamp + BigInt(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotionalFirst = BigInt("10000") * ONE_18DEC;
        const swapFixedInterestRateFirst = BigInt("5") * ONE_16DEC;
        const derivativeIbtQuantityFirst = BigInt("95") * ONE_18DEC;

        const soapIndicatorAfterOpenFirst = await mockSoapIndicatorLogic.rebalanceWhenOpenSwap(
            soapIndicator,
            rebalanceTimestampFirst,
            derivativeNotionalFirst,
            swapFixedInterestRateFirst,
            derivativeIbtQuantityFirst
        );

        const rebalanceTimestampSecond =
            BigInt(soapIndicatorAfterOpenFirst.rebalanceTimestamp) +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotionalSecond = BigInt("20000") * ONE_18DEC;
        const swapFixedInterestRateSecond = BigInt("8") * ONE_16DEC;
        const derivativeIbtQuantitySecond = BigInt("173") * ONE_18DEC;

        const soapIndicatorAfterOpenSecond = await mockSoapIndicatorLogic.rebalanceWhenOpenSwap(
            soapIndicatorAfterOpenFirst,
            rebalanceTimestampSecond,
            derivativeNotionalSecond,
            swapFixedInterestRateSecond,
            derivativeIbtQuantitySecond
        );

        const closeTimestampSecondPosition =
            BigInt(soapIndicatorAfterOpenSecond.rebalanceTimestamp) +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);

        const soapIndicatorAfterCloseSecond = await mockSoapIndicatorLogic.rebalanceWhenCloseSwap(
            soapIndicatorAfterOpenSecond,
            closeTimestampSecondPosition,
            rebalanceTimestampSecond,
            derivativeNotionalSecond,
            swapFixedInterestRateSecond,
            derivativeIbtQuantitySecond
        );

        const closeTimestampFirstPosition =
            BigInt(soapIndicatorAfterCloseSecond.rebalanceTimestamp) +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);

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

    const assertSoapIndicator = async (
        actualSoapIndicator,
        expectedRebalanceTimestamp,
        expectedTotalNotional,
        expectedTotalIbtQuantity,
        expectedAverageInterestRate,
        expectedQuasiHypotheticalInterestCumulative
    ) => {
        expect(expectedRebalanceTimestamp, "Incorrect rebalance timestamp").to.be.eq(
            BigInt(actualSoapIndicator.rebalanceTimestamp)
        );

        expect(expectedTotalNotional, "Incorrect total notional").to.be.eq(
            actualSoapIndicator.totalNotional
        );
        expect(expectedTotalIbtQuantity, "Incorrect total IBT quantity").to.be.eq(
            actualSoapIndicator.totalIbtQuantity
        );
        expect(expectedAverageInterestRate, "Incorrect average weighted interest rate").to.be.eq(
            actualSoapIndicator.averageInterestRate
        );
        expect(
            expectedQuasiHypotheticalInterestCumulative,
            "Incorrect quasi hypothetical interest cumulative"
        ).to.be.eq(actualSoapIndicator.quasiHypotheticalInterestCumulative);
    };

    const prepareInitialDefaultSoapIndicator = async (rebalanceTimestamp, direction) => {
        return {
            rebalanceTimestamp: rebalanceTimestamp,
            direction: direction,
            quasiHypotheticalInterestCumulative: ZERO,
            totalNotional: ZERO,
            averageInterestRate: ZERO,
            totalIbtQuantity: ZERO,
            soap: ZERO,
        };
    };

    const prepareSoapIndicatorPayFixedCaseD18 = async () => {
        return prepareSoapIndicatorD18Case1(
            BigInt(Math.floor(Date.now() / 1000)),
            BigNumber.from(0)
        );
    };

    const prepareSoapIndicatorRecFixedCaseD18 = async () => {
        return prepareSoapIndicatorD18Case1(
            BigInt(Math.floor(Date.now() / 1000)),
            BigNumber.from(1)
        );
    };

    const prepareSoapIndicatorD18Case1 = async (rebalanceTimestamp, direction) => {
        return {
            rebalanceTimestamp: rebalanceTimestamp,
            direction: direction,
            quasiHypotheticalInterestCumulative:
                BigInt("500") * ONE_18DEC * ONE_18DEC * ONE_18DEC * YEARS_IN_SECONDS,

            totalNotional: BigInt("20000000000000000000000"),
            averageInterestRate: BigInt("80000000000000000"),
            totalIbtQuantity: BigInt("100000000000000000000"),
            soap: ZERO,
        };
    };
});
