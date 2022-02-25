const { expect } = require("chai");
const { ethers } = require("hardhat");

const {
    COLLATERALIZATION_FACTOR_18DEC,
    TOTAL_SUPPLY_18_DECIMALS,
    PERCENTAGE_3_18DEC,
    USD_10_000_18DEC,
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

    it("should rebalance - AM Vault ration > Optimal - deposit to Vault", async () => {
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

        const expectedMiltonStableBalance = BigInt("38000000000000000000000");

        //when
        await testData.josephDai.connect(userOne).rebalance();

        //then
        //1. sprawdz tokeny na miltonie
        //2. sprawdz LP balance na miltonie
        //3. odczytaj runtime LPBalance
    });
    it("should rebalance - AM Vault ration < Optimal - withdraw from Vault full amount", async () => {});
    it("should rebalance - AM Vault ration < Optimal - withdraw from Vault part amount", async () => {});

    it("should calculate current interest - zero because after rebalance", async () => {});
    it("should calculate current interest - greater than zero", async () => {});

    it("should calculate current interest - greater than zero", async () => {});
});
