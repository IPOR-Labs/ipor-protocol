import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
import { MockSpreadModel } from "../../types";
import {
    ZERO,
    USD_28_000_18DEC,
    USD_50_000_18DEC,
    PERCENTAGE_3_18DEC,
    N0__01_18DEC,
    TC_COLLATERAL_18DEC,
    USD_10_18DEC,
    LEG_PAY_FIXED,
    PERCENTAGE_151_18DEC,
    PERIOD_25_DAYS_IN_SECONDS,
    USER_SUPPLY_10MLN_18DEC,
    PERCENTAGE_160_18DEC,
    PERCENTAGE_5_18DEC,
    PERIOD_28_DAYS_IN_SECONDS,
    PERCENTAGE_150_18DEC,
    PERCENTAGE_6_18DEC,
    LEG_RECEIVE_FIXED,
    TC_INCOME_TAX_18DEC,
    PERIOD_50_DAYS_IN_SECONDS,
    PERCENTAGE_120_18DEC,
    PERCENTAGE_50_18DEC,
    SPECIFIC_INCOME_TAX_CASE_1,
    SPECIFIC_INTEREST_AMOUNT_CASE_1,
    PERIOD_27_DAYS_19_HOURS_IN_SECONDS,
    USD_10_000_18DEC,
    LEVERAGE_18DEC,
    PERIOD_14_DAYS_IN_SECONDS,
} from "../utils/Constants";
import {
    prepareMockSpreadModel,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,testCaseWhenMiltonLostAndUserEarn, testCaseWhenMiltonEarnAndUserLost
} from "../utils/MiltonUtils";
import {
    openSwapPayFixed,
    openSwapReceiveFixed,
} from "../utils/SwapUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

import {
    prepareComplexTestDataDaiCase000,
    getPayFixedDerivativeParamsDAICase1,
    getReceiveFixedDerivativeParamsDAICase1,
    prepareApproveForUsers,
    prepareTestData,
    setupTokenDaiInitialValuesForUsers,
} from "../utils/DataUtils";
import { assertError } from "../utils/AssertUtils";
import { beforeEach } from 'mocha'

const { expect } = chai;

