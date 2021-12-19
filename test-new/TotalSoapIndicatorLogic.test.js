const { expect } = require("chai");
const { ethers } = require("hardhat");
const { DerivativeDirection } = require("./enums.js");
const {
    PERIOD_1_DAY_IN_SECONDS,
    PERIOD_25_DAYS_IN_SECONDS,
} = require("./Const.js");
const ONE_18DEC = BigInt("1000000000000000000");

const prepareInitialSoapIndicator = (timestamp, direction) => {
    return {
        rebalanceTimestamp: timestamp,
        direction,
        quasiHypotheticalInterestCumulative: BigInt(0),
        totalNotional: BigInt(0),
        averageInterestRate: BigInt(0),
        totalIbtQuantity: BigInt(0),
        soap: BigInt(0),
    };
};

const prepareInitialTotalSoapIndicator = async (timestamp) => {
    const pf = prepareInitialSoapIndicator(
        timestamp,
        DerivativeDirection.PayFixedReceiveFloating
    );

    const rf = prepareInitialSoapIndicator(
        timestamp,
        DerivativeDirection.PayFloatingReceiveFixed
    );
    return { pf, rf };
};

const simulateOpenPayFixPositionCase1D18 = async (
    deltaTimeInSeconds,
    tsiStorage,
    soapIndicatorLogic
) => {
    const rebalanceTimestamp =
        tsiStorage.pf.rebalanceTimestamp + deltaTimeInSeconds;
    const derivativeNotional = BigInt(10000) * ONE_18DEC;
    const derivativeFixedInterestRate = BigInt(5 * 1e16);
    const derivativeIbtQuantity = BigInt(95 * 1e18);
    const si = tsiStorage.pf;

    const siResult = await soapIndicatorLogic.rebalanceWhenOpenPosition(
        si,
        rebalanceTimestamp,
        derivativeNotional,
        derivativeFixedInterestRate,
        derivativeIbtQuantity
    );
    tsiStorage.pf = siResult;
    return tsiStorage;
};

const simulateOpenPayFixPositionCase2D18 = async (
    deltaTimeInSeconds,
    tsiStorage,
    soapIndicatorLogic
) => {
    const rebalanceTimestamp =
        tsiStorage.pf.rebalanceTimestamp + deltaTimeInSeconds;
    const derivativeNotional = BigInt(98703) * ONE_18DEC;
    const derivativeFixedInterestRate = BigInt(3 * 1e16);
    const derivativeIbtQuantity = BigInt(98703 * 1e16);
    const si = tsiStorage.pf;

    const siResult = await soapIndicatorLogic.rebalanceWhenOpenPosition(
        si,
        rebalanceTimestamp,
        derivativeNotional,
        derivativeFixedInterestRate,
        derivativeIbtQuantity
    );
    tsiStorage.pf = siResult;
    return tsiStorage;
};

const simulateOpenRecFixPositionCase1D18 = async (
    deltaTimeInSeconds,
    tsiStorage,
    soapIndicatorLogic
) => {
    const rebalanceTimestamp =
        tsiStorage.rf.rebalanceTimestamp + deltaTimeInSeconds;
    const derivativeNotional = BigInt(10000) * ONE_18DEC;
    const derivativeFixedInterestRate = BigInt(5 * 1e16);
    const derivativeIbtQuantity = BigInt(95) * ONE_18DEC;
    const si = tsiStorage.rf;
    const siResult = await soapIndicatorLogic.rebalanceWhenOpenPosition(
        si,
        rebalanceTimestamp,
        derivativeNotional,
        derivativeFixedInterestRate,
        derivativeIbtQuantity
    );
    tsiStorage.rf = siResult;
    return tsiStorage;
};

const simulateOpenRecFixPositionCase2D18 = async (
    deltaTimeInSeconds,
    tsiStorage,
    soapIndicatorLogic
) => {
    const rebalanceTimestamp =
        tsiStorage.rf.rebalanceTimestamp + deltaTimeInSeconds;
    const derivativeNotional = BigInt(98703) * ONE_18DEC;
    const derivativeFixedInterestRate = BigInt(3 * 1e16);
    const derivativeIbtQuantity = BigInt(98703 * 1e16);
    const si = tsiStorage.rf;
    const siResult = await soapIndicatorLogic.rebalanceWhenOpenPosition(
        si,
        rebalanceTimestamp,
        derivativeNotional,
        derivativeFixedInterestRate,
        derivativeIbtQuantity
    );
    tsiStorage.rf = siResult;
    return tsiStorage;
};

