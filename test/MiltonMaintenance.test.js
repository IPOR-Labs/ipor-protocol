const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");

const {
    USER_SUPPLY_6_DECIMALS,
    USER_SUPPLY_10MLN_18DEC,
    COLLATERALIZATION_FACTOR_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_5_18DEC,
    PERCENTAGE_6_18DEC,
    PERCENTAGE_50_18DEC,
    PERCENTAGE_120_18DEC,
    PERCENTAGE_160_18DEC,
    PERCENTAGE_365_18DEC,
    USD_10_18DEC,
    USD_20_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USD_10_000_6DEC,
    USD_28_000_18DEC,
    USD_28_000_6DEC,
    TC_COLLATERAL_18DEC,
    USD_10_000_000_6DEC,

    USD_10_000_000_18DEC,
    TC_OPENING_FEE_6DEC,
    TC_OPENING_FEE_18DEC,
    TC_LP_BALANCE_BEFORE_CLOSE_6DEC,
    TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
    TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC,
    TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC,
    TC_IPOR_PUBLICATION_AMOUNT_6DEC,
    TC_IPOR_PUBLICATION_AMOUNT_18DEC,
    ZERO,
    SPECIFIC_INTEREST_AMOUNT_CASE_1,
    SPECIFIC_INCOME_TAX_CASE_1,
    PERIOD_25_DAYS_IN_SECONDS,
    PERIOD_14_DAYS_IN_SECONDS,
    PERIOD_50_DAYS_IN_SECONDS,
    TC_INCOME_TAX_18DEC,
    TC_COLLATERAL_6DEC,
} = require("./Const.js");

const {
    assertError,
    getStandardDerivativeParamsDAI,
    getStandardDerivativeParamsUSDT,
    getPayFixedDerivativeParamsDAICase1,
    getPayFixedDerivativeParamsUSDTCase1,
    prepareApproveForUsers,
    prepareData,
    prepareTestData,
    prepareTestDataDaiCase1,
    prepareComplexTestDataDaiCase00,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdtInitialValuesForUsers,
} = require("./Utils");

