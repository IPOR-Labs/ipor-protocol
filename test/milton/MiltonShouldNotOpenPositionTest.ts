import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { ItfIporOracle, MockCase8MiltonDai } from "../../types";
import {
    N1__0_18DEC,
    N0__01_18DEC,
    N0__001_18DEC,
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
    USER_SUPPLY_10MLN_18DEC,
} from "../utils/Constants";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
    prepareMockMiltonSpreadModel,
} from "../utils/MiltonUtils";
import { openSwapPayFixed } from "../utils/SwapUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

import {
    prepareComplexTestDataDaiCase000,
    prepareComplexTestDataDaiCase700,
    prepareComplexTestDataDaiCase800,
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
        const acceptableFixedInterestRate = BigNumber.from("3");
        const leverage = USD_10_18DEC;
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));
        await assertError(
            //when
            miltonDai.itfOpenSwapPayFixed(
                timestamp,
                totalAmount,
                acceptableFixedInterestRate,
                leverage
            ),
            //then
            "IPOR_308"
        );
    });

    it("should NOT open position because totalAmount > asset balance", async () => {
        //given
        const { miltonDai } = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const totalAmount = USER_SUPPLY_10MLN_18DEC.add(BigNumber.from("3"));
        const acceptableFixedInterestRate = BigNumber.from("3");
        const leverage = USD_10_18DEC;
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));
        await assertError(
            //when
            miltonDai.itfOpenSwapPayFixed(
                timestamp,
                totalAmount,
                acceptableFixedInterestRate,
                leverage
            ),
            //then
            "IPOR_003"
        );
    });

    it("should NOT open position because acceptable fixed interest rate  exceeded - pay fixed 18 decimals", async () => {
        //given
        const { iporOracle, tokenDai, josephDai, miltonDai } =
            await prepareComplexTestDataDaiCase000(
                [admin, userOne, userTwo, userThree, liquidityProvider],
                miltonSpreadModel
            );

        const totalAmount = BigNumber.from("30000000000000000001");
        const acceptableFixedInterestRate = BigNumber.from("39999999999999999");
        const leverage = USD_10_18DEC;
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(tokenDai.address, PERCENTAGE_3_18DEC, timestamp);

        await josephDai.connect(liquidityProvider).itfProvideLiquidity(USD_28_000_18DEC, timestamp);

        await assertError(
            //when
            miltonDai.itfOpenSwapPayFixed(
                timestamp,
                totalAmount,
                acceptableFixedInterestRate,
                leverage
            ),
            //then
            "IPOR_312"
        );
    });

    it("should NOT open position because acceptable fixed interest rate  exceeded - receive fixed 18 decimals", async () => {
        //given
        const { iporOracle, tokenDai, josephDai, miltonDai } =
            await prepareComplexTestDataDaiCase000(
                [admin, userOne, userTwo, userThree, liquidityProvider],
                miltonSpreadModel
            );

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const totalAmount = BigNumber.from("30000000000000000001");
        const acceptableFixedInterestRate = N0__01_18DEC.add(N0__01_18DEC).add(N0__001_18DEC);
        const leverage = USD_10_18DEC;
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(tokenDai.address, PERCENTAGE_3_18DEC, timestamp);

        await josephDai.connect(liquidityProvider).itfProvideLiquidity(USD_28_000_18DEC, timestamp);

        await assertError(
            //when
            miltonDai.itfOpenSwapReceiveFixed(
                timestamp,
                totalAmount,
                acceptableFixedInterestRate,
                leverage
            ),
            //then
            "IPOR_312"
        );
    });

    it("should NOT open position because acceptable fixed interest rate  exceeded - pay fixed 6 decimals", async () => {
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

        const { tokenUsdt, iporOracle, josephUsdt, miltonUsdt } = testData;

        if (tokenUsdt === undefined || josephUsdt === undefined || miltonUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        const totalAmount = BigNumber.from("30000001");
        const acceptableFixedInterestRate = BigNumber.from("39999999999999999");
        const leverage = USD_10_18DEC;
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(tokenUsdt.address, PERCENTAGE_3_18DEC, timestamp);

        await josephUsdt.connect(liquidityProvider).itfProvideLiquidity(USD_28_000_6DEC, timestamp);

        await assertError(
            //when
            miltonUsdt.itfOpenSwapPayFixed(
                timestamp,
                totalAmount,
                acceptableFixedInterestRate,
                leverage
            ),
            //then
            "IPOR_312"
        );
    });

    it("should NOT open position because acceptable fixed interest rate  exceeded - receive fixed 6 decimals", async () => {
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

        const { tokenUsdt, iporOracle, josephUsdt, miltonUsdt } = testData;

        if (tokenUsdt === undefined || josephUsdt === undefined || miltonUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        const totalAmount = BigNumber.from("30000001");
        const acceptableFixedInterestRate = N0__01_18DEC.add(N0__01_18DEC).add(N0__001_18DEC);
        const leverage = USD_10_18DEC;
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(tokenUsdt.address, PERCENTAGE_3_18DEC, timestamp);

        await josephUsdt.connect(liquidityProvider).itfProvideLiquidity(USD_28_000_6DEC, timestamp);

        await assertError(
            //when
            miltonUsdt.itfOpenSwapReceiveFixed(
                timestamp,
                totalAmount,
                acceptableFixedInterestRate,
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
        const acceptableFixedInterestRate = 3;
        const leverage = BigNumber.from("10").mul(N1__0_18DEC);
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        await assertError(
            //when
            miltonDai.itfOpenSwapPayFixed(
                timestamp,
                totalAmount,
                acceptableFixedInterestRate,
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
        const acceptableFixedInterestRate = 3;
        const leverage = BigNumber.from("10").mul(N1__0_18DEC);
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        await assertError(
            //when
            miltonDai.itfOpenSwapPayFixed(
                timestamp,
                totalAmount,
                acceptableFixedInterestRate,
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

        const { tokenDai, josephDai, miltonDai, iporOracle, miltonStorageDai } = testData;

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
            acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };
        const closeSwapTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, N0__01_18DEC, params.openTimestamp);

        await openSwapPayFixed(testData, params);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                BigNumber.from("16").mul(N0__1_18DEC),
                params.openTimestamp
            );

        await iporOracle
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

        const { tokenDai, iporOracle, miltonDai } = testData;
        if (tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: BigNumber.from(500),
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };
        await iporOracle
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
                    params.acceptableFixedInterestRate,
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

        const { tokenDai, iporOracle, miltonDai } = testData;
        if (tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: BigNumber.from("1000000000000000000001"),
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };
        await iporOracle
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
                    params.acceptableFixedInterestRate,
                    params.leverage
                ),
            //then
            "IPOR_307"
        );
    });

    it("Should not open position when utilization exceeded", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase700(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
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
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: userThree,
        };
        // when
        await expect(openSwapPayFixed(testData, derivativeParams)).to.be.revertedWith("IPOR_302");
    });

    it("Should not open position when total amount lower than fee", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase800(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
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
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: userThree,
        };
        // when
        await expect(openSwapPayFixed(testData, derivativeParams)).to.be.revertedWith("IPOR_309");
    });

    it("Should not open position when total amount lower than fee", async () => {
        //given
        const { miltonDai } = await prepareComplexTestDataDaiCase800(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const MockMiltonStorage = await hre.ethers.getContractFactory("MockMiltonStorage");
        const mockMiltonStorage = (await MockMiltonStorage.deploy()) as ItfIporOracle;
        await (miltonDai as MockCase8MiltonDai).setMockMiltonStorage(mockMiltonStorage.address);
        // when
        await expect(miltonDai.getAccruedBalance()).to.be.revertedWith("IPOR_301");
    });

    it("Should revert when ibt price is zero", async () => {
        //given

        const MockItfIporOracle = await hre.ethers.getContractFactory("MockItfIporOracle");
        const mockIporOracle = (await MockItfIporOracle.deploy()) as ItfIporOracle;
        await mockIporOracle.initialize();
        await mockIporOracle.addUpdater(await admin.getAddress());

        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            mockIporOracle
        );

        const { tokenDai, josephDai } = testData;
        if (tokenDai === undefined || josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: userThree,
        };
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigNumber.from(2).mul(USD_28_000_18DEC),
                derivativeParams.openTimestamp
            );

        await expect(openSwapPayFixed(testData, derivativeParams)).to.be.revertedWith("311");
    });
});
