const { expect } = require("chai");
const { ethers } = require("hardhat");

const {
    COLLATERALIZATION_FACTOR_18DEC,
    TOTAL_SUPPLY_18_DECIMALS,
    PERCENTAGE_3_18DEC,
    USD_1_000_18DEC,
    USD_10_000_18DEC,
    USD_19_997_18DEC,
    USD_20_000_18DEC,
    USD_28_000_18DEC,
    USER_SUPPLY_10MLN_18DEC,
    USER_SUPPLY_6_DECIMALS,
} = require("./Const.js");
const {
    assertError,
    prepareData,
    prepareTestData,
    prepareApproveForUsers,
    getStandardDerivativeParamsDAI,
    setupTokenDaiInitialValuesForUsers,
} = require("./Utils");

describe("AssetManagementIntegration", () => {
    let data = null;
    let admin, userOne, userTwo, userThree, liquidityProvider;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] =
            await ethers.getSigners();
        data = await prepareData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            1
        );
    });

    beforeEach(async () => {});

    it("should rebalance - AM Vault ratio > Optimal - deposit to Vault", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0,
            1
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await testData.miltonDai
            .connect(params.from)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor
            );

        const expectedMiltonStableBalance = BigInt("3230000000000000000000");
        //collateral + opening fee + ipor vault interest
        const expectedMiltonLiquidityPoolBalance = BigInt(
            "28032820538384845463609"
        );
        const expectedMiltonAccruedLiquidityPoolBalance =
            expectedMiltonLiquidityPoolBalance + BigInt("3000000000000000000");
        const expectedIporVaultStableBalance = BigInt(
            "34773000000000000000000"
        );

        //when
        await testData.josephDai.connect(userOne).rebalance();

        //then
        const actualMiltonStableBalance = await testData.tokenDai.balanceOf(
            testData.miltonDai.address
        );
        const actualIporVaultStableBalance =
            await testData.iporVaultDai.totalBalance();

        const actualMiltonBalance =
            await testData.miltonStorageDai.getBalance();

        const actualMiltonAccruedBalance =
            await testData.miltonDai.getAccruedBalance();

        expect(
            expectedMiltonStableBalance,
            `Incorrect Milton stables balance`
        ).to.be.eq(actualMiltonStableBalance);

        expect(
            expectedIporVaultStableBalance,
            `Incorrect Ipor Vault stables balance`
        ).to.be.eq(actualIporVaultStableBalance);

        expect(
            expectedMiltonLiquidityPoolBalance,
            `Incorrect Milton Liquidity Pool Balance`
        ).to.be.eq(actualMiltonBalance.liquidityPool);

        expect(
            expectedMiltonAccruedLiquidityPoolBalance,
            `Incorrect Milton Accrued Liquidity Pool Balance`
        ).to.be.eq(actualMiltonAccruedBalance.liquidityPool);
    });

    it("should rebalance - AM Vault ratio < Optimal - withdraw from Vault full amount", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0,
            1
        );

        await testData.tokenDai
            .connect(liquidityProvider)
            .approve(testData.iporVaultDai.address, TOTAL_SUPPLY_18_DECIMALS);

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const params = getStandardDerivativeParamsDAI(userTwo, testData);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_1_000_18DEC, params.openTimestamp);

        await testData.iporVaultDai
            .connect(liquidityProvider)
            .deposit(USD_19_997_18DEC);

        const expectedMiltonStableBalance = BigInt("1785000000000000000000");

        const expectedMiltonLiquidityPoolBalance = BigInt(
            "1003000000000000000000"
        );
        const expectedMiltonAccruedLiquidityPoolBalance =
            expectedMiltonLiquidityPoolBalance + BigInt("3000000000000000000");
        const expectedIporVaultStableBalance = BigInt(
            "19218000000000000000000"
        );

        //when
        await testData.josephDai.connect(userOne).rebalance();

        //then
        const actualMiltonStableBalance = await testData.tokenDai.balanceOf(
            testData.miltonDai.address
        );
        const actualIporVaultStableBalance =
            await testData.iporVaultDai.totalBalance();

        const actualMiltonBalance =
            await testData.miltonStorageDai.getBalance();

        const actualMiltonAccruedBalance =
            await testData.miltonDai.getAccruedBalance();

        expect(
            expectedMiltonStableBalance,
            `Incorrect Milton stables balance`
        ).to.be.eq(actualMiltonStableBalance);

        expect(
            expectedIporVaultStableBalance,
            `Incorrect Ipor Vault stables balance`
        ).to.be.eq(actualIporVaultStableBalance);

        expect(
            expectedMiltonLiquidityPoolBalance,
            `Incorrect Milton Liquidity Pool Balance`
        ).to.be.eq(actualMiltonBalance.liquidityPool);

        expect(
            expectedMiltonAccruedLiquidityPoolBalance,
            `Incorrect Milton Accrued Liquidity Pool Balance`
        ).to.be.eq(actualMiltonAccruedBalance.liquidityPool);
    });
    // it("should rebalance - AM Vault ratio < Optimal - withdraw from Vault part amount", async () => {});

    // it("should calculate current interest - zero because after rebalance", async () => {});
    // it("should calculate current interest - greater than zero", async () => {});

    // it("should calculate current interest - greater than zero", async () => {});
});
