import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { N1__0_18DEC, PERCENTAGE_3_18DEC, N1__0_6DEC, N0__000_1_18DEC } from "../utils/Constants";
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
    getStandardDerivativeParamsDAI,
    prepareApproveForUsers,
    setupTokenUsdtInitialValuesForUsers,
    getStandardDerivativeParamsUSDT,
    setupTokenDaiInitialValuesForUsers,
} from "../utils/DataUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

const { expect } = chai;

describe("Joseph -  calculate Exchange Rate when SOAP changed", () => {
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

    it("should NOT change Exchange Rate when Liquidity Provider provide liquidity, DAI 18 decimals", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE1,
            MiltonUsdtCase.CASE1,
            MiltonDaiCase.CASE1,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        const { josephDai, ipTokenDai, tokenDai, iporOracle, miltonDai } = testData;
        if (
            josephDai === undefined ||
            ipTokenDai === undefined ||
            tokenDai === undefined ||
            miltonDai === undefined
        ) {
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
        const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

        const amount = BigNumber.from("180").mul(N1__0_18DEC);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(amount, params.openTimestamp);

        //open position to have something in Liquidity Pool
        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                amount,
                params.acceptableFixedInterestRate,
                params.leverage
            );

        const expectedExchangeRate = BigNumber.from("13125").mul(N0__000_1_18DEC);
        const exchangeRateBeforeProvideLiquidity = await josephDai.itfCalculateExchangeRate(
            params.openTimestamp
        );
        const expectedIpTokenBalanceForUserThree = BigNumber.from("1142857142857142857143");

        //when
        await josephDai
            .connect(userThree)
            .itfProvideLiquidity(BigNumber.from("1500").mul(N1__0_18DEC), params.openTimestamp);

        const actualIpTokenBalanceForUserThree = await ipTokenDai.balanceOf(
            await userThree.getAddress()
        );
        const actualExchangeRate = await josephDai.itfCalculateExchangeRate(params.openTimestamp);
        //then
        expect(
            expectedIpTokenBalanceForUserThree,
            `Incorrect ipToken Balance for asset ${params.asset} for user ${userThree}, actual:  ${actualIpTokenBalanceForUserThree},
             expected: ${expectedIpTokenBalanceForUserThree}`
        ).to.be.eql(actualIpTokenBalanceForUserThree);

        expect(
            expectedExchangeRate,
            `Incorrect exchange rate before providing liquidity for DAI, actual:  ${exchangeRateBeforeProvideLiquidity},
            expected: ${expectedExchangeRate}`
        ).to.be.eql(exchangeRateBeforeProvideLiquidity);

        expect(
            expectedExchangeRate,
            `Incorrect exchange rate after providing liquidity for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should NOT change Exchange Rate when Liquidity Provider provide liquidity and redeem, DAI 18 decimals", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE1,
            MiltonUsdtCase.CASE1,
            MiltonDaiCase.CASE1,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        const { josephDai, ipTokenDai, tokenDai, iporOracle, miltonDai } = testData;
        if (
            josephDai === undefined ||
            ipTokenDai === undefined ||
            tokenDai === undefined ||
            miltonDai === undefined
        ) {
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
        const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

        const amount = BigNumber.from("180").mul(N1__0_18DEC);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(amount, params.openTimestamp);

        //open position to have something in Liquidity Pool
        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                amount,
                params.acceptableFixedInterestRate,
                params.leverage
            );

        const expectedExchangeRateBeforeRedeem = BigNumber.from("1312500000000000000");
        const expectedExchangeRateAfterRedeem = BigNumber.from("1325321471291866029");
        const exchangeRateBeforeProvideLiquidity = await josephDai.itfCalculateExchangeRate(
            params.openTimestamp
        );
        const expectedIpTokenBalanceForUserThree = BigNumber.from("267857142857142857289");

        //when
        await josephDai
            .connect(userThree)
            .itfProvideLiquidity(BigNumber.from("1500").mul(N1__0_18DEC), params.openTimestamp);

        await josephDai
            .connect(userThree)
            .itfRedeem(BigNumber.from("874999999999999999854"), params.openTimestamp);

        const actualIpTokenBalanceForUserThree = await ipTokenDai.balanceOf(
            await userThree.getAddress()
        );
        const actualExchangeRate = await josephDai.itfCalculateExchangeRate(params.openTimestamp);
        //then
        expect(
            expectedIpTokenBalanceForUserThree,
            `Incorrect ipToken Balance for DAI asset ${params.asset} for user ${userThree}, actual:  ${actualIpTokenBalanceForUserThree},
             expected: ${expectedIpTokenBalanceForUserThree}`
        ).to.be.eql(actualIpTokenBalanceForUserThree);

        expect(
            expectedExchangeRateBeforeRedeem,
            `Incorrect exchange rate before providing liquidity for DAI, actual:  ${exchangeRateBeforeProvideLiquidity},
            expected: ${expectedExchangeRateBeforeRedeem}`
        ).to.be.eql(exchangeRateBeforeProvideLiquidity);

        expect(
            expectedExchangeRateAfterRedeem,
            `Incorrect exchange rate after providing liquidity for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRateAfterRedeem}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should NOT change Exchange Rate when Liquidity Provider provide liquidity and redeem, USDT 6 decimals", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE1,
            MiltonUsdtCase.CASE1,
            MiltonDaiCase.CASE1,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        const { tokenUsdt, iporOracle, josephUsdt, miltonUsdt, ipTokenUsdt } = testData;
        if (
            tokenUsdt === undefined ||
            josephUsdt === undefined ||
            miltonUsdt === undefined ||
            ipTokenUsdt === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );
        const params = getStandardDerivativeParamsUSDT(userTwo, tokenUsdt);

        const amount = BigNumber.from("180").mul(N1__0_6DEC);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);
        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(amount, params.openTimestamp);

        //open position to have something in Liquidity Pool
        await miltonUsdt
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                amount,
                params.acceptableFixedInterestRate,
                params.leverage
            );

        const expectedExchangeRateBeforeRedeem = BigNumber.from("1312500000000000000");
        const expectedExchangeRateAfterRedeem = BigNumber.from("1325321471291866029");
        const exchangeRateBeforeProvideLiquidity = await josephUsdt.itfCalculateExchangeRate(
            params.openTimestamp
        );
        const expectedIpTokenBalanceForUserThree = BigNumber.from("267857142857142857289");

        //when
        await josephUsdt
            .connect(userThree)
            .itfProvideLiquidity(BigNumber.from("1500").mul(N1__0_6DEC), params.openTimestamp);
        await josephUsdt
            .connect(userThree)
            .itfRedeem(BigNumber.from("874999999999999999854"), params.openTimestamp);

        let actualIpTokenBalanceForUserThree = await ipTokenUsdt.balanceOf(
            await userThree.getAddress()
        );
        let actualExchangeRate = await josephUsdt.itfCalculateExchangeRate(params.openTimestamp);
        //then
        expect(
            expectedIpTokenBalanceForUserThree,
            `Incorrect ipToken Balance for USDT asset ${params.asset} for user ${userThree}, actual:  ${actualIpTokenBalanceForUserThree},
             expected: ${expectedIpTokenBalanceForUserThree}`
        ).to.be.eql(actualIpTokenBalanceForUserThree);

        expect(
            expectedExchangeRateBeforeRedeem,
            `Incorrect exchange rate before providing liquidity for USDT, actual:  ${exchangeRateBeforeProvideLiquidity},
            expected: ${expectedExchangeRateBeforeRedeem}`
        ).to.be.eql(exchangeRateBeforeProvideLiquidity);

        expect(
            expectedExchangeRateAfterRedeem,
            `Incorrect exchange rate after providing liquidity for USDT, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRateAfterRedeem}`
        ).to.be.eql(actualExchangeRate);
    });
});
