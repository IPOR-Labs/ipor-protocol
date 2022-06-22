import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { MockSpreadModel } from "../../types";
import {
    USD_28_000_18DEC,
    PERCENTAGE_3_18DEC,
    N1__0_18DEC,
    N0__01_18DEC,
    USD_14_000_18DEC,
    ZERO,
} from "../utils/Constants";
import { assertError } from "../utils/AssertUtils";
import {    
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
    prepareMockSpreadModel,
} from "../utils/MiltonUtils";
import {
    prepareTestData,
    prepareApproveForUsers,
    setupTokenDaiInitialValuesForUsers,
    getPayFixedDerivativeParamsDAICase1,
    getReceiveFixedDerivativeParamsDAICase1,
} from "../utils/DataUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

const { expect } = chai;

describe("Milton Utilisation Rate", () => {
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

    it("should open pay fixed position - liquidity pool utilization per leg not exceeded, default utilization", async () => {
        //given
        miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("4").mul(N0__01_18DEC));
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_3_18DEC],
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

        const { josephDai, tokenDai, iporOracle, miltonDai } = testData;

        if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        //when
        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.acceptableFixedInterestRate,
                params.leverage
            );
    });

    it("should open receive fixed position - liquidity pool utilization per leg not exceeded, default utilization", async () => {
        //given
        miltonSpreadModel.setCalculateQuoteReceiveFixed(BigNumber.from("2").mul(N0__01_18DEC));
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_3_18DEC],
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

        const { josephDai, tokenDai, iporOracle, miltonDai } = testData;

        if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        //when
        await miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                params.totalAmount,
                params.acceptableFixedInterestRate,
                params.leverage
            );
    });

    it("should open pay fixed position - liquidity pool utilization per leg not exceeded, custom utilization", async () => {
        //given
        miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("4").mul(N0__01_18DEC));
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_3_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE6,
            MiltonUsdtCase.CASE6,
            MiltonDaiCase.CASE6,
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

        const { josephDai, tokenDai, iporOracle, miltonDai } = testData;

        if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from("100000").mul(N1__0_18DEC), params.openTimestamp);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        //when
        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.acceptableFixedInterestRate,
                params.leverage
            );
    });

    it("should open receive fixed position - liquidity pool utilization per leg not exceeded, custom utilization", async () => {
        //given
        miltonSpreadModel.setCalculateQuoteReceiveFixed(BigNumber.from("2").mul(N0__01_18DEC));
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_3_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE6,
            MiltonUsdtCase.CASE6,
            MiltonDaiCase.CASE6,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        const { josephDai, tokenDai, iporOracle, miltonDai } = testData;

        if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
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
        const params = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from("100000").mul(N1__0_18DEC), params.openTimestamp);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        //when
        await miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                params.totalAmount,
                params.acceptableFixedInterestRate,
                params.leverage
            );
    });

    it("should NOT open pay fixed position - liquidity pool utilization per leg exceeded, default utilization", async () => {
        //given
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_3_18DEC],
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

        const { josephDai, tokenDai, iporOracle, miltonDai } = testData;

        if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await assertError(
            //when
            miltonDai
                .connect(userTwo)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    USD_14_000_18DEC,
                    params.acceptableFixedInterestRate,
                    params.leverage
                ),
            //then
            "IPOR_303"
        );
    });

    it("should NOT open pay fixed position - liquidity pool utilization per leg exceeded, custom utilization", async () => {
        //given
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_3_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE6,
            MiltonUsdtCase.CASE6,
            MiltonDaiCase.CASE6,
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

        const { josephDai, tokenDai, iporOracle, miltonDai } = testData;

        if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await assertError(
            //when
            miltonDai
                .connect(userTwo)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.acceptableFixedInterestRate,
                    params.leverage
                ),
            //then
            "IPOR_303"
        );
    });

    it("should NOT open receive fixed position - liquidity pool utilization per leg exceeded, default utilization", async () => {
        //given
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_3_18DEC],
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

        const { josephDai, tokenDai, iporOracle, miltonDai } = testData;

        if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await assertError(
            //when
            miltonDai
                .connect(userTwo)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    USD_14_000_18DEC,
                    params.acceptableFixedInterestRate,
                    params.leverage
                ),
            //then
            "IPOR_303"
        );
    });

    it("should NOT open pay fixed position - liquidity pool utilization per leg exceeded, custom utilization", async () => {
        //given
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_3_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE6,
            MiltonUsdtCase.CASE6,
            MiltonDaiCase.CASE6,
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

        const { josephDai, tokenDai, iporOracle, miltonDai } = testData;

        if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await assertError(
            //when
            miltonDai
                .connect(userTwo)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.acceptableFixedInterestRate,
                    params.leverage
                ),
            //then
            "IPOR_303"
        );
    });
});
