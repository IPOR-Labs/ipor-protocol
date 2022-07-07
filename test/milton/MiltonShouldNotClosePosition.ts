import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { MockSpreadModel } from "../../types";
import {
    ZERO,
    USD_10_18DEC,
    USD_28_000_18DEC,
    PERCENTAGE_3_18DEC,
    PERIOD_25_DAYS_IN_SECONDS,
    LEVERAGE_18DEC,
    N0__1_18DEC,
    N0__01_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    PERCENTAGE_160_18DEC,
    PERCENTAGE_5_18DEC,
    PERCENTAGE_120_18DEC,
    PERCENTAGE_121_18DEC,
    PERIOD_50_DAYS_IN_SECONDS,
    PERCENTAGE_6_18DEC,
    PERIOD_27_DAYS_17_HOURS_IN_SECONDS,
	USD_1_000_000_18DEC,
    USD_10_000_000_18DEC,
    LEG_PAY_FIXED,
    LEG_RECEIVE_FIXED,
} from "../utils/Constants";
import {
    prepareMockSpreadModel,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
} from "../utils/MiltonUtils";
import {
    openSwapPayFixed,
    openSwapReceiveFixed,
    executeCloseSwapsTestCase,
} from "../utils/SwapUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

import {
    prepareComplexTestDataDaiCase000,
    prepareTestDataDaiCase000,
    prepareApproveForUsers,
    prepareTestData,
    setupTokenDaiInitialValuesForUsers,
} from "../utils/DataUtils";
import { assertError } from "../utils/AssertUtils";

const { expect } = chai;

