import hre from "hardhat";
import chai from "chai";
import { Signer } from "ethers";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
    prepareMockMiltonSpreadModel,
} from "./utils/MiltonUtils";
import { assertError } from "./utils/AssertUtils";
import { MockStanleyCase } from "./utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "./utils/JosephUtils";
import {
    prepareTestData,
    prepareApproveForUsers,
    setupTokenDaiInitialValuesForUsers,
} from "./utils/DataUtils";
import {
    TOTAL_SUPPLY_18_DECIMALS,
    USD_3_18DEC,
    USD_1_000_18DEC,
    USD_19_997_18DEC,
    USD_20_000_18DEC,
} from "./utils/Constants";
const { expect } = chai;

describe("Stanley - Asset Management Vault", () => {
    let mockMiltonSpreadModel: MockMiltonSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        mockMiltonSpreadModel = await prepareMockMiltonSpreadModel(MiltonSpreadModels.CASE1);
    });

    it("should rebalance - AM Vault ratio > Optimal - deposit to Vault", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            mockMiltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        const { tokenDai, josephDai, miltonDai, stanleyDai, miltonStorageDai } = testData;

        if (
            tokenDai == undefined ||
            josephDai == undefined ||
            miltonDai == undefined ||
            stanleyDai == undefined ||
            miltonStorageDai == undefined
        ) {
            expect(true).to.be.false;
            return;
        }
        await tokenDai
            .connect(liquidityProvider)
            .approve(stanleyDai.address, TOTAL_SUPPLY_18_DECIMALS);

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const timestamp = Math.floor(Date.now() / 1000);

        await josephDai.connect(liquidityProvider).itfProvideLiquidity(USD_20_000_18DEC, timestamp);
        await josephDai.connect(admin).depositToStanley(USD_1_000_18DEC);

        //Force deposit to simulate that IporVault earn money for Milton $3
        await stanleyDai.connect(liquidityProvider).testDeposit(miltonDai.address, USD_3_18DEC);

        const expectedMiltonStableBalance = BigInt("1700255000000000000000");
        //collateral + opening fee + ipor vault interest
        const expectedMiltonLiquidityPoolBalance = BigInt("20003000000000000000000");

        const expectedIporVaultStableBalance = BigInt("18302745000000000000000");

        //when
        await josephDai.connect(admin).rebalance();

        //then
        const actualMiltonStableBalance = await tokenDai.balanceOf(miltonDai.address);
        const actualIporVaultStableBalance = await stanleyDai.totalBalance(miltonDai.address);
        const actualMiltonBalance = await miltonStorageDai.getBalance();
        const actualMiltonAccruedBalance = await miltonDai.getAccruedBalance();

        expect(expectedMiltonStableBalance, `Incorrect Milton stables balance`).to.be.eq(
            actualMiltonStableBalance
        );

        expect(expectedIporVaultStableBalance, `Incorrect Ipor Vault stables balance`).to.be.eq(
            actualIporVaultStableBalance
        );

        expect(
            expectedMiltonLiquidityPoolBalance,
            `Incorrect Milton Liquidity Pool Balance`
        ).to.be.eq(actualMiltonBalance.liquidityPool);

        //Notice! In this specific case IporVault mock returns totalBalance without any interest so balance = accrued balance
        expect(
            expectedMiltonLiquidityPoolBalance,
            `Incorrect Milton Accrued Liquidity Pool Balance`
        ).to.be.eq(actualMiltonAccruedBalance.liquidityPool);
    });

    it("should rebalance - AM Vault ratio < Optimal - withdraw from Vault part amount", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            mockMiltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE2,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        const { tokenDai, josephDai, miltonDai, stanleyDai, miltonStorageDai } = testData;

        if (
            tokenDai == undefined ||
            josephDai == undefined ||
            miltonDai == undefined ||
            stanleyDai == undefined ||
            miltonStorageDai == undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await tokenDai
            .connect(liquidityProvider)
            .approve(stanleyDai.address, TOTAL_SUPPLY_18_DECIMALS);

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const timestamp = Math.floor(Date.now() / 1000);

        await josephDai.connect(liquidityProvider).itfProvideLiquidity(USD_1_000_18DEC, timestamp);

        await tokenDai.transfer(miltonDai.address, USD_19_997_18DEC);

        await josephDai.connect(admin).depositToStanley(USD_19_997_18DEC);

        //Force deposit to simulate that IporVault earn money for Milton $3
        await stanleyDai.connect(liquidityProvider).testDeposit(miltonDai.address, USD_3_18DEC);

        const expectedMiltonStableBalance = BigInt("1628000000000000000000");

        const expectedMiltonLiquidityPoolBalance = BigInt("1003000000000000000000");

        const expectedIporVaultStableBalance = BigInt("19372000000000000000000");

        //when
        await josephDai.connect(admin).rebalance();

        //then
        const actualMiltonStableBalance = await tokenDai.balanceOf(miltonDai.address);
        const actualIporVaultStableBalance = await stanleyDai.totalBalance(miltonDai.address);

        const actualMiltonBalance = await miltonStorageDai.getBalance();

        const actualMiltonAccruedBalance = await miltonDai.getAccruedBalance();

        expect(expectedMiltonStableBalance, `Incorrect Milton stables balance`).to.be.eq(
            actualMiltonStableBalance
        );

        expect(expectedIporVaultStableBalance, `Incorrect Ipor Vault stables balance`).to.be.eq(
            actualIporVaultStableBalance
        );

        expect(
            expectedMiltonLiquidityPoolBalance,
            `Incorrect Milton Liquidity Pool Balance`
        ).to.be.eq(actualMiltonBalance.liquidityPool);

        //Notice! In this specific case IporVault mock returns totalBalance without any interest so balance = accrued balance
        expect(
            expectedMiltonLiquidityPoolBalance,
            `Incorrect Milton Accrued Liquidity Pool Balance`
        ).to.be.eq(actualMiltonAccruedBalance.liquidityPool);
    });

    it("should rebalance - AM Vault ratio < Optimal - withdraw from Vault part amount", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            mockMiltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE2,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        const { tokenDai, josephDai, miltonDai, stanleyDai, miltonStorageDai } = testData;

        if (
            tokenDai == undefined ||
            josephDai == undefined ||
            miltonDai == undefined ||
            stanleyDai == undefined ||
            miltonStorageDai == undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await tokenDai
            .connect(liquidityProvider)
            .approve(stanleyDai.address, TOTAL_SUPPLY_18_DECIMALS);

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const timestamp = Math.floor(Date.now() / 1000);

        await josephDai.connect(liquidityProvider).itfProvideLiquidity(USD_1_000_18DEC, timestamp);

        await tokenDai.transfer(miltonDai.address, USD_19_997_18DEC);

        await josephDai.connect(admin).depositToStanley(USD_19_997_18DEC);

        //Force deposit to simulate that IporVault earn money for Milton $3
        await stanleyDai.connect(liquidityProvider).testDeposit(miltonDai.address, USD_3_18DEC);

        const expectedMiltonStableBalance = BigInt("1628000000000000000000");

        const expectedMiltonLiquidityPoolBalance = BigInt("1003000000000000000000");

        const expectedIporVaultStableBalance = BigInt("19372000000000000000000");

        //when
        await josephDai.connect(admin).rebalance();

        //then
        const actualMiltonStableBalance = await tokenDai.balanceOf(miltonDai.address);
        const actualIporVaultStableBalance = await stanleyDai.totalBalance(miltonDai.address);

        const actualMiltonBalance = await miltonStorageDai.getBalance();

        const actualMiltonAccruedBalance = await miltonDai.getAccruedBalance();

        expect(expectedMiltonStableBalance, `Incorrect Milton stables balance`).to.be.eq(
            actualMiltonStableBalance
        );

        expect(expectedIporVaultStableBalance, `Incorrect Ipor Vault stables balance`).to.be.eq(
            actualIporVaultStableBalance
        );

        expect(
            expectedMiltonLiquidityPoolBalance,
            `Incorrect Milton Liquidity Pool Balance`
        ).to.be.eq(actualMiltonBalance.liquidityPool);

        //Notice! In this specific case IporVault mock returns totalBalance without any interest so balance = accrued balance
        expect(
            expectedMiltonLiquidityPoolBalance,
            `Incorrect Milton Accrued Liquidity Pool Balance`
        ).to.be.eq(actualMiltonAccruedBalance.liquidityPool);
    });

    it("should withdraw All FromStanley", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            mockMiltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE2,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        const { tokenDai, josephDai, miltonDai, stanleyDai, miltonStorageDai } = testData;

        if (
            tokenDai == undefined ||
            josephDai == undefined ||
            miltonDai == undefined ||
            stanleyDai == undefined ||
            miltonStorageDai == undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await tokenDai
            .connect(liquidityProvider)
            .approve(stanleyDai.address, TOTAL_SUPPLY_18_DECIMALS);

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const timestamp = Math.floor(Date.now() / 1000);

        await josephDai.connect(liquidityProvider).itfProvideLiquidity(USD_1_000_18DEC, timestamp);

        await tokenDai.transfer(miltonDai.address, USD_19_997_18DEC);

        await josephDai.connect(admin).depositToStanley(USD_19_997_18DEC);

        //Force deposit to simulate that IporVault earn money for Milton $3
        await stanleyDai.connect(liquidityProvider).testDeposit(miltonDai.address, USD_3_18DEC);

        const stanleyBalanceBefore = await stanleyDai.totalBalance(miltonDai.address);

        //when
        await josephDai.connect(admin).withdrawAllFromStanley();

        //then
        const stanleyBalanceAfter = await stanleyDai.totalBalance(miltonDai.address);

        expect(stanleyBalanceBefore.gt(stanleyBalanceAfter)).to.be.true;
    });

    it("should not sent ETH to Stanley DAI, USDT, USDC", async () => {
        //given
        const testData = await prepareTestData(
            [admin],
            ["DAI", "USDT", "USDC"],
            mockMiltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE0,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        const { stanleyDai, stanleyUsdt, stanleyUsdc } = testData;

        if (stanleyDai == undefined || stanleyUsdt == undefined || stanleyUsdc == undefined) {
            expect(true).to.be.false;
            return;
        }

        await assertError(
            //when
            admin.sendTransaction({
                to: stanleyDai.address,
                value: hre.ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );

        await assertError(
            //when
            admin.sendTransaction({
                to: stanleyUsdt.address,
                value: hre.ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );

        await assertError(
            //when
            admin.sendTransaction({
                to: stanleyUsdc.address,
                value: hre.ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
    });
});
