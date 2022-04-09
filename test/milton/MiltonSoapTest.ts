import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    ZERO,
	N0__01_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_6_18DEC,
    PERCENTAGE_120_18DEC,
    PERIOD_25_DAYS_IN_SECONDS,
    PERCENTAGE_5_18DEC,
    USD_28_000_18DEC,
    LEVERAGE_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USD_10_000_6DEC,
    USD_28_000_6DEC,
    PERCENTAGE_6_6DEC,
    PERIOD_50_DAYS_IN_SECONDS,
    PERIOD_28_DAYS_IN_SECONDS,
    PERIOD_1_DAY_IN_SECONDS,
} from "../utils/Constants";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    prepareMockMiltonSpreadModel,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
} from "../utils/MiltonUtils";
import {
    prepareTestData,
    prepareApproveForUsers,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdtInitialValuesForUsers,
} from "../utils/DataUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";
import {
    calculateSoap,
    openSwapPayFixed,
    assertSoap,
    openSwapReceiveFixed,
} from "../utils/SwapUtils";

const { expect } = chai;

describe("Milton SOAP", () => {
    let miltonSpreadModel: MockMiltonSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockMiltonSpreadModel(MiltonSpreadModels.CASE1);
    });

    it("should calculate soap, no derivatives, soap equal 0", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userTwo],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        const { tokenDai } = testData;

        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            calculateTimestamp: BigNumber.from(BigNumber.from(Math.floor(Date.now() / 1000))),
            from: userTwo,
        };
        const expectedSoap = ZERO;

        //when
        const actualSoapStruct = await calculateSoap(testData, params);
        const actualSoap = actualSoapStruct?.soap || ZERO;

        //then
        expect(
            expectedSoap,
            `Incorrect SOAP for asset ${params.asset} actual: ${actualSoap}, expected: ${expectedSoap}`
        ).to.be.eq(actualSoap);
    });

    it("should calculate soap, DAI, pay fixed, add position, calculate now", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const { tokenDai, josephDai, iporOracle } = testData;

        if (tokenDai === undefined || josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const openerUserAddress = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_5_18DEC;

        const derivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: openerUserAddress,
        };

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParams);

        const expectedSoap = ZERO;

        //when
        const soapParams = {
            asset: tokenDai.address,
            calculateTimestamp: derivativeParams.openTimestamp,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(testData, soapParams);
    });

    it("should calculate soap, DAI, pay fixed, add position, calculate after 25 days", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE0,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const openerUser = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;

        const { tokenDai, josephDai, iporOracle } = testData;

        if (tokenDai === undefined || josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const derivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: openerUser,
        };

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParams);

        const expectedSoap = BigNumber.from("-68267191075554066594");

        //when
        const soapParams = {
            asset: tokenDai.address,
            calculateTimestamp: derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(testData, soapParams);
    });

    it("should calculate soap, DAI, rec fixed, add position, calculate now", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const openerUser = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;

        const { tokenDai, josephDai, iporOracle } = testData;

        if (tokenDai === undefined || josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const derivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: N0__01_18DEC,
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: openerUser,
        };

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );
        await openSwapReceiveFixed(testData, derivativeParams);

        const expectedSoap = ZERO;

        //when
        const soapParams = {
            asset: tokenDai.address,
            calculateTimestamp: derivativeParams.openTimestamp,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(testData, soapParams);
    });

    it("should calculate soap, DAI, rec fixed, add position, calculate after 25 days", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const openerUser = userTwo;
        const iporValueBeforOpenSwap = PERCENTAGE_3_18DEC;

        const { tokenDai, josephDai, iporOracle } = testData;

        if (tokenDai === undefined || josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const derivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: N0__01_18DEC,
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: openerUser,
        };

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforOpenSwap,
                derivativeParams.openTimestamp
            );
        await openSwapReceiveFixed(testData, derivativeParams);

        const expectedSoap = BigNumber.from("-68267191075554025634");

        //when
        const soapParams = {
            asset: tokenDai.address,
            calculateTimestamp: derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(testData, soapParams);
    });

    it("should calculate soap, DAI, pay fixed, add and remove position", async () => {
        // given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const openerUser = userTwo;
        const closerUser = userTwo;
        const iporValueBeforOpenSwap = PERCENTAGE_3_18DEC;

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const derivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: openerUser,
        };

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforOpenSwap,
                derivativeParams.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParams);

        const endTimestamp = derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        //when
        await miltonDai.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp);

        const expectedSoap = ZERO;

        //when
        const soapParams = {
            asset: tokenDai.address,
            calculateTimestamp: endTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            expectedSoap: expectedSoap,
            from: userTwo,
        };

        await assertSoap(testData, soapParams);
    });

    it("should calculate soap, DAI, rec fixed, add and remove position", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const openerUser = userTwo;
        const closerUser = userTwo;
        const iporValueBeforOpenSwap = PERCENTAGE_3_18DEC;

        const derivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: N0__01_18DEC,
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: openerUser,
        };

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforOpenSwap,
                derivativeParams.openTimestamp
            );
        await openSwapReceiveFixed(testData, derivativeParams);

        const expectedSoap = ZERO;
        let endTimestamp = derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        //we expecting that Milton loose his money, so we add some cash to liquidity pool
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(TC_TOTAL_AMOUNT_10_000_18DEC, derivativeParams.openTimestamp);

        //when
        await miltonDai.connect(closerUser).itfCloseSwapReceiveFixed(1, endTimestamp);

        const soapParams = {
            asset: tokenDai.address,
            calculateTimestamp: derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(testData, soapParams);
    });

    it("should calculate soap, DAI add pay fixed, DAI add rec fixed, 18 decimals", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        let openerUser = userTwo;
        let iporValueBeforOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const firstDerivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const secondDerivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: N0__01_18DEC,
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from(2).mul(USD_28_000_18DEC), openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(firstDerivativeParams.asset, iporValueBeforOpenSwap, openTimestamp);
        await openSwapPayFixed(testData, firstDerivativeParams);
        await openSwapReceiveFixed(testData, secondDerivativeParams);

        const expectedSoap = BigNumber.from("-136534382151108092229");

        //when
        const soapParams = {
            asset: tokenDai.address,
            calculateTimestamp: openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            expectedSoap: expectedSoap,
            from: userTwo,
        };

        await assertSoap(testData, soapParams);
    });

    it("should calculate soap, USDT add pay fixed, USDT add rec fixed, 6 decimals", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            testData
        );

        const { tokenUsdt, josephUsdt, iporOracle } = testData;

        if (tokenUsdt === undefined || josephUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        let openerUser = userTwo;
        let iporValueBeforOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const firstDerivativeParams = {
            asset: tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            acceptableFixedInterestRate: BigNumber.from("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const secondDerivativeParams = {
            asset: tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            acceptableFixedInterestRate: N0__01_18DEC,
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from(2).add(USD_28_000_6DEC), openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(firstDerivativeParams.asset, iporValueBeforOpenSwap, openTimestamp);
        await openSwapPayFixed(testData, firstDerivativeParams);
        await openSwapReceiveFixed(testData, secondDerivativeParams);

        const expectedSoap = BigNumber.from("-136534382151108092229");

        //when
        const soapParams = {
            asset: tokenUsdt.address,
            calculateTimestamp: openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            expectedSoap: expectedSoap,
            from: userTwo,
        };

        await assertSoap(testData, soapParams);
    });

    it("should calculate soap, DAI add pay fixed, USDT add pay fixed", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI", "USDT"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            testData
        );

        const { tokenDai, josephDai, iporOracle, miltonDai, tokenUsdt, josephUsdt } = testData;

        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            tokenUsdt === undefined ||
            josephUsdt === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        let openerUser = userTwo;

        let iporValueBeforOpenSwapDAI = PERCENTAGE_3_18DEC;
        let iporValueBeforOpenSwapUSDT = PERCENTAGE_3_18DEC;

        let openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeDAIParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const derivativeUSDTParams = {
            asset: tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            acceptableFixedInterestRate: BigNumber.from("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, openTimestamp);
        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeDAIParams.asset,
                iporValueBeforOpenSwapDAI,
                derivativeDAIParams.openTimestamp
            );
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeUSDTParams.asset,
                iporValueBeforOpenSwapUSDT,
                derivativeUSDTParams.openTimestamp
            );

        //when
        await openSwapPayFixed(testData, derivativeDAIParams);
        await openSwapPayFixed(testData, derivativeUSDTParams);

        //then
        let expectedDAISoap = BigNumber.from("-68267191075554066594");

        let expectedUSDTSoap = BigNumber.from("-68267191075554066594");

        const soapDAIParams = {
            asset: tokenDai.address,
            calculateTimestamp: derivativeDAIParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            expectedSoap: expectedDAISoap,
            from: userTwo,
        };
        await assertSoap(testData, soapDAIParams);

        const soapUSDTParams = {
            asset: tokenUsdt.address,
            calculateTimestamp: derivativeUSDTParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            expectedSoap: expectedUSDTSoap,
            from: userTwo,
        };
        await assertSoap(testData, soapUSDTParams);
    });

    it("should calculate soap, DAI add pay fixed, DAI add rec fixed, close rec fixed position", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const openerUser = userTwo;
        const closerUser = userTwo;
        const iporValueBeforOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const payFixDerivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const recFixDerivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: N0__01_18DEC,
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from(2).add(USD_28_000_18DEC), openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(payFixDerivativeParams.asset, iporValueBeforOpenSwap, openTimestamp);
        await openSwapPayFixed(testData, payFixDerivativeParams);
        await openSwapReceiveFixed(testData, recFixDerivativeParams);

        const endTimestamp = recFixDerivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        //when
        await miltonDai.connect(closerUser).itfCloseSwapReceiveFixed(2, endTimestamp);

        //then
        const expectedSoap = BigNumber.from("-68267191075554066594");

        const soapParams = {
            asset: tokenDai.address,
            calculateTimestamp: openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            expectedSoap: expectedSoap,
            from: userTwo,
        };

        await assertSoap(testData, soapParams);
    });

    it("should calculate soap, DAI add pay fixed, DAI add rec fixed, remove pay fixed position after 25 days", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const openerUser = userTwo;
        const closerUser = userTwo;
        const iporValueBeforOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const payFixDerivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const recFixDerivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: N0__01_18DEC,
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from(2).add(USD_28_000_18DEC), openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(payFixDerivativeParams.asset, iporValueBeforOpenSwap, openTimestamp);
        await openSwapPayFixed(testData, payFixDerivativeParams);
        await openSwapReceiveFixed(testData, recFixDerivativeParams);

        let endTimestamp = recFixDerivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        //when
        await miltonDai.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp);

        //then
        const expectedSoap = BigNumber.from("-68267191075554025634");

        const soapParams = {
            asset: tokenDai.address,
            calculateTimestamp: openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            expectedSoap: expectedSoap,
            from: userTwo,
        };

        await assertSoap(testData, soapParams);
    });

    it("should calculate soap, DAI add pay fixed, USDT add rec fixed, remove rec fixed position after 25 days", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI", "USDT"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            testData
        );

        const { tokenDai, josephDai, iporOracle, miltonDai, tokenUsdt, josephUsdt, miltonUsdt } =
            testData;

        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            tokenUsdt === undefined ||
            josephUsdt === undefined ||
            miltonUsdt === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        const openerUser = userTwo;
        const closerUser = userTwo;
        const iporValueBeforOpenSwapDAI = PERCENTAGE_3_18DEC;
        const iporValueBeforOpenSwapUSDT = PERCENTAGE_3_18DEC;

        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const payFixDerivativeDAIParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const recFixDerivativeUSDTParams = {
            asset: tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            acceptableFixedInterestRate: N0__01_18DEC,
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, openTimestamp);

        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, openTimestamp);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                payFixDerivativeDAIParams.asset,
                iporValueBeforOpenSwapDAI,
                openTimestamp
            );
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                recFixDerivativeUSDTParams.asset,
                iporValueBeforOpenSwapUSDT,
                openTimestamp
            );

        await openSwapPayFixed(testData, payFixDerivativeDAIParams);
        await openSwapReceiveFixed(testData, recFixDerivativeUSDTParams);

        //we expecting that Milton loose his money, so we add some cash to liquidity pool
        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_10_000_6DEC, openTimestamp);

        let endTimestamp = recFixDerivativeUSDTParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        //when
        await miltonUsdt.connect(closerUser).itfCloseSwapReceiveFixed(1, endTimestamp);

        //then
        const expectedSoapDAI = BigNumber.from("-68267191075554066594");

        const soapParamsDAI = {
            asset: tokenDai.address,
            calculateTimestamp: openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            expectedSoap: expectedSoapDAI,
            from: userTwo,
        };

        await assertSoap(testData, soapParamsDAI);
    });

    it("should calculate soap, DAI add pay fixed, change ibtPrice, wait 25 days and then calculate soap, 18 decimals", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const openerUser = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const iporValueAfterOpenSwap = PERCENTAGE_120_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const derivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        let calculationTimestamp = derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );

        await openSwapPayFixed(testData, derivativeParams);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueAfterOpenSwap,
                derivativeParams.openTimestamp
            );
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(derivativeParams.asset, PERCENTAGE_6_18DEC, calculationTimestamp);

        const expectedSoap = BigNumber.from("7918994164764269327487");

        //when
        //then
        const soapParams = {
            asset: tokenDai.address,
            calculateTimestamp: calculationTimestamp,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(testData, soapParams);
    });

    it("should calculate soap, USDT add pay fixed, change ibtPrice, wait 25 days and then calculate soap, 6 decimals", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            testData
        );

        const { iporOracle, tokenUsdt, josephUsdt } = testData;

        if (tokenUsdt === undefined || josephUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        const openerUser = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const iporValueAfterOpenSwap = PERCENTAGE_120_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeParams = {
            asset: tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            acceptableFixedInterestRate: BigNumber.from("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const calculationTimestamp = derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, derivativeParams.openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );

        await openSwapPayFixed(testData, derivativeParams);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueAfterOpenSwap,
                derivativeParams.openTimestamp
            );
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(derivativeParams.asset, PERCENTAGE_6_6DEC, calculationTimestamp);

        const expectedSoap = BigNumber.from("7918994164764269327487");

        //when
        //then
        const soapParams = {
            asset: tokenUsdt.address,
            calculateTimestamp: calculationTimestamp,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(testData, soapParams);
    });

    it("should calculate soap, DAI add pay fixed, change ibtPrice, calculate soap after 28 days and after 50 days and compare", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const openerUser = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const iporValueAfterOpenSwap = PERCENTAGE_120_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        let calculationTimestamp25days =
            derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        let calculationTimestamp28days =
            derivativeParams.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);
        let calculationTimestamp50days =
            derivativeParams.openTimestamp.add(PERIOD_50_DAYS_IN_SECONDS);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParams);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueAfterOpenSwap,
                derivativeParams.openTimestamp
            );
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(derivativeParams.asset, PERCENTAGE_6_18DEC, calculationTimestamp25days);

        const expectedSoap28Days = BigNumber.from("7935378290622402313573");
        const expectedSoap50Days = BigNumber.from("8055528546915377478426");

        //when
        //then
        const soapParams28days = {
            asset: tokenDai.address,
            calculateTimestamp: calculationTimestamp28days,
            expectedSoap: expectedSoap28Days,
            from: userTwo,
        };
        await assertSoap(testData, soapParams28days);

        const soapParams50days = {
            asset: tokenDai.address,
            calculateTimestamp: calculationTimestamp50days,
            expectedSoap: expectedSoap50Days,
            from: userTwo,
        };
        await assertSoap(testData, soapParams50days);
    });

    it("should calculate soap, DAI add pay fixed, wait 25 days, DAI add pay fixed, wait 25 days and then calculate soap", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const openerUser = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeParamsFirst = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        const derivativeParams25days = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            from: openerUser,
        };
        const calculationTimestamp50days =
            derivativeParams25days.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigNumber.from(2).mul(USD_28_000_18DEC),
                derivativeParamsFirst.openTimestamp
            );

        //when
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                derivativeParamsFirst.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParamsFirst);
        await openSwapPayFixed(testData, derivativeParams25days);

        //then
        const expectedSoap = BigNumber.from("-205221535441070939561");

        const soapParams = {
            asset: tokenDai.address,
            calculateTimestamp: calculationTimestamp50days,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(testData, soapParams);
    });

    it("should calculate soap, DAI add pay fixed, wait 25 days, update IPOR and DAI add pay fixed, wait 25 days update IPOR and then calculate soap", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const openerUser = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeParamsFirst = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        const derivativeParams25days = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            from: openerUser,
        };
        let calculationTimestamp50days =
            derivativeParams25days.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from(2).mul(USD_28_000_18DEC), openTimestamp);

        //when
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                derivativeParamsFirst.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParamsFirst);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                derivativeParams25days.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParams25days);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                calculationTimestamp50days
            );

        //then
        const expectedSoap = BigNumber.from("-205221535441070939561");

        const soapParams = {
            asset: tokenDai.address,
            calculateTimestamp: calculationTimestamp50days,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(testData, soapParams);
    });

    it("should calculate EXACTLY the same SOAP with and without update IPOR Index with the same indexValue, DAI add pay fixed, 25 and 50 days period", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const openerUser = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const calculationTimestamp25days =
            derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        const calculationTimestamp50days =
            derivativeParams.openTimestamp.add(PERIOD_50_DAYS_IN_SECONDS);

        const soapParams = {
            asset: tokenDai.address,
            calculateTimestamp: calculationTimestamp50days,
            from: userTwo,
        };

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, openTimestamp);

        //when
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParams);

        const soapBeforeUpdateIndexStruct = await calculateSoap(testData, soapParams);
        const soapBeforeUpdateIndex = soapBeforeUpdateIndexStruct?.soap || ZERO;

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                calculationTimestamp25days
            );
        const soapUpdateIndexAfter25DaysStruct = await calculateSoap(testData, soapParams);
        const soapUpdateIndexAfter25Days = soapUpdateIndexAfter25DaysStruct?.soap || ZERO;

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                calculationTimestamp50days
            );
        const soapUpdateIndexAfter50DaysStruct = await calculateSoap(testData, soapParams);
        const soapUpdateIndexAfter50Days = soapUpdateIndexAfter50DaysStruct?.soap || ZERO;

        //then
        const expectedSoap = BigNumber.from("-136534382151108133189");

        expect(
            expectedSoap,
            `Incorrect SOAP before update index for asset ${soapParams.asset} actual: ${soapBeforeUpdateIndex}, expected: ${expectedSoap}`
        ).to.be.eq(soapBeforeUpdateIndex);
        expect(
            expectedSoap,
            `Incorrect SOAP update index after 25 days for asset ${soapParams.asset} actual: ${soapUpdateIndexAfter25Days}, expected: ${expectedSoap}`
        ).to.be.eq(soapUpdateIndexAfter25Days);
        expect(
            expectedSoap,
            `Incorrect SOAP update index after 50 days for asset ${soapParams.asset} actual: ${soapUpdateIndexAfter50Days}, expected: ${expectedSoap}`
        ).to.be.eq(soapUpdateIndexAfter50Days);
    });

    it("should calculate NEGATIVE SOAP, DAI add pay fixed, wait 25 days, update ibtPrice after swap opened, soap should be negative right after opened position and updated ibtPrice", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const openerUser = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const iporValueAfterOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const firstUpdateIndexTimestamp = openTimestamp;
        const secondUpdateIndexTimestamp = firstUpdateIndexTimestamp.add(PERIOD_1_DAY_IN_SECONDS);

        const derivativeParamsFirst = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: secondUpdateIndexTimestamp,
            from: openerUser,
        };

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, openTimestamp);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                firstUpdateIndexTimestamp
            );
        await openSwapPayFixed(testData, derivativeParamsFirst);

        //when
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueAfterOpenSwap,
                secondUpdateIndexTimestamp
            );

        let rightAfterOpenedPositionTimestamp = secondUpdateIndexTimestamp.add(
            BigNumber.from("100")
        );

        const soapParams = {
            asset: tokenDai.address,
            calculateTimestamp: rightAfterOpenedPositionTimestamp,
            expectedSoap: ZERO,
            from: userTwo,
        };
        const actualSoapStruct = await calculateSoap(testData, soapParams);
        const actualSoap = actualSoapStruct?.soap || ZERO;

        //then
        expect(actualSoap).to.be.below(
            0,
            `SOAP is positive but should be negative, actual: ${actualSoap}`
        );
    });
});