describe("Milton Maintenance", () => {
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
    //TODO: fix it
    it("should pause Smart Contract, sender is an admin", async () => {
        //when
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            1,
            1
        );
        await testData.miltonDai.connect(admin).pause();

        //then
        await assertError(
            testData.miltonDai.connect(userOne).provideLiquidity(123),
            "Pausable: paused"
        );
    });
    //TODO: fix it
    it("should pause Smart Contract specific methods", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            1,
            1
        );

        //when
        await testData.josephDai.connect(admin).pause();

        //then
        await assertError(
            testData.josephDai.connect(userOne).rebalance(),
            "Pausable: paused"
        );

        await assertError(
            testData.josephDai.connect(userOne).depositToStanley(123),
            "Pausable: paused"
        );

        await assertError(
            testData.josephDai.connect(userOne).withdrawFromStanley(123),
            "Pausable: paused"
        );

        await assertError(
            testData.josephDai.connect(userOne).provideLiquidity(123),
            "Pausable: paused"
        );

        await assertError(
            testData.josephDai.connect(userOne).redeem(123),
            "Pausable: paused"
        );

        await assertError(
            testData.josephDai.connect(userOne).transferTreasury(123),
            "Pausable: paused"
        );

        await assertError(
            testData.josephDai.connect(userOne).transferPublicationFee(123),
            "Pausable: paused"
        );

        await assertError(
            testData.josephDai
                .connect(userOne)
                .setCharlieTreasurer(userTwo.address),
            "Pausable: paused"
        );
        await assertError(
            testData.josephDai
                .connect(userOne)
                .setTreasureTreasurer(userTwo.address),
            "Pausable: paused"
        );
        await assertError(
            testData.josephDai
                .connect(userOne)
                .setPublicationFeeTransferer(userTwo.address),
            "Pausable: paused"
        );
        await assertError(
            testData.josephDai
                .connect(userOne)
                .setTreasureTransferer(userTwo.address),
            "Pausable: paused"
        );
    });
    //TODO: fix it
    it("should NOT pause Smart Contract specific methods when paused", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            1,
            1
        );

        //when
        await testData.josephDai.connect(admin).pause();

        //then
        await testData.josephDai.connect(userOne).getVersion();
        await testData.josephDai.connect(userOne).checkVaultReservesRatio();
        await testData.josephDai.connect(userOne).getCharlieTreasurer();
        await testData.josephDai.connect(userOne).getTreasureTreasurer();
        await testData.josephDai.connect(userOne).getPublicationFeeTransferer();
        await testData.josephDai.connect(userOne).getTreasureTransferer();
        await testData.josephDai
            .connect(userOne)
            .getRedeemLpMaxUtilizationPercentage();
        await testData.josephDai
            .connect(userOne)
            .getMiltonStanleyBalancePercentage();
        await testData.josephDai.connect(userOne).decimals();
        await testData.josephDai.connect(userOne).asset();
    });
    //TODO: fix it
    it("should NOT pause Smart Contract, sender is NOT an admin", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        //when
        await assertError(
            testData.josephDai.connect(userThree).pause(),
            //then
            "Ownable: caller is not the owner"
        );
    });
    //TODO: fix it
    it("should unpause Smart Contract, sender is an admin", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase00(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        await testData.josephDai.connect(admin).pause();

        await assertError(
            testData.josephDai.connect(userOne).provideLiquidity(123),
            "Pausable: paused"
        );

        const expectedIpTokenBalance = BigInt("123");

        //when
        await testData.josephDai.connect(admin).unpause();
        await testData.josephDai.connect(userOne).provideLiquidity(123);

        //then
        const actualIpTokenBalance = BigInt(
            await testData.ipTokenDai.balanceOf(userOne.address)
        );
        expect(actualIpTokenBalance, "Incorrect IpToken balance.").to.be.eql(
            expectedIpTokenBalance
        );
    });

    //TODO: fix it
    it("should NOT unpause Smart Contract, sender is NOT an admin", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        await testData.josephDai.connect(admin).pause();

        //when
        await assertError(
            testData.josephDai.connect(userThree).unpause(),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should transfer ownership - simple case 1", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        //when
        await testData.miltonDai
            .connect(admin)
            .transferOwnership(expectedNewOwner.address);

        await testData.miltonDai
            .connect(expectedNewOwner)
            .confirmTransferOwnership();

        //then
        const actualNewOwner = await testData.miltonDai
            .connect(userOne)
            .owner();
        expect(expectedNewOwner.address).to.be.eql(actualNewOwner);
    });

    it("should NOT transfer ownership - sender not current owner", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        //when
        await assertError(
            testData.miltonDai
                .connect(userThree)
                .transferOwnership(expectedNewOwner.address),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT confirm transfer ownership - sender not appointed owner", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        //when
        await testData.miltonDai
            .connect(admin)
            .transferOwnership(expectedNewOwner.address);

        await assertError(
            testData.miltonDai.connect(userThree).confirmTransferOwnership(),
            //then
            "IPOR_6"
        );
    });

    it("should NOT confirm transfer ownership twice - sender not appointed owner", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        //when
        await testData.miltonDai
            .connect(admin)
            .transferOwnership(expectedNewOwner.address);

        await testData.miltonDai
            .connect(expectedNewOwner)
            .confirmTransferOwnership();

        await assertError(
            testData.miltonDai
                .connect(expectedNewOwner)
                .confirmTransferOwnership(),
            "IPOR_6"
        );
    });

    it("should NOT transfer ownership - sender already lost ownership", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        await testData.miltonDai
            .connect(admin)
            .transferOwnership(expectedNewOwner.address);

        await testData.miltonDai
            .connect(expectedNewOwner)
            .confirmTransferOwnership();

        //when
        await assertError(
            testData.miltonDai
                .connect(admin)
                .transferOwnership(expectedNewOwner.address),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should have rights to transfer ownership - sender still have rights", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        await testData.miltonDai
            .connect(admin)
            .transferOwnership(expectedNewOwner.address);

        //when
        await testData.miltonDai
            .connect(admin)
            .transferOwnership(expectedNewOwner.address);

        //then
        const actualNewOwner = await testData.miltonDai
            .connect(userOne)
            .owner();
        expect(admin.address).to.be.eql(actualNewOwner);
    });
});
