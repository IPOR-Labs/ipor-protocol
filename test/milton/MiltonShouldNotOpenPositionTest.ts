import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    N0__01_18DEC,
    N1__0_18DEC,
    USD_28_000_6DEC,
    USD_10_000_18DEC,
    ZERO,
    USD_10_18DEC,
    USD_28_000_18DEC,
    PERCENTAGE_3_18DEC,
    PERIOD_25_DAYS_IN_SECONDS,
    LEVERAGE_18DEC,
    N0__1_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
} from "../utils/Constants";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
    prepareMockMiltonSpreadModel,
} from "../utils/MiltonUtils";
import { openSwapPayFixed } from "../utils/SwapUtiles";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

import {
    prepareComplexTestDataDaiCase000,
    prepareApproveForUsers,
    prepareTestData,
    setupTokenUsdtInitialValuesForUsers,
} from "../utils/DataUtils";
import { assertError } from "../utils/AssertUtils";

const { expect } = chai;

describe("MiltonSpreadModel - Core", () => {
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

    it("should NOT open position because totalAmount amount too low", async () => {
        //given
        const { miltonDai } = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const totalAmount = ZERO;
        const maxAcceptableFixedInterestRate = BigNumber.from("3");
        const leverage = USD_10_18DEC;
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));
        await assertError(
            //when
            miltonDai.itfOpenSwapPayFixed(
                timestamp,
                totalAmount,
                maxAcceptableFixedInterestRate,
                leverage
            ),
            //then
            "IPOR_308"
        );
    });

    it("should NOT open position because tolerated quote value exceeded - pay fixed 18 decimals", async () => {
        //given
        const { warren, tokenDai, josephDai, miltonDai } = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const totalAmount = BigNumber.from("30000000000000000001");
        const maxAcceptableFixedInterestRate = BigNumber.from("39999999999999999");
        const leverage = USD_10_18DEC;
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await warren
            .connect(userOne)
            .itfUpdateIndex(tokenDai.address, PERCENTAGE_3_18DEC, timestamp);

        await josephDai.connect(liquidityProvider).itfProvideLiquidity(USD_28_000_18DEC, timestamp);

        await assertError(
            //when
            miltonDai.itfOpenSwapPayFixed(
                timestamp,
                totalAmount,
                maxAcceptableFixedInterestRate,
                leverage
            ),
            //then
            "IPOR_312"
        );
    });

    it("should NOT open position because tolerated quote value exceeded - receive fixed 18 decimals", async () => {
        //given
        const { warren, tokenDai, josephDai, miltonDai } = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const totalAmount = BigNumber.from("30000000000000000001");
        const maxAcceptableFixedInterestRate = BigNumber.from("19999999999999999");
        const leverage = USD_10_18DEC;
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        await warren
            .connect(userOne)
            .itfUpdateIndex(tokenDai.address, PERCENTAGE_3_18DEC, timestamp);

        await josephDai.connect(liquidityProvider).itfProvideLiquidity(USD_28_000_18DEC, timestamp);

        await assertError(
            //when
            miltonDai.itfOpenSwapReceiveFixed(
                timestamp,
                totalAmount,
                maxAcceptableFixedInterestRate,
                leverage
            ),
            //then
            "IPOR_312"
        );
    });

    it("should NOT open position because tolerated quote value exceeded - pay fixed 6 decimals", async () => {
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

        const { tokenUsdt, warren, josephUsdt, miltonUsdt } = testData;

        if (tokenUsdt === undefined || josephUsdt === undefined || miltonUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        const totalAmount = BigNumber.from("30000001");
        const maxAcceptableFixedInterestRate = BigNumber.from("39999999999999999");
        const leverage = USD_10_18DEC;
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        await warren
            .connect(userOne)
            .itfUpdateIndex(tokenUsdt.address, PERCENTAGE_3_18DEC, timestamp);

        await josephUsdt.connect(liquidityProvider).itfProvideLiquidity(USD_28_000_6DEC, timestamp);

        await assertError(
            //when
            miltonUsdt.itfOpenSwapPayFixed(
                timestamp,
                totalAmount,
                maxAcceptableFixedInterestRate,
                leverage
            ),
            //then
            "IPOR_312"
        );
    });

    it("should NOT open position because tolerated quote value exceeded - receive fixed 6 decimals", async () => {
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

        const { tokenUsdt, warren, josephUsdt, miltonUsdt } = testData;

        if (tokenUsdt === undefined || josephUsdt === undefined || miltonUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        const totalAmount = BigNumber.from("30000001");
        const maxAcceptableFixedInterestRate = BigNumber.from("19999999999999999");
        const leverage = USD_10_18DEC;
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        await warren
            .connect(userOne)
            .itfUpdateIndex(tokenUsdt.address, PERCENTAGE_3_18DEC, timestamp);

        await josephUsdt.connect(liquidityProvider).itfProvideLiquidity(USD_28_000_6DEC, timestamp);

        await assertError(
            //when
            miltonUsdt.itfOpenSwapReceiveFixed(
                timestamp,
                totalAmount,
                maxAcceptableFixedInterestRate,
                leverage
            ),
            //then
            "IPOR_312"
        );
    });

    it("should NOT open position because totalAmount amount too high", async () => {
        //given
        const { miltonDai } = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const totalAmount = BigNumber.from("1000000000000000000000001");
        const maxAcceptableFixedInterestRate = 3;
        const leverage = BigNumber.from("10").mul(N1__0_18DEC);
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        await assertError(
            //when
            miltonDai.itfOpenSwapPayFixed(
                timestamp,
                totalAmount,
                maxAcceptableFixedInterestRate,
                leverage
            ),
            //then
            "IPOR_310"
        );
    });

    it("should NOT open position because totalAmount amount too high - case 2", async () => {
        //given
        const { miltonDai } = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const totalAmount = BigNumber.from("100688870576704582165765");
        const maxAcceptableFixedInterestRate = 3;
        const leverage = BigNumber.from("10").mul(N1__0_18DEC);
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        await assertError(
            //when
            miltonDai.itfOpenSwapPayFixed(
                timestamp,
                totalAmount,
                maxAcceptableFixedInterestRate,
                leverage
            ),
            //then
            "IPOR_310"
        );
    });

    it("should NOT open position because Liquidity Pool balance is to low", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, miltonDai, warren, miltonStorageDai } = testData;

        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: USD_10_000_18DEC, //10 000 USD
            maxAcceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };
        const closeSwapTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, N0__01_18DEC, params.openTimestamp);

        await openSwapPayFixed(testData, params);

        await warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                BigNumber.from("16").mul(N0__1_18DEC),
                params.openTimestamp
            );

        await warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                BigNumber.from("5").mul(N0__01_18DEC),
                closeSwapTimestamp
            );

        await miltonStorageDai.setJoseph(await userOne.getAddress());

        await miltonStorageDai
            .connect(userOne)
            .subtractLiquidity(BigNumber.from("20000").mul(N1__0_18DEC));

        await miltonStorageDai.setJoseph(josephDai.address);

        //when
        await assertError(
            //when
            miltonDai.connect(userTwo).itfCloseSwapPayFixed(1, closeSwapTimestamp),
            //then
            "IPOR_319"
        );
    });

    it("should NOT open pay fixed position, DAI, leverage too low", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, warren, miltonDai } = testData;
        if (tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            maxAcceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: BigNumber.from(500),
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        //when
        await assertError(
            //when
            miltonDai
                .connect(userTwo)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.maxAcceptableFixedInterestRate,
                    params.leverage
                ),
            //then
            "IPOR_306"
        );
    });

    it("should NOT open pay fixed position, DAI, leverage too high", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, warren, miltonDai } = testData;
        if (tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            maxAcceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: BigNumber.from("1000000000000000000001"),
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        //when
        await assertError(
            //when
            miltonDai
                .connect(userTwo)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.maxAcceptableFixedInterestRate,
                    params.leverage
                ),
            //then
            "IPOR_307"
        );
    });
});