describe("Milton - not close position", () => {
    let miltonSpreadModel: MockSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockSpreadModel(ZERO, ZERO, ZERO, ZERO);
    });

    it("should NOT close position, DAI, not owner, pay fixed, Milton lost, User earned < Collateral, before maturity", async () => {
        //given
        miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        await openSwapPayFixed(testData, params);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        const endTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            miltonDai.connect(userThree).itfCloseSwapPayFixed(1, endTimestamp),
            //then
            "IPOR_321"
        );
    });

    it("should NOT close position, DAI, not owner, pay fixed, Milton lost, User earned < Collateral, 7 hours before maturity", async () => {
        //given
        miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        await openSwapPayFixed(testData, params);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        const endTimestamp = params.openTimestamp.add(PERIOD_27_DAYS_17_HOURS_IN_SECONDS);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            miltonDai.connect(userThree).itfCloseSwapPayFixed(1, endTimestamp),
            //then
            "IPOR_321"
        );
    });

    it("should NOT close position, DAI, not owner, pay fixed, Milton earned, User lost < Collateral, before maturity", async () => {
        //given
        miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("121").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_120_18DEC
        );

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: PERCENTAGE_121_18DEC,
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        await openSwapPayFixed(testData, params);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        const endTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            miltonDai.connect(userThree).itfCloseSwapPayFixed(1, endTimestamp),
            //then
            "IPOR_321"
        );
    });

    it("should NOT close position, DAI, not owner, receive fixed, Milton lost, User earned < Collateral, before maturity", async () => {
        //given
        miltonSpreadModel.setCalculateQuoteReceiveFixed(BigNumber.from("119").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_120_18DEC
        );

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: N0__01_18DEC,
            leverage: USD_10_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        await openSwapReceiveFixed(testData, params);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        const endTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            miltonDai.connect(userThree).itfCloseSwapReceiveFixed(1, endTimestamp),
            //then
            "IPOR_321"
        );
    });

    it("should NOT close position, DAI, not owner, receive fixed, Milton lost, User earned < Collateral, 7 hours before maturity", async () => {
        //given
        miltonSpreadModel.setCalculateQuoteReceiveFixed(BigNumber.from("119").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_120_18DEC
        );

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: N0__01_18DEC,
            leverage: USD_10_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        await openSwapReceiveFixed(testData, params);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        const endTimestamp = params.openTimestamp.add(PERIOD_27_DAYS_17_HOURS_IN_SECONDS);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            miltonDai.connect(userThree).itfCloseSwapReceiveFixed(1, endTimestamp),
            //then
            "IPOR_321"
        );
    });

    it("should NOT close position, DAI, not owner, receive fixed, Milton earned, User lost < Collateral, before maturity", async () => {
        //given
        miltonSpreadModel.setCalculateQuoteReceiveFixed(BigNumber.from("4").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: N0__01_18DEC,
            leverage: USD_10_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        await openSwapReceiveFixed(testData, params);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        const endTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            miltonDai.connect(userThree).itfCloseSwapReceiveFixed(1, endTimestamp),
            //then
            "IPOR_321"
        );
    });

    it("should NOT close position, because incorrect swap Id", async () => {
        //given
        miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("4").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const openerUser = userTwo;
        const closerUser = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeParamsFirst = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                derivativeParamsFirst.openTimestamp
            );
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParamsFirst.openTimestamp);
        await openSwapPayFixed(testData, derivativeParamsFirst);

        await assertError(
            //when
            miltonDai
                .connect(closerUser)
                .itfCloseSwapPayFixed(0, openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS)),
            //then
            "IPOR_306"
        );
    });

    it("should NOT close position, because swap has incorrect status - pay fixed", async () => {
        //given
        miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("4").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const openerUser = userTwo;
        const closerUser = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeParamsFirst = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                derivativeParamsFirst.openTimestamp
            );
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_28_000_18DEC.add(USD_28_000_18DEC),
                derivativeParamsFirst.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParamsFirst);

        const derivativeParams25days = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            from: openerUser,
        };
        await openSwapPayFixed(testData, derivativeParams25days);

        const endTimestamp = openTimestamp.add(PERIOD_50_DAYS_IN_SECONDS);

        await miltonDai.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp);

        await assertError(
            //when
            miltonDai.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp),
            //then
            "IPOR_307"
        );
    });

    it("should NOT close position, because swap has incorrect status - receive fixed", async () => {
        //given
        miltonSpreadModel.setCalculateQuoteReceiveFixed(BigNumber.from("2").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const openerUser = userTwo;
        const closerUser = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeParamsFirst = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: N0__01_18DEC,
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                derivativeParamsFirst.openTimestamp
            );
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_28_000_18DEC.add(USD_28_000_18DEC),
                derivativeParamsFirst.openTimestamp
            );
        await openSwapReceiveFixed(testData, derivativeParamsFirst);

        const derivativeParams25days = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: N0__01_18DEC,
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            from: openerUser,
        };
        await openSwapReceiveFixed(testData, derivativeParams25days);

        const endTimestamp = openTimestamp.add(PERIOD_50_DAYS_IN_SECONDS);

        await miltonDai.connect(closerUser).itfCloseSwapReceiveFixed(1, endTimestamp);

        await assertError(
            //when
            miltonDai.connect(closerUser).itfCloseSwapReceiveFixed(1, endTimestamp),
            //then
            "IPOR_307"
        );
    });

    it("should NOT close position, because swap not exists", async () => {
        //given
        const { miltonDai } = await prepareTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );

        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const closerUser = userTwo;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        await assertError(
            //when
            miltonDai
                .connect(closerUser)
                .itfCloseSwapPayFixed(0, openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS)),
            //then
            "IPOR_306"
        );
    });

    it("should NOT close position, pay fixed, single id function, DAI, when contract is paused", async () => {
        miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE3,
            MiltonUsdtCase.CASE3,
            MiltonDaiCase.CASE3,
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

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            executeCloseSwapsTestCase(
                testData,
                tokenDai.address,
                USD_10_18DEC,
                LEG_PAY_FIXED,
                userTwo,
                userTwo,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_1_000_000_18DEC,
                BigNumber.from("1"),
                async (contract) => {
                    return contract.closeSwapPayFixed(1);
                },
                ZERO,
                true,
                admin,
                userOne,
                liquidityProvider
            ),
            "Pausable: paused"
        );
    });

    it("should NOT close position, pay fixed, multiple ids function, DAI, when contract is paused", async () => {
        miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE3,
            MiltonUsdtCase.CASE3,
            MiltonDaiCase.CASE3,
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

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            executeCloseSwapsTestCase(
                testData,
                tokenDai.address,
                USD_10_18DEC,
                LEG_PAY_FIXED,
                userTwo,
                userTwo,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_1_000_000_18DEC,
                BigNumber.from("1"),
                async (contract) => {
                    return contract.closeSwaps([1], []);
                },
                ZERO,
                true,
                admin,
                userOne,
                liquidityProvider
            ),
            "Pausable: paused"
        );
    });

    it("should NOT close position, receive fixed, single id function, DAI, when contract is paused", async () => {
        miltonSpreadModel.setCalculateQuoteReceiveFixed(BigNumber.from("4").mul(N0__01_18DEC));
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE3,
            MiltonUsdtCase.CASE3,
            MiltonDaiCase.CASE3,
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

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await assertError(
            executeCloseSwapsTestCase(
                testData,
                tokenDai.address,
                USD_10_18DEC,
                LEG_RECEIVE_FIXED,
                userTwo,
                userTwo,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_1_000_000_18DEC,
                BigNumber.from("1"),
                async (contract) => {
                    return contract.closeSwapReceiveFixed(1);
                },
                ZERO,
                true,
                admin,
                userOne,
                liquidityProvider
            ),
            "Pausable: paused"
        );
    });

    it("should NOT close position, receive fixed, multiple ids function, DAI, when contract is paused", async () => {
        miltonSpreadModel.setCalculateQuoteReceiveFixed(BigNumber.from("4").mul(N0__01_18DEC));
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE3,
            MiltonUsdtCase.CASE3,
            MiltonDaiCase.CASE3,
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

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await assertError(
            executeCloseSwapsTestCase(
                testData,
                tokenDai.address,
                USD_10_18DEC,
                LEG_RECEIVE_FIXED,
                userTwo,
                userTwo,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_1_000_000_18DEC,
                BigNumber.from("1"),
                async (contract) => {
                    return contract.closeSwaps([], [1]);
                },
                ZERO,
                true,
                admin,
                userOne,
                liquidityProvider
            ),
            "Pausable: paused"
        );
    });

    it("should NOT close position, pay fixed, multiple ids emergency function, DAI, when contract is paused", async () => {
        miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE3,
            MiltonUsdtCase.CASE3,
            MiltonDaiCase.CASE3,
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

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await assertError(
            executeCloseSwapsTestCase(
                testData,
                tokenDai.address,
                USD_10_18DEC,
                LEG_PAY_FIXED,
                userTwo,
                userTwo,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_1_000_000_18DEC,
                BigNumber.from("1"),
                async (contract) => {
                    return contract.emergencyCloseSwapsPayFixed([1]);
                },
                ZERO,
                true,
                admin,
                userOne,
                liquidityProvider
            ),
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT close position, pay fixed, single id emergency function, DAI, when contract is paused", async () => {
        miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE3,
            MiltonUsdtCase.CASE3,
            MiltonDaiCase.CASE3,
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

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await assertError(
            executeCloseSwapsTestCase(
                testData,
                tokenDai.address,
                USD_10_18DEC,
                LEG_PAY_FIXED,
                userTwo,
                userTwo,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_1_000_000_18DEC,
                BigNumber.from("1"),
                async (contract) => {
                    return contract.emergencyCloseSwapPayFixed(1);
                },
                ZERO,
                true,
                admin,
                userOne,
                liquidityProvider
            ),
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT close position, receive fixed, multiple ids emergency function, DAI, when contract is paused", async () => {
        miltonSpreadModel.setCalculateQuoteReceiveFixed(BigNumber.from("4").mul(N0__01_18DEC));
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE3,
            MiltonUsdtCase.CASE3,
            MiltonDaiCase.CASE3,
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
        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await assertError(
            executeCloseSwapsTestCase(
                testData,
                tokenDai.address,
                USD_10_18DEC,
                LEG_RECEIVE_FIXED,
                userTwo,
                userTwo,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_1_000_000_18DEC,
                BigNumber.from("1"),
                async (contract) => {
                    return contract.emergencyCloseSwapsReceiveFixed([1]);
                },
                ZERO,
                true,
                admin,
                userOne,
                liquidityProvider
            ),
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT close position, receive fixed, single id emergency function, DAI, when contract is paused", async () => {
        miltonSpreadModel.setCalculateQuoteReceiveFixed(BigNumber.from("4").mul(N0__01_18DEC));
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE3,
            MiltonUsdtCase.CASE3,
            MiltonDaiCase.CASE3,
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

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await assertError(
            executeCloseSwapsTestCase(
                testData,
                tokenDai.address,
                USD_10_18DEC,
                LEG_RECEIVE_FIXED,
                userTwo,
                userTwo,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_1_000_000_18DEC,
                BigNumber.from("1"),
                async (contract) => {
                    return contract.emergencyCloseSwapReceiveFixed(1);
                },
                ZERO,
                true,
                admin,
                userOne,
                liquidityProvider
            ),
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT close position by owner, pay fixed, multiple ids emergency function, DAI, when contract is not paused", async () => {
        miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE3,
            MiltonUsdtCase.CASE3,
            MiltonDaiCase.CASE3,
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

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            executeCloseSwapsTestCase(
                testData,
                tokenDai.address,
                USD_10_18DEC,
                LEG_PAY_FIXED,
                userTwo,
                admin,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_1_000_000_18DEC,
                BigNumber.from("1"),
                async (contract) => {
                    return contract.emergencyCloseSwapsPayFixed([1]);
                },
                ZERO,
                false,
                admin,
                userOne,
                liquidityProvider
            ),
            "Pausable: not paused"
        );
    });

    it("should NOT close position by owner, pay fixed, single id emergency function, DAI, when contract is not paused", async () => {
        miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE3,
            MiltonUsdtCase.CASE3,
            MiltonDaiCase.CASE3,
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

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await assertError(
            executeCloseSwapsTestCase(
                testData,
                tokenDai.address,
                USD_10_18DEC,
                LEG_PAY_FIXED,
                userTwo,
                admin,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_1_000_000_18DEC,
                BigNumber.from("1"),
                async (contract) => {
                    return contract.emergencyCloseSwapPayFixed(1);
                },
                ZERO,
                false,
                admin,
                userOne,
                liquidityProvider
            ),
            "Pausable: not paused"
        );
    });

    it("should NOT close position by owner, receive fixed, multiple ids emergency function, DAI, when contract is not paused", async () => {
        miltonSpreadModel.setCalculateQuoteReceiveFixed(BigNumber.from("4").mul(N0__01_18DEC));
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE3,
            MiltonUsdtCase.CASE3,
            MiltonDaiCase.CASE3,
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

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await assertError(
            executeCloseSwapsTestCase(
                testData,
                tokenDai.address,
                USD_10_18DEC,
                LEG_RECEIVE_FIXED,
                userTwo,
                admin,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_1_000_000_18DEC,
                BigNumber.from("1"),
                async (contract) => {
                    return contract.emergencyCloseSwapsReceiveFixed([1]);
                },
                ZERO,
                false,
                admin,
                userOne,
                liquidityProvider
            ),
            "Pausable: not paused"
        );
    });

    it("should NOT close position by owner, receive fixed, single id emergency function, DAI, when contract is not paused", async () => {
        miltonSpreadModel.setCalculateQuoteReceiveFixed(BigNumber.from("4").mul(N0__01_18DEC));
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE3,
            MiltonUsdtCase.CASE3,
            MiltonDaiCase.CASE3,
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

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            executeCloseSwapsTestCase(
                testData,
                tokenDai.address,
                USD_10_18DEC,
                LEG_RECEIVE_FIXED,
                userTwo,
                admin,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_1_000_000_18DEC,
                BigNumber.from("1"),
                async (contract) => {
                    return contract.emergencyCloseSwapReceiveFixed(1);
                },
                ZERO,
                false,
                admin,
                userOne,
                liquidityProvider
            ),
            "Pausable: not paused"
        );
    });

    it("should NOT close position, DAI, when ERC20: amount exceeds balance milton on DAI token", async () => {
        //given
        miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai, josephDai, iporOracle, miltonDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        await openSwapPayFixed(testData, params);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        const endTimestamp = params.openTimestamp.add(PERIOD_27_DAYS_17_HOURS_IN_SECONDS);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        // await miltonDai.connect(userTwo).itfCloseSwapPayFixed(1, endTimestamp);
        await hre.network.provider.send("hardhat_setBalance", [
            miltonDai.address,
            "0x500000000000000000000",
        ]);
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [miltonDai.address],
        });
        const signer = await hre.ethers.provider.getSigner(miltonDai.address);
        const daiBalanceAfterOpen = await tokenDai.balanceOf(miltonDai.address);
        await tokenDai.connect(signer).transfer(await admin.getAddress(), daiBalanceAfterOpen);

        //when
        await assertError(
            //when
            miltonDai.connect(userTwo).itfCloseSwapPayFixed(1, endTimestamp),
            //then
            "ERC20: transfer amount exceeds balance"
        );
    });
});
