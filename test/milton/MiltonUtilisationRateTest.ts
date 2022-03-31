import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    USD_28_000_18DEC,
    PERCENTAGE_3_18DEC,
    N1__0_18DEC,
    USD_14_000_18DEC,
} from "../utils/Constants";
import { assertError } from "../utils/AssertUtils";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
    prepareMockMiltonSpreadModel,
} from "../utils/MiltonUtils";
import {
    prepareTestData,
    prepareApproveForUsers,
    setupTokenDaiInitialValuesForUsers,
    getPayFixedDerivativeParamsDAICase1,
} from "../utils/DataUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

const { expect } = chai;

describe("Milton Utilisation Rate", () => {
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

    //TODO: clarify when spread equasion will be clarified
    // it("should NOT open pay fixed position - liquidity pool utilization exceeded, liquidity pool and opening fee are ZERO", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data
    //     );
    //     await prepareApproveForUsers(
    //         [userOne, userTwo, userThree, liquidityProvider],
    //         "DAI",
    //         data,
    //         testData
    //     );
    //     await setupTokenDaiInitialValuesForUsers(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         testData
    //     );
    //     const params = getPayFixedDerivativeParamsDAICase1(
    //         userTwo,
    //         testData
    //     );

    //     await warren.connect(userOne).itfUpdateIndex(
    //         params.asset,
    //         PERCENTAGE_3_18DEC,
    //         params.openTimestamp
    //     );

    //     await assertError(
    //         //when
    //         data.milton.connect(userTwo).itfOpenSwap(
    //             params.openTimestamp,
    //             params.asset,
    //             params.totalAmount,
    //             params.toleratedQuoteValue,
    //             params.leverage,
    //             params.direction
    //         ),
    //         //then
    //         "IPOR_303"
    //     );
    // });

    it("should open pay fixed position - liquidity pool utilization per leg not exceeded, default utilization", async () => {
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

        const { josephDai, tokenDai, warren, miltonDai } = testData;

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

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        //when
        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.toleratedQuoteValue,
                params.leverage
            );
    });

    it("should open receive fixed position - liquidity pool utilization per leg not exceeded, default utilization", async () => {
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

        const { josephDai, tokenDai, warren, miltonDai } = testData;

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

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        //when
        await miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                params.totalAmount,
                params.toleratedQuoteValue,
                params.leverage
            );
    });

    it("should open pay fixed position - liquidity pool utilization per leg not exceeded, custom utilization", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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

        const { josephDai, tokenDai, warren, miltonDai } = testData;

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

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        //when
        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.toleratedQuoteValue,
                params.leverage
            );
    });

    it("should open receive fixed position - liquidity pool utilization per leg not exceeded, custom utilization", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE6,
            MiltonUsdtCase.CASE6,
            MiltonDaiCase.CASE6,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        const { josephDai, tokenDai, warren, miltonDai } = testData;

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
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from("100000").mul(N1__0_18DEC), params.openTimestamp);

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        //when
        await miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                params.totalAmount,
                params.toleratedQuoteValue,
                params.leverage
            );
    });

    it("should NOT open pay fixed position - liquidity pool utilization per leg exceeded, default utilization", async () => {
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

        const { josephDai, tokenDai, warren, miltonDai } = testData;

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

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await assertError(
            //when
            miltonDai
                .connect(userTwo)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    USD_14_000_18DEC,
                    params.toleratedQuoteValue,
                    params.leverage
                ),
            //then
            "IPOR_303"
        );
    });

    it("should NOT open pay fixed position - liquidity pool utilization per leg exceeded, custom utilization", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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

        const { josephDai, tokenDai, warren, miltonDai } = testData;

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

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await assertError(
            //when
            miltonDai
                .connect(userTwo)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
                    params.leverage
                ),
            //then
            "IPOR_303"
        );
    });

    it("should NOT open receive fixed position - liquidity pool utilization per leg exceeded, default utilization", async () => {
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

        const { josephDai, tokenDai, warren, miltonDai } = testData;

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

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await assertError(
            //when
            miltonDai
                .connect(userTwo)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    USD_14_000_18DEC,
                    params.toleratedQuoteValue,
                    params.leverage
                ),
            //then
            "IPOR_303"
        );
    });

    it("should NOT open pay fixed position - liquidity pool utilization per leg exceeded, custom utilization", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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

        const { josephDai, tokenDai, warren, miltonDai } = testData;

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

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await assertError(
            //when
            miltonDai
                .connect(userTwo)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
                    params.leverage
                ),
            //then
            "IPOR_303"
        );
    });
});
