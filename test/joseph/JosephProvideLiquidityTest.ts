import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { MockSpreadModel } from "../../types";
import {
    N1__0_18DEC,
    ZERO,
    PERCENTAGE_3_18DEC,
    USD_14_000_18DEC,
    USD_14_000_6DEC,
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
    prepareTestDataDaiCase000,
    prepareComplexTestDataDaiCase000,
    prepareTestDataUsdtCase000,
    setupIpTokenInitialValues,
    getStandardDerivativeParamsDAI,
    prepareApproveForUsers,
    setupTokenUsdtInitialValuesForUsers,
    getStandardDerivativeParamsUSDT,
    setupTokenDaiInitialValuesForUsers,
    prepareTestDataDaiCase001,
} from "../utils/DataUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

const { expect } = chai;

describe("Joseph - provide liquidity", () => {
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

    it("should setup init value for Redeem LP Max Utilization Percentage", async () => {
        //given
        const { josephUsdt, josephUsdc, josephDai } = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI", "USDT", "USDC"],
            [],
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
                BigNumber.from(Math.floor(Date.now() / 1000)),
                [admin, userOne, userTwo, userThree, liquidityProvider],
                miltonSpreadModel,
                PERCENTAGE_3_18DEC
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
        ).to.be.equal(actualIpTokenBalanceSender);

        expect(
            assetAmount,
            `Incorrect DAI balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${assetAmount}`
        ).to.be.equal(actualUnderlyingBalanceMilton);

        expect(
            expectedLiquidityPoolBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
        ).to.be.equal(actualLiquidityPoolBalanceMilton);

        expect(
            expectedLiquidityProviderStableBalance,
            `Incorrect DAI balance on user for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
        ).to.be.equal(actualUnderlyingBalanceSender);
    });

    it("should provide liquidity and take ipToken - simple case 1 - USDT 6 decimals", async () => {
        //given
        const testData = await prepareTestDataUsdtCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
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
        ).to.be.equal(actualIpTokenBalanceSender.toString());

        expect(
            assetAmount,
            `Incorrect USDT balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${assetAmount}`
        ).to.be.equal(actualUnderlyingBalanceMilton);

        expect(
            expectedLiquidityPoolBalanceMilton,
            `Incorrect USDT Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
        ).to.be.equal(actualLiquidityPoolBalanceMilton);

        expect(
            expectedLiquidityProviderStableBalance,
            `Incorrect USDT balance on user for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
        ).to.be.equal(actualUnderlyingBalanceSender);
    });

    it("should NOT provide liquidity because of empty Liquidity Pool", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
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

    it("Should throw error when stanley balance is zero", async () => {
        //given
        const { josephDai } = await prepareTestDataDaiCase001(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        if (josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        //when
        await assertError(
            //when
            josephDai.checkVaultReservesRatio(),
            //then
            "IPOR_408"
        );
    });

    it("should NOT provide liquidity because Max Liquidity Pool Balance exceeded", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );
        const maxLpAccountContributionAmount = BigNumber.from("15000");
        await testData.josephDai.setMaxLiquidityPoolAmount(
            maxLpAccountContributionAmount.add(BigNumber.from("5000"))
        );
        await testData.josephDai.setMaxLpAccountContributionAmount(maxLpAccountContributionAmount);

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

        params.totalAmount = maxLpAccountContributionAmount.mul(N1__0_18DEC);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(params.totalAmount, params.openTimestamp);

        //when other user provide liquidity
        await assertError(
            //when
            josephDai
                .connect(userOne)
                .itfProvideLiquidity(params.totalAmount, params.openTimestamp),
            //then
            "IPOR_329"
        );
    });

    it("should NOT provide liquidity because Max Liquidity Pool Account Contribution Amount exceeded - case 1", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );
        const maxLpAccountContributionAmount = BigNumber.from("50000");
        await testData.josephDai.setMaxLiquidityPoolAmount(BigNumber.from("2000000"));
        await testData.josephDai.setMaxLpAccountContributionAmount(maxLpAccountContributionAmount);

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

        params.totalAmount = maxLpAccountContributionAmount
            .add(BigNumber.from("1000"))
            .mul(N1__0_18DEC);

        //when
        await assertError(
            //when
            josephDai
                .connect(liquidityProvider)
                .itfProvideLiquidity(params.totalAmount, params.openTimestamp),
            //then
            "IPOR_330"
        );
    });

    it("should NOT provide liquidity because Max Liquidity Pool Account Contribution Amount exceeded - case 2", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );
        const maxLpAccountContributionAmount = BigNumber.from("50000");
        await testData.josephDai.setMaxLiquidityPoolAmount(BigNumber.from("2000000"));
        await testData.josephDai.setMaxLpAccountContributionAmount(maxLpAccountContributionAmount);

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

        params.totalAmount = maxLpAccountContributionAmount.mul(N1__0_18DEC);

        // first time should pass
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(params.totalAmount, params.openTimestamp);

        //when
        await assertError(
            //when
            josephDai
                .connect(liquidityProvider)
                .itfProvideLiquidity(params.totalAmount, params.openTimestamp),
            //then
            "IPOR_330"
        );
    });

    it("should NOT provide liquidity because Max Liquidity Pool Account Contribution Amount exceeded - case 3", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );
        const maxLpAccountContributionAmount = BigNumber.from("50000");
        await testData.josephDai.setMaxLiquidityPoolAmount(BigNumber.from("2000000"));
        await testData.josephDai.setMaxLpAccountContributionAmount(maxLpAccountContributionAmount);

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

        params.totalAmount = maxLpAccountContributionAmount.mul(N1__0_18DEC);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(params.totalAmount, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfRedeem(params.totalAmount, params.openTimestamp);

        //when
        await assertError(
            //when
            josephDai
                .connect(liquidityProvider)
                .itfProvideLiquidity(params.totalAmount, params.openTimestamp),
            //then
            "IPOR_330"
        );
    });

    it("should NOT provide liquidity because Max Liquidity Pool Account Contribution Amount exceeded - case 4", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );
        const maxLpAccountContributionAmount = BigNumber.from("50000");
        await testData.josephDai.setMaxLiquidityPoolAmount(BigNumber.from("2000000"));
        await testData.josephDai.setMaxLpAccountContributionAmount(maxLpAccountContributionAmount);

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

        params.totalAmount = maxLpAccountContributionAmount.mul(N1__0_18DEC);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(params.totalAmount, params.openTimestamp);

        await ipTokenDai
            .connect(liquidityProvider)
            .transfer(await userThree.getAddress(), params.totalAmount);

        const balance = await ipTokenDai
            .connect(liquidityProvider)
            .balanceOf(await liquidityProvider.getAddress());

        expect(ZERO).to.be.equal(balance);

        //when
        await assertError(
            //when
            josephDai
                .connect(liquidityProvider)
                .itfProvideLiquidity(params.totalAmount, params.openTimestamp),
            //then
            "IPOR_330"
        );
    });
});
