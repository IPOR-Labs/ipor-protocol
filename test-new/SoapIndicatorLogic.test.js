const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const {
    ZERO,
    YEARS_IN_SECONDS,
    PERIOD_25_DAYS_IN_SECONDS,
} = require("./Const.js");

const { assertError } = require("./Utils");

const ONE_18DEC = BigInt("1000000000000000000");
const ONE_16DEC = BigInt("10000000000000000");

describe("SoapIndicatorLogic", () => {
    let mockSoapIndicatorLogic;

    before(async () => {
        const SoapIndicatorLogic = await ethers.getContractFactory(
            "SoapIndicatorLogic"
        );
        const soapIndicatorLogic = await SoapIndicatorLogic.deploy();
        await soapIndicatorLogic.deployed();

        const MockSoapIndicatorLogic = await ethers.getContractFactory(
            "MockSoapIndicatorLogic"
        );
        mockSoapIndicatorLogic = await MockSoapIndicatorLogic.deploy();
        await mockSoapIndicatorLogic.deployed();
    });

    it("should calculate interest rate when open position - simple case - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareSoapIndicatorPayFixedCaseD18();
        const derivativeNotional = BigInt(10000) * ONE_18DEC;
        const derivativeFixedInterestRate = BigInt(4) * ONE_16DEC;

        //when

        const actualInterestRate =
            await mockSoapIndicatorLogic.calculateInterestRateWhenOpenPosition(
                soapIndicator,
                derivativeNotional,
                derivativeFixedInterestRate
            );

        //then
        const expectedInterestRate = BigInt("66666666666666667");
        expect(
            expectedInterestRate,
            "Wrong interest rate when open position"
        ).to.be.eq(actualInterestRate);
    });

    it("should calculate interest rate when close position - simple case - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareSoapIndicatorPayFixedCaseD18();
        const derivativeNotional = BigInt(10000) * ONE_18DEC;
        const derivativeFixedInterestRate = BigInt(4) * ONE_16DEC;

        //when

        const actualInterestRate =
            await mockSoapIndicatorLogic.calculateInterestRateWhenClosePosition(
                soapIndicator,
                derivativeNotional,
                derivativeFixedInterestRate
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
        const derivativeFixedInterestRate = BigInt(4) * ONE_16DEC;

        //when
        await assertError(
            //when
            mockSoapIndicatorLogic.calculateInterestRateWhenClosePosition(
                soapIndicator,
                derivativeNotional,
                derivativeFixedInterestRate
            ),
            //then
            "IPOR_19"
        );
    });

    it("should calculate interest delta - simple case 1 - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareSoapIndicatorPayFixedCaseD18();
        const timestamp =
            soapIndicator.rebalanceTimestamp +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);

        //when

        const actualQuasiInterestRate =
            await mockSoapIndicatorLogic.calculateQuasiHypotheticalInterestDelta(
                soapIndicator,
                timestamp
            );

        //then
        const expectedQuasiInterestDelta =
            BigInt("3456000000") * ONE_18DEC * ONE_18DEC * ONE_18DEC;
        expect(
            expectedQuasiInterestDelta,
            "Incorrect quasi interest in delta time"
        ).to.be.eq(actualQuasiInterestRate);
    });

    it("should calculate hypothetical interest delta - simple case 1 - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareSoapIndicatorPayFixedCaseD18();
        const timestamp =
            soapIndicator.rebalanceTimestamp +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);

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
            soapIndicator.rebalanceTimestamp +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotional = BigInt(10000) * ONE_18DEC;
        const derivativeFixedInterestRate = BigInt(5) * ONE_16DEC;
        const derivativeIbtQuantity = BigInt(95) * ONE_18DEC;

        //when
        const actualSoapIndicator =
            await mockSoapIndicatorLogic.rebalanceWhenOpenPosition(
                soapIndicator,
                rebalanceTimestamp,
                derivativeNotional,
                derivativeFixedInterestRate,
                derivativeIbtQuantity
            );

        //then
        await assertSoapIndicator(
            actualSoapIndicator,
            rebalanceTimestamp,
            derivativeNotional,
            derivativeIbtQuantity,
            derivativeFixedInterestRate,
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
            soapIndicator.rebalanceTimestamp +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotional = BigInt("10000") * ONE_18DEC;
        const derivativeFixedInterestRate = BigInt("5") * ONE_16DEC;
        const derivativeIbtQuantity = BigInt("95") * ONE_18DEC;

        const actualSoapIndicatorFirst =
            await mockSoapIndicatorLogic.rebalanceWhenOpenPosition(
                soapIndicator,
                rebalanceTimestamp,
                derivativeNotional,
                derivativeFixedInterestRate,
                derivativeIbtQuantity
            );

        const rebalanceTimestampSecond =
            BigInt(actualSoapIndicatorFirst.rebalanceTimestamp) +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);

        const derivativeNotionalSecond = BigInt("20000") * ONE_18DEC;
        const derivativeFixedInterestRateSecond = BigInt("8") * ONE_16DEC;
        const derivativeIbtQuantitySecond = BigInt("173") * ONE_18DEC;

        //when
        const actualSoapIndicatorSecond =
            await mockSoapIndicatorLogic.rebalanceWhenOpenPosition(
                actualSoapIndicatorFirst,
                rebalanceTimestampSecond,
                derivativeNotionalSecond,
                derivativeFixedInterestRateSecond,
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
            soapIndicator.rebalanceTimestamp +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotional = BigInt(10000) * ONE_18DEC;
        const derivativeFixedInterestRate = BigInt(5) * ONE_16DEC;
        const derivativeIbtQuantity = BigInt(95) * ONE_18DEC;

        const soapIndicatorAfterOpen =
            await mockSoapIndicatorLogic.rebalanceWhenOpenPosition(
                soapIndicator,
                rebalanceTimestampWhenOpen,
                derivativeNotional,
                derivativeFixedInterestRate,
                derivativeIbtQuantity
            );

        const closeTimestamp =
            BigInt(soapIndicatorAfterOpen.rebalanceTimestamp) +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);

        //when
        const actualSoapIndicatorAfterClose =
            await mockSoapIndicatorLogic.rebalanceWhenClosePosition(
                soapIndicatorAfterOpen,
                closeTimestamp,
                rebalanceTimestampWhenOpen,
                derivativeNotional,
                derivativeFixedInterestRate,
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
            soapIndicator.rebalanceTimestamp +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotionalFirst = BigInt("10000") * ONE_18DEC;
        const derivativeFixedInterestRateFirst = BigInt("5") * ONE_16DEC;
        const derivativeIbtQuantityFirst = BigInt("95") * ONE_18DEC;

        const soapIndicatorAfterOpenFirst =
            await mockSoapIndicatorLogic.rebalanceWhenOpenPosition(
                soapIndicator,
                rebalanceTimestampFirst,
                derivativeNotionalFirst,
                derivativeFixedInterestRateFirst,
                derivativeIbtQuantityFirst
            );

        const averageInterestRateAfterFirstOpen = BigInt(
            soapIndicatorAfterOpenFirst.averageInterestRate
        );

        const rebalanceTimestampSecond =
            BigInt(soapIndicatorAfterOpenFirst.rebalanceTimestamp) +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotionalSecond = BigInt("20000") * ONE_18DEC;
        const derivativeFixedInterestRateSecond = BigInt("8") * ONE_16DEC;
        const derivativeIbtQuantitySecond = BigInt("173") * ONE_18DEC;

        const soapIndicatorAfterOpenSecond =
            await mockSoapIndicatorLogic.rebalanceWhenOpenPosition(
                soapIndicatorAfterOpenFirst,
                rebalanceTimestampSecond,
                derivativeNotionalSecond,
                derivativeFixedInterestRateSecond,
                derivativeIbtQuantitySecond
            );

        const closeTimestamp =
            BigInt(soapIndicatorAfterOpenSecond.rebalanceTimestamp) +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);

        //when
        const actualSoapIndicatorAfterClose =
            await mockSoapIndicatorLogic.rebalanceWhenClosePosition(
                soapIndicatorAfterOpenSecond,
                closeTimestamp,
                rebalanceTimestampSecond,
                derivativeNotionalSecond,
                derivativeFixedInterestRateSecond,
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
            soapIndicator.rebalanceTimestamp +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotionalFirst = BigInt("10000") * ONE_18DEC;
        const derivativeFixedInterestRateFirst = BigInt("5") * ONE_16DEC;
        const derivativeIbtQuantityFirst = BigInt("95") * ONE_18DEC;

        const soapIndicatorAfterOpenFirst =
            await mockSoapIndicatorLogic.rebalanceWhenOpenPosition(
                soapIndicator,
                rebalanceTimestampFirst,
                derivativeNotionalFirst,
                derivativeFixedInterestRateFirst,
                derivativeIbtQuantityFirst
            );

        const rebalanceTimestampSecond =
            BigInt(soapIndicatorAfterOpenFirst.rebalanceTimestamp) +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);
        const derivativeNotionalSecond = BigInt("20000") * ONE_18DEC;
        const derivativeFixedInterestRateSecond = BigInt("8") * ONE_16DEC;
        const derivativeIbtQuantitySecond = BigInt("173") * ONE_18DEC;

        const soapIndicatorAfterOpenSecond =
            await mockSoapIndicatorLogic.rebalanceWhenOpenPosition(
                soapIndicatorAfterOpenFirst,
                rebalanceTimestampSecond,
                derivativeNotionalSecond,
                derivativeFixedInterestRateSecond,
                derivativeIbtQuantitySecond
            );

        const closeTimestampSecondPosition =
            BigInt(soapIndicatorAfterOpenSecond.rebalanceTimestamp) +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);

        const soapIndicatorAfterCloseSecond =
            await mockSoapIndicatorLogic.rebalanceWhenClosePosition(
                soapIndicatorAfterOpenSecond,
                closeTimestampSecondPosition,
                rebalanceTimestampSecond,
                derivativeNotionalSecond,
                derivativeFixedInterestRateSecond,
                derivativeIbtQuantitySecond
            );

        const closeTimestampFirstPosition =
            BigInt(soapIndicatorAfterCloseSecond.rebalanceTimestamp) +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);

        //when
        const soapIndicatorAfterCloseFirst =
            await mockSoapIndicatorLogic.rebalanceWhenClosePosition(
                soapIndicatorAfterCloseSecond,
                closeTimestampFirstPosition,
                rebalanceTimestampFirst,
                derivativeNotionalFirst,
                derivativeFixedInterestRateFirst,
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

    it("should calculate Pay Fixed Soap - simple case 1 - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareSoapIndicatorPayFixedCaseD18();
        const ibtPrice = BigInt(145) * ONE_18DEC;
        const calculationTimestamp =
            soapIndicator.rebalanceTimestamp +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);

        //when
        const actualSoapPf = await mockSoapIndicatorLogic.calculateSoap(
            soapIndicator,
            ibtPrice,
            calculationTimestamp
        );

        //then
        const expectedSoapPf = BigInt("-6109589041095890410958");
        expect(
            expectedSoapPf,
            "Incorrect SOAP for Pay Fixed Derivatives"
        ).to.be.eq(actualSoapPf);
    });

    it("should calculate Rec Fixed Soap - simple case 1 - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareSoapIndicatorRecFixedCaseD18();
        const ibtPrice = BigInt(145) * ONE_18DEC;
        const calculationTimestamp =
            soapIndicator.rebalanceTimestamp +
            BigInt(PERIOD_25_DAYS_IN_SECONDS);

        //when
        const actualSoapRf = await mockSoapIndicatorLogic.calculateSoap(
            soapIndicator,
            ibtPrice,
            calculationTimestamp
        );

        //then
        const expectedSoapRf = BigInt("6109589041095890410959");
        expect(
            expectedSoapRf,
            "Incorrect SOAP for Rec Fixed Derivatives"
        ).to.be.eq(actualSoapRf);
    });

    const assertSoapIndicator = async (
        actualSoapIndicator,
        expectedRebalanceTimestamp,
        expectedTotalNotional,
        expectedTotalIbtQuantity,
        expectedAverageInterestRate,
        expectedQuasiHypotheticalInterestCumulative
    ) => {
        expect(
            expectedRebalanceTimestamp,
            "Incorrect rebalance timestamp"
        ).to.be.eq(actualSoapIndicator.rebalanceTimestamp);
        expect(expectedTotalNotional, "Incorrect total notional").to.be.eq(
            actualSoapIndicator.totalNotional
        );
        expect(
            expectedTotalIbtQuantity,
            "Incorrect total IBT quantity"
        ).to.be.eq(actualSoapIndicator.totalIbtQuantity);
        expect(
            expectedAverageInterestRate,
            "Incorrect average weighted interest rate"
        ).to.be.eq(actualSoapIndicator.averageInterestRate);
        expect(
            expectedQuasiHypotheticalInterestCumulative,
            "Incorrect quasi hypothetical interest cumulative"
        ).to.be.eq(actualSoapIndicator.quasiHypotheticalInterestCumulative);
    };

    const prepareInitialDefaultSoapIndicator = async (
        rebalanceTimestamp,
        direction
    ) => {
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

    const prepareSoapIndicatorD18Case1 = async (
        rebalanceTimestamp,
        direction
    ) => {
        return {
            rebalanceTimestamp: rebalanceTimestamp,
            direction: direction,
            quasiHypotheticalInterestCumulative:
                BigInt("500") *
                ONE_18DEC *
                ONE_18DEC *
                ONE_18DEC *
                YEARS_IN_SECONDS,

            totalNotional: BigInt("20000000000000000000000"),
            averageInterestRate: BigInt("80000000000000000"),
            totalIbtQuantity: BigInt("100000000000000000000"),
            soap: ZERO,
        };
    };
});