const assertSoapIndicator = (
    si,
    expectedRebalanceTimestamp,
    expectedTotalNotional,
    expectedTotalIbtQuantity,
    expectedAverageInterestRate,
    expectedQuasiHypotheticalInterestCumulative
) => {
    expect(si.rebalanceTimestamp, "Incorrect rebalance timestamp").to.be.equal(
        expectedRebalanceTimestamp
    );
    expect(si.totalNotional, "Incorrect total notional").to.be.equal(
        expectedTotalNotional
    );
    expect(si.totalIbtQuantity, "Incorrect total IBT quantity").to.be.equal(
        expectedTotalIbtQuantity
    );
    expect(
        si.averageInterestRate,
        "Incorrect average weighted interest rate"
    ).to.be.equal(expectedAverageInterestRate);
    expect(
        si.quasiHypotheticalInterestCumulative,
        "Incorrect quasi hypothetical interest cumulative"
    ).to.be.equal(expectedQuasiHypotheticalInterestCumulative);
};

describe("TotalSoapIndicatorLogic", () => {
    let totalSoapIndicatorLogic;
    let soapIndicatorLogic;

    before(async () => {
        MockTotalSoapIndicatorLogic = await ethers.getContractFactory(
            "MockTotalSoapIndicatorLogic"
        );
        totalSoapIndicatorLogic = await MockTotalSoapIndicatorLogic.deploy();
        await totalSoapIndicatorLogic.deployed();

        const MockSoapIndicatorLogic = await ethers.getContractFactory(
            "MockSoapIndicatorLogic"
        );
        soapIndicatorLogic = await MockSoapIndicatorLogic.deploy();
        await soapIndicatorLogic.deployed();
    });

    it("Calculate Soap When Open Pay Fix Position D18", async () => {
        const ibtPrice = BigInt(100) * ONE_18DEC;
        const timestamp = Date.now();
        const tsiStorage = await prepareInitialTotalSoapIndicator(timestamp);

        const tsiSimulateOpenPayFixPosition =
            await simulateOpenPayFixPositionCase2D18(
                PERIOD_1_DAY_IN_SECONDS,
                tsiStorage,
                soapIndicatorLogic
            );

        //when
        const { soapPf, soapRf } = await totalSoapIndicatorLogic.calculateSoap(
            tsiSimulateOpenPayFixPosition,
            timestamp + PERIOD_1_DAY_IN_SECONDS + PERIOD_25_DAYS_IN_SECONDS,
            ibtPrice
        );
        //then
        expect(soapPf, "Incorrect SOAP PF").to.be.equal(
            "-202814383561637282015"
        );
        expect(soapRf, "Incorrect SOAP RF").to.be.equal("0");
    });

    it("Calculate Soap When Open Pay Fix And Rec Fix Position Same Notional Same Moment D18", async () => {
        //given
        const ibtPrice = BigInt(100) * ONE_18DEC;
        const timestamp = Date.now();
        const tsiStorage = await prepareInitialTotalSoapIndicator(timestamp);
        const tsiSimulatPf = await simulateOpenPayFixPositionCase2D18(
            0,
            tsiStorage,
            soapIndicatorLogic
        );
        const tsiSimulatRf = await simulateOpenRecFixPositionCase2D18(
            0,
            tsiSimulatPf,
            soapIndicatorLogic
        );

        //when
        const { soapPf, soapRf } =
            await totalSoapIndicatorLogic.calculateQuasiSoap(
                tsiSimulatRf,
                timestamp + PERIOD_25_DAYS_IN_SECONDS,
                ibtPrice
            );
        //then
        expect(soapPf, "Incorrect SOAP PF").to.be.equal(
            "-6395954399999793325670400000000000000000000000000000000000000000"
        );
        expect(soapRf, "Incorrect SOAP RF").to.be.equal(
            "6395954399999793325670400000000000000000000000000000000000000000"
        );
    });

    it("Calculate Soap When Open Pay Fix And Rec Fix Position Same Notional Different Moment D18", async () => {
        //given

        const ibtPrice = BigInt(100) * ONE_18DEC;
        const timestamp = Date.now();
        const tsiStorage = await prepareInitialTotalSoapIndicator(timestamp);
        const tsiSimulatPf = await simulateOpenPayFixPositionCase2D18(
            PERIOD_25_DAYS_IN_SECONDS,
            tsiStorage,
            soapIndicatorLogic
        );
        const tsiSimulatRf = await simulateOpenRecFixPositionCase2D18(
            0,
            tsiSimulatPf,
            soapIndicatorLogic
        );

        //when
        const { soapPf, soapRf } = await totalSoapIndicatorLogic.calculateSoap(
            tsiSimulatRf,
            timestamp + PERIOD_25_DAYS_IN_SECONDS,
            ibtPrice
        );

        //then
        expect(soapPf, "Incorrect SOAP PF").to.be.equal("6553600");
        expect(soapRf, "Incorrect SOAP RF").to.be.equal(
            "202814383561637282016"
        );
        const result = BigInt(soapPf) + BigInt(soapRf);
        expect(result, "Incorrect SOAP").to.be.equal(
            BigInt("202814383561643835616")
        );
    });

    it("Rebalance Soap When Open Pay Fix Position D18", async () => {
        //given
        const timestamp = Date.now();
        const tsiStorage = await prepareInitialTotalSoapIndicator(timestamp);

        //when
        const tsiSimulatPf = await simulateOpenPayFixPositionCase1D18(
            PERIOD_25_DAYS_IN_SECONDS,
            tsiStorage,
            soapIndicatorLogic
        );

        //then
        const expectedRebalanceTimestamp = tsiSimulatPf.pf.rebalanceTimestamp;
        const expectedTotalNotional = BigInt(10000) * ONE_18DEC;
        const expectedTotalIbtQuantity = BigInt(95) * ONE_18DEC;
        const expectedAverageInterestRate = BigInt(5 * 1e16);
        const expectedHypotheticalInterestCumulative = BigInt(0);

        assertSoapIndicator(
            tsiSimulatPf.pf,
            expectedRebalanceTimestamp,
            expectedTotalNotional,
            expectedTotalIbtQuantity,
            expectedAverageInterestRate,
            expectedHypotheticalInterestCumulative
        );
    });

    it("Rebalance Soap When Open Rec Fix Position D18", async () => {
        //given
        const timestamp = Date.now();
        const tsiStorage = await prepareInitialTotalSoapIndicator(timestamp);

        //when
        const tsiSimulatRf = await simulateOpenRecFixPositionCase1D18(
            PERIOD_25_DAYS_IN_SECONDS,
            tsiStorage,
            soapIndicatorLogic
        );

        const expectedRebalanceTimestamp = tsiSimulatRf.rf.rebalanceTimestamp;
        const expectedTotalNotional = BigInt("10000") * ONE_18DEC;
        const expectedTotalIbtQuantity = BigInt("95") * ONE_18DEC;
        const expectedAverageInterestRate = BigInt(5 * 1e16);
        const expectedHypotheticalInterestCumulative = BigInt(0);

        assertSoapIndicator(
            tsiStorage.rf,
            expectedRebalanceTimestamp,
            expectedTotalNotional,
            expectedTotalIbtQuantity,
            expectedAverageInterestRate,
            expectedHypotheticalInterestCumulative
        );
    });

    it("Rebalance Soap When Pay Fix And Rec Fix Position D18", async () => {
        //given
        const timestamp = Date.now();
        const tsiStorage = await prepareInitialTotalSoapIndicator(timestamp);

        //when
        const tsiSimulatPf = await simulateOpenPayFixPositionCase1D18(
            PERIOD_25_DAYS_IN_SECONDS,
            tsiStorage,
            soapIndicatorLogic
        );
        const tsiSimulatRf = await simulateOpenRecFixPositionCase1D18(
            PERIOD_25_DAYS_IN_SECONDS,
            tsiSimulatPf,
            soapIndicatorLogic
        );

        //then
        const expectedRebalanceTimestamp = tsiSimulatRf.pf.rebalanceTimestamp;
        const expectedTotalNotional = BigInt("10000") * ONE_18DEC;
        const expectedTotalIbtQuantity = BigInt("95") * ONE_18DEC;
        const expectedAverageInterestRate = BigInt(5 * 1e16);
        const expectedHypotheticalInterestCumulative = BigInt(0);

        assertSoapIndicator(
            tsiStorage.pf,
            expectedRebalanceTimestamp,
            expectedTotalNotional,
            expectedTotalIbtQuantity,
            expectedAverageInterestRate,
            expectedHypotheticalInterestCumulative
        );

        assertSoapIndicator(
            tsiStorage.rf,
            expectedRebalanceTimestamp,
            expectedTotalNotional,
            expectedTotalIbtQuantity,
            expectedAverageInterestRate,
            expectedHypotheticalInterestCumulative
        );
    });
});