describe("ItfLiquidator - close position (liquidate)", () => {
    let miltonSpreadModel: MockSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockSpreadModel(
            BigNumber.from("6").mul(N0__01_18DEC),
            BigNumber.from("4").mul(N0__01_18DEC),
            ZERO,
            ZERO
        );
    });

    it("Should deploy contract", async () => {
        const ItfLiquidator = await hre.ethers.getContractFactory("ItfLiquidator")
        const itfLiquidator = await ItfLiquidator.deploy(userOne.getAddress(), userTwo.getAddress())
        // assert deployed
        expect(await itfLiquidator.deployed()).to.be.not.null;
    });
        

    it("should emit CloseSwap event - pay fixed", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );
        const { tokenDai, josephDai, miltonDai, iporOracle, miltonStorageDai } = testData;


        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const ItfLiquidator = await hre.ethers.getContractFactory("ItfLiquidator")
        const itfLiquidator = await ItfLiquidator.deploy(miltonDai?.address, miltonStorageDai?.address)
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_50_000_18DEC, params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.acceptableFixedInterestRate,
                params.leverage
            );

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.acceptableFixedInterestRate,
                params.leverage
            );

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_160_18DEC, params.openTimestamp);

        const closeTimestamp = params.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS)

        // when
        await expect(
            itfLiquidator.itfLiquidate([1, 2], [], closeTimestamp)
        )
        //then
        .to.emit(miltonDai, "CloseSwap").withArgs(anyValue, anyValue, anyValue, anyValue, anyValue, anyValue, anyValue)
        .to.emit(miltonDai, "CloseSwap").withArgs(anyValue, anyValue, anyValue, anyValue, anyValue, anyValue, anyValue)
    });


    it("should emit CloseSwap event - receive fixed", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai, josephDai, miltonDai, iporOracle, miltonStorageDai } = testData;

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        const ItfLiquidator = await hre.ethers.getContractFactory("ItfLiquidator")
        const itfLiquidator = await ItfLiquidator.deploy(miltonDai?.address, miltonStorageDai?.address)

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_50_000_18DEC, params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                params.totalAmount,
                params.acceptableFixedInterestRate,
                params.leverage
            );

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                params.totalAmount,
                params.acceptableFixedInterestRate,
                params.leverage
            );

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_160_18DEC, params.openTimestamp);
        
        // when
        await expect(
            itfLiquidator
                .itfLiquidate([], [1, 2], params.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS))
        )
        //then
        .to.emit(miltonDai, "CloseSwap").withArgs(anyValue, anyValue, anyValue, anyValue, anyValue, anyValue, anyValue)
        .to.emit(miltonDai, "CloseSwap").withArgs(anyValue, anyValue, anyValue, anyValue, anyValue, anyValue, anyValue)
    });

    it("should close 10 pay fixed, 10 receive fixed positions in one transaction - case 1, all are opened", async () => {
        //given
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

        const { tokenDai, josephDai, iporOracle, miltonDai, miltonStorageDai } = testData;
        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        const ItfLiquidator = await hre.ethers.getContractFactory("ItfLiquidator")
        const itfLiquidator = await ItfLiquidator.deploy(miltonDai?.address, miltonStorageDai?.address)

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const volumePayFixed = 10;
        const volumeReceiveFixed = 10;

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(
            volumePayFixed + volumeReceiveFixed
        );

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        const swapIdsPayFixed = [];
        const swapIdsReceiveFixed = [];

        for (let i = 0; i < volumePayFixed; i++) {
            await openSwapPayFixed(testData, paramsPayFixed);
            swapIdsPayFixed.push(i + 1);
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await openSwapReceiveFixed(testData, paramsReceiveFixed);
            swapIdsReceiveFixed.push(i + 1);
        }

        const expectedSwapStatus = 0;

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);

        //when
        await itfLiquidator
            .itfLiquidate(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp);

        //then
        for (let i = 0; i < volumePayFixed; i++) {
            const swapPayFixed = await miltonStorageDai.getSwapPayFixed(i + 1);
            expect(expectedSwapStatus, `Incorrect swap status for swapId=${i + 1}`).to.be.eq(
                swapPayFixed.state
            );
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            const swapReceiveFixed = await miltonStorageDai.getSwapReceiveFixed(i + 1);
            expect(expectedSwapStatus, `Incorrect swap status for swapId=${i + 1}`).to.be.eq(
                swapReceiveFixed.state
            );
        }
    });
    
    it("should close 10 (5 already opened) pay fixed, 10 receive fixed (5 already opened) positions in one transaction - case 2, some of them are already closed and some expired", async () => {
        //given
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

        const { tokenDai, josephDai, iporOracle, miltonDai, miltonStorageDai } = testData;
        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        const paramsPayFixedOpenedLater = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsPayFixedOpenedLater.openTimestamp = paramsPayFixedOpenedLater.openTimestamp.add(PERIOD_14_DAYS_IN_SECONDS)
        const paramsReceiveFixedOpenedLater = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixedOpenedLater.openTimestamp = paramsReceiveFixedOpenedLater.openTimestamp.add(PERIOD_14_DAYS_IN_SECONDS)

        const ItfLiquidator = await hre.ethers.getContractFactory("ItfLiquidator")
        const itfLiquidator = await ItfLiquidator.deploy(miltonDai?.address, miltonStorageDai?.address)

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const volumePayFixed = 5;
        const volumePayFixedOpenedLater = 5;
        const volumeReceiveFixed = 5;
        const volumeReceiveFixedOpenedLater = 5;

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(
            volumePayFixed + volumeReceiveFixed
        );

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        const swapIdsPayFixed = [];
        const swapIdsReceiveFixed = [];

        for (let i = 0; i < volumePayFixed; i++) {
            await openSwapPayFixed(testData, paramsPayFixed);
            swapIdsPayFixed.push(i + 1);
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await openSwapReceiveFixed(testData, paramsReceiveFixed);
            swapIdsReceiveFixed.push(i + 1);
        }

        for (let i = volumePayFixed + volumeReceiveFixed; i < volumePayFixed + volumeReceiveFixed + volumePayFixedOpenedLater; i++) {
            await openSwapPayFixed(testData, paramsPayFixedOpenedLater);
            swapIdsPayFixed.push(i + 1);
        }

        for (let i = volumePayFixed + volumeReceiveFixed + volumePayFixedOpenedLater; i < volumePayFixed + volumeReceiveFixed + volumePayFixedOpenedLater + volumeReceiveFixedOpenedLater; i++) {
            await openSwapReceiveFixed(testData, paramsReceiveFixedOpenedLater);
            swapIdsReceiveFixed.push(i + 1);
        }

        const expectedSwapStatus = 0;
        const expectedSwapStatusForOpenedLater = 1;

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);

        //when
        await itfLiquidator
            .itfLiquidate(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp);

        //then
        for (let i = 0; i < volumePayFixed; i++) {
            const swapPayFixed = await miltonStorageDai.getSwapPayFixed(i + 1);
            expect(expectedSwapStatus, `Incorrect swap status for swapId=${i + 1}`).to.be.eq(
                swapPayFixed.state
            );
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            const swapReceiveFixed = await miltonStorageDai.getSwapReceiveFixed(i + 1);
            expect(expectedSwapStatus, `Incorrect swap status for swapId=${i + 1}`).to.be.eq(
                swapReceiveFixed.state
            );
        }

        for (let i = volumePayFixed + volumeReceiveFixed; i < volumePayFixed + volumeReceiveFixed + volumePayFixedOpenedLater; i++) {
            const swapPayFixed = await miltonStorageDai.getSwapPayFixed(i + 1);
            expect(expectedSwapStatusForOpenedLater, `Incorrect swap status for swapId=${i + 1}`).to.be.eq(
                swapPayFixed.state
            );
        }

        for (let i = volumePayFixed + volumeReceiveFixed + volumePayFixedOpenedLater; i < volumePayFixed + volumeReceiveFixed + volumePayFixedOpenedLater + volumeReceiveFixedOpenedLater; i++) {
            const swapReceiveFixed = await miltonStorageDai.getSwapReceiveFixed(i + 1);
            expect(expectedSwapStatusForOpenedLater, `Incorrect swap status for swapId=${i + 1}`).to.be.eq(
                swapReceiveFixed.state
            );
        }

    });

    it("should close 5 pay fixed, 5 receive fixed positions in one transaction - case 2, some of them are already closed", async () => {
        //given
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

        const { tokenDai, josephDai, iporOracle, miltonDai, miltonStorageDai } = testData;
        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        const ItfLiquidator = await hre.ethers.getContractFactory("ItfLiquidator")
        const itfLiquidator = await ItfLiquidator.deploy(miltonDai?.address, miltonStorageDai?.address)

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const volumePayFixed = 5;
        const volumeReceiveFixed = 5;

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(
            volumePayFixed + volumeReceiveFixed
        );

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        const swapIdsPayFixed = [];
        const swapIdsReceiveFixed = [];

        for (let i = 0; i < volumePayFixed; i++) {
            await openSwapPayFixed(testData, paramsPayFixed);
            swapIdsPayFixed.push(i + 1);
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await openSwapReceiveFixed(testData, paramsReceiveFixed);
            swapIdsReceiveFixed.push(i + 1);
        }

        const expectedSwapStatus = 0;

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);

        await miltonDai.connect(paramsPayFixed.from).itfCloseSwapPayFixed(3, closeTimestamp);
        await miltonDai.connect(paramsPayFixed.from).itfCloseSwapReceiveFixed(8, closeTimestamp);

        //when
        await itfLiquidator
            .itfLiquidate(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp);

        //then
        for (let i = 0; i < volumePayFixed; i++) {
            const swapPayFixed = await miltonStorageDai.getSwapPayFixed(i + 1);
            expect(expectedSwapStatus, `Incorrect swap status for swapId=${i + 1}`).to.be.eq(
                swapPayFixed.state
            );
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            const swapReceiveFixed = await miltonStorageDai.getSwapReceiveFixed(i + 1);
            expect(expectedSwapStatus, `Incorrect swap status for swapId=${i + 1}`).to.be.eq(
                swapReceiveFixed.state
            );
        }

        const closedSwapPayFixed = await miltonStorageDai.getSwapPayFixed(3);
        expect(0, `Incorrect swap status for swapId=3`).to.be.eq(closedSwapPayFixed.state);

        const closedSwapReceiveFixed = await miltonStorageDai.getSwapReceiveFixed(8);
        expect(0, `Incorrect swap status for swapId=8`).to.be.eq(closedSwapReceiveFixed.state);
    });

    it("should close 10 pay fixed, 10 receive fixed positions in one transaction - liquidation deposit amount not transferred to liquidator", async () => {
        //given
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

        const { tokenDai, josephDai, iporOracle, miltonDai, miltonStorageDai } = testData;
        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        const ItfLiquidator = await hre.ethers.getContractFactory("ItfLiquidator")
        const itfLiquidator = await ItfLiquidator.deploy(miltonDai?.address, miltonStorageDai?.address)

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const volumePayFixed = 10;
        const volumeReceiveFixed = 10;

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(
            volumePayFixed + volumeReceiveFixed
        );

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        const swapIdsPayFixed = [];
        const swapIdsReceiveFixed = [];

        for (let i = 0; i < volumePayFixed; i++) {
            await openSwapPayFixed(testData, paramsPayFixed);
            swapIdsPayFixed.push(i + 1);
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await openSwapReceiveFixed(testData, paramsReceiveFixed);
            swapIdsReceiveFixed.push(i + 1);
        }

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);

        const expectedBalanceTrader = BigNumber.from("9997046420320479199074790")
        const expectedBalanceLiquidator = USER_SUPPLY_10MLN_18DEC

        //when
        await itfLiquidator
            .itfLiquidate(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp);

        //then
        const actualBalanceLiquidator = await tokenDai.balanceOf(await userThree.getAddress());
        expect(expectedBalanceLiquidator, `Incorrect liquidator balance`).to.be.eq(
            actualBalanceLiquidator
        );

        const actualBalanceTrader = await tokenDai.balanceOf(
            await paramsPayFixed.from.getAddress()
        );
        expect(expectedBalanceTrader, `Incorrect trader balance`).to.be.eq(actualBalanceTrader);
    });

    it("should close 2 pay fixed, 0 receive fixed positions in one transaction - all receive fixed positions already closed", async () => {
        //given
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

        const { tokenDai, josephDai, iporOracle, miltonDai, miltonStorageDai } = testData;
        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        const ItfLiquidator = await hre.ethers.getContractFactory("ItfLiquidator")
        const itfLiquidator = await ItfLiquidator.deploy(miltonDai?.address, miltonStorageDai?.address)

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const volumePayFixed = 10;
        const volumeReceiveFixed = 10;

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(
            volumePayFixed + volumeReceiveFixed
        );

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        const swapIdsPayFixed = [];
        const swapIdsReceiveFixed = [];

        for (let i = 0; i < volumePayFixed; i++) {
            await openSwapPayFixed(testData, paramsPayFixed);
            swapIdsPayFixed.push(i + 1);
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await openSwapReceiveFixed(testData, paramsReceiveFixed);
            swapIdsReceiveFixed.push(i + 1);
        }

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);

        const expectedBalanceTrader = BigNumber.from("9997246420320479199074790")
        const expectedBalanceLiquidator = USER_SUPPLY_10MLN_18DEC

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await miltonDai
                .connect(paramsReceiveFixed.from)
                .itfCloseSwapReceiveFixed(i + 1, closeTimestamp);
        }

        //when
        await itfLiquidator
            .itfLiquidate(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp);

        //then
        const actualBalanceLiquidator = await tokenDai.balanceOf(await userThree.getAddress());
        expect(expectedBalanceLiquidator, `Incorrect liquidator balance`).to.be.eq(
            actualBalanceLiquidator
        );

        const actualBalanceTrader = await tokenDai.balanceOf(
            await paramsPayFixed.from.getAddress()
        );
        expect(expectedBalanceTrader, `Incorrect trader balance`).to.be.eq(actualBalanceTrader);
    });

    it("should close 0 pay fixed, 2 receive fixed positions in one transaction - all pay fixed positions already closed", async () => {
        //given
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

        const { tokenDai, josephDai, iporOracle, miltonDai, miltonStorageDai } = testData;
        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        const ItfLiquidator = await hre.ethers.getContractFactory("ItfLiquidator")
        const itfLiquidator = await ItfLiquidator.deploy(miltonDai?.address, miltonStorageDai?.address)

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const volumePayFixed = 10;
        const volumeReceiveFixed = 10;

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(
            volumePayFixed + volumeReceiveFixed
        );

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        const swapIdsPayFixed = [];
        const swapIdsReceiveFixed = [];

        for (let i = 0; i < volumePayFixed; i++) {
            await openSwapPayFixed(testData, paramsPayFixed);
            swapIdsPayFixed.push(i + 1);
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await openSwapReceiveFixed(testData, paramsReceiveFixed);
            swapIdsReceiveFixed.push(i + 1);
        }

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);

        const expectedBalanceTrader = BigNumber.from("9997246420320479199074790")
        const expectedBalanceLiquidator = USER_SUPPLY_10MLN_18DEC

        for (let i = 0; i < volumePayFixed; i++) {
            await miltonDai
                .connect(paramsPayFixed.from)
                .itfCloseSwapPayFixed(i + 1, closeTimestamp);
        }

        //when
        await itfLiquidator
            .itfLiquidate(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp);

        //then
        const actualBalanceLiquidator = await tokenDai.balanceOf(await userThree.getAddress());
        expect(expectedBalanceLiquidator, `Incorrect liquidator balance`).to.be.eq(
            actualBalanceLiquidator
        );

        const actualBalanceTrader = await tokenDai.balanceOf(
            await paramsPayFixed.from.getAddress()
        );
        expect(expectedBalanceTrader, `Incorrect trader balance`).to.be.eq(actualBalanceTrader);
    });

    it("should close 0 pay fixed, 2 receive fixed positions in one transaction - all pay fixed positions already closed", async () => {
        //given
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

        const { tokenDai, josephDai, iporOracle, miltonDai, miltonStorageDai } = testData;
        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        const ItfLiquidator = await hre.ethers.getContractFactory("ItfLiquidator")
        const itfLiquidator = await ItfLiquidator.deploy(miltonDai?.address, miltonStorageDai?.address)

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const volumePayFixed = 10;
        const volumeReceiveFixed = 10;

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(
            volumePayFixed + volumeReceiveFixed
        );

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        const swapIdsPayFixed = [];
        const swapIdsReceiveFixed = [];

        for (let i = 0; i < volumePayFixed; i++) {
            await openSwapPayFixed(testData, paramsPayFixed);
            swapIdsPayFixed.push(i + 1);
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await openSwapReceiveFixed(testData, paramsReceiveFixed);
            swapIdsReceiveFixed.push(i + 1);
        }

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);

        const expectedBalanceTrader = BigNumber.from("9997246420320479199074790")

        const expectedBalanceLiquidator = USER_SUPPLY_10MLN_18DEC

        for (let i = 0; i < volumePayFixed; i++) {
            await miltonDai
                .connect(paramsPayFixed.from)
                .itfCloseSwapPayFixed(i + 1, closeTimestamp);
        }

        //when
        await itfLiquidator
            .itfLiquidate(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp);

        //then
        const actualBalanceLiquidator = await tokenDai.balanceOf(await userThree.getAddress());
        expect(expectedBalanceLiquidator, `Incorrect liquidator balance`).to.be.eq(
            actualBalanceLiquidator
        );

        const actualBalanceTrader = await tokenDai.balanceOf(
            await paramsPayFixed.from.getAddress()
        );
        expect(expectedBalanceTrader, `Incorrect trader balance`).to.be.eq(actualBalanceTrader);
    });

    it("Should commit transaction try to close 2 pay fixed, 2 receive fixed positions in one transaction - all positions already closed", async () => {
        //given
        miltonSpreadModel.setCalculateQuoteReceiveFixed(BigNumber.from("4").mul(N0__01_18DEC));
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

        const { tokenDai, josephDai, iporOracle, miltonDai, miltonStorageDai } = testData;
        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        const ItfLiquidator = await hre.ethers.getContractFactory("ItfLiquidator")
        const itfLiquidator = await ItfLiquidator.deploy(miltonDai?.address, miltonStorageDai?.address)

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const volumePayFixed = 2;
        const volumeReceiveFixed = 2;

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(
            volumePayFixed + volumeReceiveFixed
        );

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        const swapIdsPayFixed = [];
        const swapIdsReceiveFixed = [];

        for (let i = 0; i < volumePayFixed; i++) {
            await openSwapPayFixed(testData, paramsPayFixed);
            swapIdsPayFixed.push(i + 1);
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await openSwapReceiveFixed(testData, paramsReceiveFixed);
            swapIdsReceiveFixed.push(i + 1);
        }

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);

        for (let i = 0; i < volumePayFixed; i++) {
            await miltonDai
                .connect(paramsPayFixed.from)
                .itfCloseSwapPayFixed(i + 1, closeTimestamp);
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await miltonDai
                .connect(paramsReceiveFixed.from)
                .itfCloseSwapReceiveFixed(i + 1, closeTimestamp);
        }

        const expectedBalanceTrader = BigNumber.from("9999489284064095839814958");

        const actualBalanceLiquidatorBefore = await tokenDai.balanceOf(
            await userThree.getAddress()
        );

        //when
        await itfLiquidator
            .itfLiquidate(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp);

        //then
        const actualBalanceLiquidatorAfter = await tokenDai.balanceOf(await userThree.getAddress());
        expect(actualBalanceLiquidatorBefore, `Incorrect liquidator balance`).to.be.eq(
            actualBalanceLiquidatorAfter
        );

        const actualBalanceTrader = await tokenDai.balanceOf(
            await paramsPayFixed.from.getAddress()
        );
        expect(expectedBalanceTrader, `Incorrect trader balance`).to.be.eq(actualBalanceTrader);
    });

    it("should commit transaction even if lists for closing are empty", async () => {
        //given
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

        const { miltonDai, miltonStorageDai } = testData;
        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const ItfLiquidator = await hre.ethers.getContractFactory("ItfLiquidator")
        const itfLiquidator = await ItfLiquidator.deploy(miltonDai?.address, miltonStorageDai?.address)

        const closeTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        //when
        const result = await itfLiquidator.itfLiquidate([], [], closeTimestamp);

        //then
        expect(result, `Incorrect transaction result`).to.be.not.undefined;
    });

    it("should close DAI position pay fixed, Liquidator lost, User earned > Collateral, before maturity", async () => {
        //given
        const quote = BigNumber.from("1").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC;
        const expectedPayoffWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            admin,
            PERCENTAGE_160_18DEC,
            acceptableFixedInterestRate,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should close DAI position pay fixed, Liquidator lost, 100% Collateral > User earned > 99% Collateral, before maturity", async () => {
        //given
        const quote = BigNumber.from("6").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeTaxValue = BigNumber.from("989874270595533665253");
        const expectedIncomeTaxValueWad = BigNumber.from("989874270595533665253");
        const expectedPayoff = BigNumber.from("9898742705955336652531");
        const expectedPayoffWad = BigNumber.from("9898742705955336652531");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            admin,
            PERCENTAGE_151_18DEC,
            acceptableFixedInterestRate,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            ZERO,
            expectedIncomeTaxValue,
            expectedIncomeTaxValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close DAI position receive fixed, Liquidator lost, User earned < Collateral, 5 hours before maturity", async () => {
        //given
        const quote = BigNumber.from("10").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_120_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeTaxValue = BigNumber.from("37945180372828793181");
        const expectedIncomeTaxValueWad = BigNumber.from("37945180372828793181");
        const expectedPayoff = BigNumber.from("379451803728287931809");
        const expectedPayoffWad = BigNumber.from("379451803728287931809");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            admin,
            PERCENTAGE_5_18DEC,
            acceptableFixedInterestRate,
            PERIOD_27_DAYS_19_HOURS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            ZERO,
            expectedIncomeTaxValue,
            expectedIncomeTaxValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close DAI position pay fixed, Liquidator lost, User earned > Collateral, after maturity", async () => {
        const quote = BigNumber.from("1").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        miltonSpreadModel.setCalculateQuotePayFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC;
        const expectedPayoffWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            admin,
            PERCENTAGE_160_18DEC,
            acceptableFixedInterestRate,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should close DAI position pay fixed, Liquidator lost, User earned < Collateral, after maturity", async () => {
        const quote = BigNumber.from("6").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        miltonSpreadModel.setCalculateQuotePayFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = SPECIFIC_INCOME_TAX_CASE_1;
        const expectedIncomeFeeValueWad = SPECIFIC_INCOME_TAX_CASE_1;
        const expectedPayoff = SPECIFIC_INTEREST_AMOUNT_CASE_1;
        const expectedPayoffWad = SPECIFIC_INTEREST_AMOUNT_CASE_1;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            admin,
            PERCENTAGE_50_18DEC,
            acceptableFixedInterestRate,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close DAI position pay fixed, Liquidator earned, User lost > Collateral, before maturity", async () => {
        const quote = BigNumber.from("161").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_160_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPayoffWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            admin,
            PERCENTAGE_5_18DEC,
            acceptableFixedInterestRate,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should close DAI position pay fixed, Liquidator earned, 100% Collateral > User lost > 99% Collateral, before maturity", async () => {
        const quote = BigNumber.from("151").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_150_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeTaxValueWad = BigNumber.from("989874270595533672762");
        const expectedPayoff = BigNumber.from("-9898742705955336727624");
        const expectedPayoffWad = BigNumber.from("-9898742705955336727624");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            admin,
            PERCENTAGE_6_18DEC,
            acceptableFixedInterestRate,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close DAI position pay fixed, Liquidator earned, User lost < Collateral, after maturity", async () => {
        const quote = BigNumber.from("10").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_120_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = BigNumber.from("68267191075554042975");
        const expectedPayoff = BigNumber.from("-682671910755540429745");
        const expectedPayoffWad = BigNumber.from("-682671910755540429745");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            admin,
            PERCENTAGE_5_18DEC,
            acceptableFixedInterestRate,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close DAI position pay fixed, Liquidator earned, User lost < Collateral, 5 hours before maturity", async () => {
        const quote = BigNumber.from("121").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_120_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeTaxValueWad = BigNumber.from("880328184649627945216");
        const expectedPayoff = BigNumber.from("-8803281846496279452160");
        const expectedPayoffWad = BigNumber.from("-8803281846496279452160");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            admin,
            PERCENTAGE_5_18DEC,
            acceptableFixedInterestRate,
            PERIOD_27_DAYS_19_HOURS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close DAI position pay fixed, Liquidator earned, User lost > Collateral, after maturity", async () => {
        const quote = BigNumber.from("161").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_160_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPayoffWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            admin,
            PERCENTAGE_5_18DEC,
            acceptableFixedInterestRate,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should close DAI position receive fixed, Liquidator lost, 100% Collateral > User earned > 99% Collateral, before maturity", async () => {
        const quote = BigNumber.from("150").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_151_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeTaxValue = BigNumber.from("989874270595533672080");
        const expectedIncomeTaxValueWad = BigNumber.from("989874270595533672080");
        const expectedPayoff = BigNumber.from("9898742705955336720799");
        const expectedPayoffWad = BigNumber.from("9898742705955336720799");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            acceptableFixedInterestRate,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            ZERO,
            expectedIncomeTaxValue,
            expectedIncomeTaxValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close DAI position receive fixed, Liquidator earned, User lost > Collateral, before maturity", async () => {
        //given
        const quote = BigNumber.from("4").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPayoffWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            admin,
            PERCENTAGE_160_18DEC,
            acceptableFixedInterestRate,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should close DAI position receive fixed, Liquidator earned, 100% Collateral > User lost > 99% Collateral, before maturity", async () => {
        //given
        const quote = BigNumber.from("4").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeTaxValueWad = BigNumber.from("996700989703089070547");
        const expectedPayoff = BigNumber.from("-9967009897030890705472");
        const expectedPayoffWad = BigNumber.from("-9967009897030890705472");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            admin,
            BigNumber.from("150").mul(N0__01_18DEC),
            acceptableFixedInterestRate,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close DAI position receive fixed, Liquidator lost, User earned > Collateral, after maturity", async () => {
        //given
        const quote = BigNumber.from("159").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_160_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC;
        const expectedPayoffWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            admin,
            PERCENTAGE_5_18DEC,
            acceptableFixedInterestRate,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should close DAI position receive fixed, Liquidator lost, User earned < Collateral, after maturity", async () => {
        //given
        const quote = BigNumber.from("10").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_120_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = BigNumber.from("68267191075554042975");
        const expectedIncomeFeeValueWad = BigNumber.from("68267191075554042975");
        const expectedPayoff = BigNumber.from("682671910755540429746");
        const expectedPayoffWad = BigNumber.from("682671910755540429746");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            admin,
            PERCENTAGE_5_18DEC,
            acceptableFixedInterestRate,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close DAI position receive fixed, Liquidator earned, User lost > Collateral, after maturity", async () => {
        //given
        const quote = BigNumber.from("4").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPayoffWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            admin,
            PERCENTAGE_160_18DEC,
            acceptableFixedInterestRate,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should close DAI position receive fixed, Liquidator earned, User lost < Collateral, after maturity", async () => {
        //given
        const quote = BigNumber.from("4").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = BigNumber.from("628058157895097225759");
        const expectedPayoff = BigNumber.from("-6280581578950972257591");
        const expectedPayoffWad = BigNumber.from("-6280581578950972257591");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            admin,
            PERCENTAGE_50_18DEC,
            acceptableFixedInterestRate,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });
});
