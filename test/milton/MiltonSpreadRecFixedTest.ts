import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { MockSpreadModel } from "../../types";
import {
    N1__0_18DEC,
    N0__001_18DEC,
    PERCENTAGE_3_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USD_100_18DEC,
    USD_500_18DEC,
    USD_15_000_18DEC,
    USD_13_000_18DEC,
    USD_20_18DEC,
    USD_10_000_000_6DEC,
    USD_10_000_000_18DEC,
    ZERO,
    N0__01_18DEC,
} from "../utils/Constants";
import { assertError } from "../utils/AssertUtils";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
    prepareMockSpreadModel,
    prepareMiltonSpreadBase,
    getPayFixedDerivativeParamsUSDTCase1,
} from "../utils/MiltonUtils";
import {
    prepareTestData,
    prepareApproveForUsers,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdtInitialValuesForUsers,
    setupTokenUsdcInitialValuesForUsers,
} from "../utils/DataUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

const { expect } = chai;

describe("MiltonSpreadRecFixed", () => {
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
    it("should calculate Quote Value Receive Fixed Value - Spread Premiums negative, Spread Premium < IPOR Index", async () => {
        //TODO:
    });
    it("should calculate Quote Value Receive Fixed Value - Spread Premiums negative, Spread Premium > IPOR Index", async () => {
        //TODO:
    });
    it("should calculate Quote Value Receive Fixed Value - Spread Premiums positive", async () => {
        //TODO:
    });

    it("should calculate Spread Receive Fixed, DAI - simple case 1 - initial state with Liquidity Pool", async () => {
        //given
        miltonSpreadModel.setCalculateSpreadReceiveFixed(BigNumber.from("553406136001736"));
        miltonSpreadModel.setCalculateSpreadPayFixed(BigNumber.from("3").mul(N0__001_18DEC));
        const calculateTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));
        const testData = await prepareTestData(
            calculateTimestamp,
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [BigNumber.from("0")],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        const { josephDai, miltonDai } = testData;
        if (josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const expectedSpreadReceiveFixed = BigNumber.from("553406136001736");

        await prepareApproveForUsers([liquidityProvider], "DAI", testData);

        await setupTokenDaiInitialValuesForUsers([liquidityProvider], testData);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_10_000_000_18DEC, calculateTimestamp);

        //when
        let actualSpreadValue = await miltonDai
            .connect(userOne)
            .callStatic.itfCalculateSpread(calculateTimestamp);

        //then
        expect(actualSpreadValue.spreadReceiveFixed).to.be.eq(expectedSpreadReceiveFixed);
    });

    it("should calculate Spread Receive Fixed, DAI - simple case 2 - initial state with Liquidity Pool", async () => {
        //given
        await miltonSpreadModel.setCalculateSpreadPayFixed(BigNumber.from("33").mul(N0__001_18DEC));
        await miltonSpreadModel.setCalculateSpreadReceiveFixed(BigNumber.from("127056293847751"));
        const calculateTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));
        const testData = await prepareTestData(
            calculateTimestamp,
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
        const { josephDai, miltonDai } = testData;
        if (josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const expectedSpreadReceiveFixed = BigNumber.from("127056293847751");

        await prepareApproveForUsers([liquidityProvider], "DAI", testData);

        await setupTokenDaiInitialValuesForUsers([liquidityProvider], testData);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_10_000_000_18DEC, calculateTimestamp);

        //when
        let actualSpreadValue = await miltonDai
            .connect(userOne)
            .callStatic.itfCalculateSpread(calculateTimestamp);

        //then
        expect(actualSpreadValue.spreadReceiveFixed).to.be.eq(expectedSpreadReceiveFixed);
    });

    it("should calculate Spread Receive Fixed, USDC - simple case 1 - initial state with Liquidity Pool", async () => {
        //given
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(ZERO);
        await miltonSpreadModel.setCalculateQuotePayFixed(ZERO);

        await miltonSpreadModel.setCalculateSpreadReceiveFixed(BigNumber.from("127056293847751"));
        await miltonSpreadModel.setCalculateSpreadPayFixed(BigNumber.from("33").mul(N0__001_18DEC));
        const calculateTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));
        const testData = await prepareTestData(
            calculateTimestamp,
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDC"],
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
        const { josephUsdc, miltonUsdc, tokenUsdc } = testData;
        if (josephUsdc === undefined || miltonUsdc === undefined || tokenUsdc === undefined) {
            expect(true).to.be.false;
            return;
        }
        const expectedSpreadReceiveFixed = BigNumber.from("127056293847751");

        await prepareApproveForUsers([liquidityProvider], "USDC", testData);

        await setupTokenUsdcInitialValuesForUsers([liquidityProvider], tokenUsdc);

        await josephUsdc
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_10_000_000_6DEC, calculateTimestamp);

        //when
        let actualSpreadValue = await miltonUsdc
            .connect(userOne)
            .callStatic.itfCalculateSpread(calculateTimestamp);

        //then
        expect(actualSpreadValue.spreadReceiveFixed).to.be.eq(expectedSpreadReceiveFixed);
    });

    it("should calculate Spread Receive Fixed - spread premiums higher than IPOR Index", async () => {
        //given
        await miltonSpreadModel.setCalculateSpreadReceiveFixed(BigNumber.from("553406136001736"));
        await miltonSpreadModel.setCalculateSpreadPayFixed(BigNumber.from("3").mul(N0__001_18DEC));
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("33").mul(N0__001_18DEC));
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
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

        const { iporOracle, josephUsdt, miltonUsdt, tokenUsdt } = testData;
        if (josephUsdt === undefined || miltonUsdt === undefined || tokenUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getPayFixedDerivativeParamsUSDTCase1(userTwo, tokenUsdt);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        let balanceLiquidityPool = BigNumber.from("10000000000");

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(balanceLiquidityPool, params.openTimestamp);

        await miltonUsdt
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigNumber.from("1000000000"),
                params.acceptableFixedInterestRate,
                params.leverage
            );

        //when
        const actualSpreadValue = await miltonUsdt
            .connect(userOne)
            .itfCalculateSpread(params.openTimestamp.add(BigNumber.from("1")));

        //then
        expect(actualSpreadValue.spreadReceiveFixed.eq(BigNumber.from("553406136001736"))).to.be
            .true;
    });
});
