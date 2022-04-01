import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { N1__0_18DEC, ZERO, USD_14_000_18DEC, USD_14_000_6DEC } from "../utils/Constants";
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
    prepareTestDataDaiCase000,
    prepareComplexTestDataDaiCase000,
    prepareTestDataUsdtCase000,
    setupIpTokenInitialValues,
    getStandardDerivativeParamsDAI,
    prepareApproveForUsers,
    setupTokenUsdtInitialValuesForUsers,
    getStandardDerivativeParamsUSDT,
    setupTokenDaiInitialValuesForUsers,
} from "../utils/DataUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

const { expect } = chai;

describe("Joseph - provide liquidity", () => {
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

    it("should setup init value for Redeem LP Max Utilization Percentage", async () => {
        //given
        const { josephUsdt, josephUsdc, josephDai } = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI", "USDT", "USDC"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        if (josephDai === undefined || josephUsdc === undefined || josephUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }

        //when
        const actualValueUsdt = await josephUsdt.getRedeemLpMaxUtilizationRate();
        const actualValueUsdc = await josephUsdc.getRedeemLpMaxUtilizationRate();
        const actualValueDai = await josephDai.getRedeemLpMaxUtilizationRate();

        //then
        expect(actualValueUsdt).to.be.eq(N1__0_18DEC);
        expect(actualValueUsdc).to.be.eq(N1__0_18DEC);
        expect(actualValueDai).to.be.eq(N1__0_18DEC);
    });

    it("should provide liquidity and take ipToken - simple case 1 - 18 decimals", async () => {
        //given
        const { ipTokenDai, tokenDai, josephDai, miltonDai } =
            await prepareComplexTestDataDaiCase000(
                [admin, userOne, userTwo, userThree, liquidityProvider],
                miltonSpreadModel
            );

        if (
            ipTokenDai === undefined ||
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await setupIpTokenInitialValues(ipTokenDai, liquidityProvider, ZERO);
        const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);
        const assetAmount = USD_14_000_18DEC;

        const expectedLiquidityProviderStableBalance = BigNumber.from("9986000").mul(N1__0_18DEC);
        const expectedLiquidityPoolBalanceMilton = USD_14_000_18DEC;

        //when
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(assetAmount, params.openTimestamp);

        // //then
        const actualIpTokenBalanceSender = await ipTokenDai.balanceOf(
            await liquidityProvider.getAddress()
        );
        const actualUnderlyingBalanceMilton = await tokenDai.balanceOf(miltonDai.address);
        const actualLiquidityPoolBalanceMilton = await (
            await miltonDai.getAccruedBalance()
        ).liquidityPool;
        const actualUnderlyingBalanceSender = await tokenDai.balanceOf(
            await liquidityProvider.getAddress()
        );
        expect(
            assetAmount,
            `Incorrect ipToken balance on user for asset ${params.asset} actual: ${actualIpTokenBalanceSender}, expected: ${assetAmount}`
        ).to.be.eql(actualIpTokenBalanceSender);

        expect(
            assetAmount,
            `Incorrect DAI balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${assetAmount}`
        ).to.be.eql(actualUnderlyingBalanceMilton);

        expect(
            expectedLiquidityPoolBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
        ).to.be.eql(actualLiquidityPoolBalanceMilton);

        expect(
            expectedLiquidityProviderStableBalance,
            `Incorrect DAI balance on user for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
        ).to.be.eql(actualUnderlyingBalanceSender);
    });

    it("should provide liquidity and take ipToken - simple case 1 - USDT 6 decimals", async () => {
        //given
        const testData = await prepareTestDataUsdtCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenUsdt, ipTokenUsdt, josephUsdt, miltonUsdt } = testData;
        if (
            tokenUsdt === undefined ||
            ipTokenUsdt === undefined ||
            josephUsdt === undefined ||
            miltonUsdt === undefined
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
        const assetAmount = USD_14_000_6DEC;
        const wadLiquidityAmount = USD_14_000_18DEC;

        const expectedLiquidityProviderStableBalance = BigNumber.from("9986000000000");
        const expectedLiquidityPoolBalanceMilton = USD_14_000_18DEC;

        //when
        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(assetAmount, params.openTimestamp);

        //then
        const actualIpTokenBalanceSender = await ipTokenUsdt.balanceOf(
            await liquidityProvider.getAddress()
        );
        const actualUnderlyingBalanceMilton = await tokenUsdt.balanceOf(miltonUsdt.address);
        const actualLiquidityPoolBalanceMilton = await (
            await miltonUsdt.getAccruedBalance()
        ).liquidityPool;
        const actualUnderlyingBalanceSender = await tokenUsdt.balanceOf(
            await liquidityProvider.getAddress()
        );
        expect(
            wadLiquidityAmount.toString(),
            `Incorrect ipToken balance on user for asset ${
                params.asset
            } actual: ${actualIpTokenBalanceSender}, expected: ${wadLiquidityAmount.toString()}`
        ).to.be.eql(actualIpTokenBalanceSender.toString());

        expect(
            assetAmount,
            `Incorrect USDT balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${assetAmount}`
        ).to.be.eql(actualUnderlyingBalanceMilton);

        expect(
            expectedLiquidityPoolBalanceMilton,
            `Incorrect USDT Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
        ).to.be.eql(actualLiquidityPoolBalanceMilton);

        expect(
            expectedLiquidityProviderStableBalance,
            `Incorrect USDT balance on user for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
        ).to.be.eql(actualUnderlyingBalanceSender);
    });

    it("should NOT provide liquidity because of empty Liquidity Pool", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        const { ipTokenDai, tokenDai, josephDai, miltonStorageDai } = testData;
        if (
            ipTokenDai === undefined ||
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonStorageDai === undefined
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
        await setupIpTokenInitialValues(ipTokenDai, liquidityProvider, ZERO);
        const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(params.totalAmount, params.openTimestamp);

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        await miltonStorageDai.setJoseph(await userOne.getAddress());
        await miltonStorageDai.connect(userOne).subtractLiquidity(params.totalAmount);
        await miltonStorageDai.setJoseph(josephDai.address);

        //when
        await assertError(
            //when
            josephDai
                .connect(liquidityProvider)
                .itfProvideLiquidity(params.totalAmount, params.openTimestamp),
            //then
            "IPOR_300"
        );
    });
});
