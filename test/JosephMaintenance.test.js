const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");

const {
    PERCENTAGE_2_5_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_8_18DEC,
    PERCENTAGE_50_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USD_14_000_18DEC,
    USD_14_000_6DEC,
    ZERO,
    PERIOD_25_DAYS_IN_SECONDS,
} = require("./Const.js");

const {
    assertError,
    getStandardDerivativeParamsDAI,
    getStandardDerivativeParamsUSDT,
    prepareApproveForUsers,
    prepareData,
    prepareTestData,
    prepareComplexTestDataDaiCase000,
    prepareTestDataUsdtCase1,
    prepareTestDataDaiCase000,
    setupIpTokenDaiInitialValues,
    setupIpTokenUsdtInitialValues,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdtInitialValuesForUsers,
} = require("./Utils");

describe("Joseph Maintenance", () => {
    let data = null;
    let admin, userOne, userTwo, userThree, liquidityProvider;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await ethers.getSigners();
        data = await prepareData([admin, userOne, userTwo, userThree, liquidityProvider], 1);
    });

    it("should pause Smart Contract, sender is an admin", async () => {
        //when
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            1,
            1,
            0
        );
        await testData.josephDai.connect(admin).pause();

        //then
        await assertError(
            testData.josephDai.connect(userOne).provideLiquidity(123),
            "Pausable: paused"
        );
    });

    it("should pause Smart Contract specific methods", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            1,
            1,
            0
        );

        //when
        await testData.josephDai.connect(admin).pause();

        //then
        await assertError(testData.josephDai.connect(userOne).rebalance(), "Pausable: paused");

        await assertError(
            testData.josephDai.connect(admin).depositToStanley(123),
            "Pausable: paused"
        );

        await assertError(
            testData.josephDai.connect(admin).withdrawFromStanley(123),
            "Pausable: paused"
        );

        await assertError(
            testData.josephDai.connect(userOne).provideLiquidity(123),
            "Pausable: paused"
        );

        await assertError(testData.josephDai.connect(userOne).redeem(123), "Pausable: paused");

        await assertError(
            testData.josephDai.connect(userOne).transferToTreasury(123),
            "Pausable: paused"
        );

        await assertError(
            testData.josephDai.connect(userOne).transferToCharlieTreasury(123),
            "Pausable: paused"
        );

        await assertError(
            testData.josephDai.connect(admin).setCharlieTreasury(userTwo.address),
            "Pausable: paused"
        );
        await assertError(
            testData.josephDai.connect(admin).setTreasury(userTwo.address),
            "Pausable: paused"
        );
        await assertError(
            testData.josephDai.connect(admin).setCharlieTreasuryManager(userTwo.address),
            "Pausable: paused"
        );
        await assertError(
            testData.josephDai.connect(admin).setTreasuryManager(userTwo.address),
            "Pausable: paused"
        );
    });

    it("should NOT pause Smart Contract specific methods when paused", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const timestamp = Math.floor(Date.now() / 1000);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(TC_TOTAL_AMOUNT_10_000_18DEC, timestamp);

        //when
        await testData.josephDai.connect(admin).pause();

        //then
        await testData.josephDai.connect(userOne).getVersion();
        await testData.josephDai.connect(userOne).checkVaultReservesRatio();
        await testData.josephDai.connect(userOne).getCharlieTreasury();
        await testData.josephDai.connect(userOne).getTreasury();
        await testData.josephDai.connect(userOne).getCharlieTreasuryManager();
        await testData.josephDai.connect(userOne).getTreasuryManager();
        await testData.josephDai.connect(userOne).getRedeemLpMaxUtilizationPercentage();
        await testData.josephDai.connect(userOne).getMiltonStanleyBalancePercentage();
        await testData.josephDai.connect(userOne).asset();
        await testData.josephDai.connect(userOne).calculateExchangeRate();
    });

    it("should NOT pause Smart Contract, sender is NOT an admin", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
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

    it("should unpause Smart Contract, sender is an admin", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
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
        const actualIpTokenBalance = BigInt(await testData.ipTokenDai.balanceOf(userOne.address));
        expect(actualIpTokenBalance, "Incorrect IpToken balance.").to.be.eql(
            expectedIpTokenBalance
        );
    });

    it("should NOT unpause Smart Contract, sender is NOT an admin", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
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
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        //when
        await testData.josephDai.connect(admin).transferOwnership(expectedNewOwner.address);

        await testData.josephDai.connect(expectedNewOwner).confirmTransferOwnership();

        //then
        const actualNewOwner = await testData.josephDai.connect(userOne).owner();
        expect(expectedNewOwner.address).to.be.eql(actualNewOwner);
    });

    it("should NOT transfer ownership - sender not current owner", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        //when
        await assertError(
            testData.josephDai.connect(userThree).transferOwnership(expectedNewOwner.address),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT confirm transfer ownership - sender not appointed owner", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        //when
        await testData.josephDai.connect(admin).transferOwnership(expectedNewOwner.address);

        await assertError(
            testData.josephDai.connect(userThree).confirmTransferOwnership(),
            //then
            "IPOR_007"
        );
    });

    it("should NOT confirm transfer ownership twice - sender not appointed owner", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        //when
        await testData.josephDai.connect(admin).transferOwnership(expectedNewOwner.address);

        await testData.josephDai.connect(expectedNewOwner).confirmTransferOwnership();

        await assertError(
            testData.josephDai.connect(expectedNewOwner).confirmTransferOwnership(),
            "IPOR_007"
        );
    });

    it("should NOT transfer ownership - sender already lost ownership", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        await testData.josephDai.connect(admin).transferOwnership(expectedNewOwner.address);

        await testData.josephDai.connect(expectedNewOwner).confirmTransferOwnership();

        //when
        await assertError(
            testData.josephDai.connect(admin).transferOwnership(expectedNewOwner.address),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should have rights to transfer ownership - sender still have rights", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        await testData.josephDai.connect(admin).transferOwnership(expectedNewOwner.address);

        //when
        await testData.josephDai.connect(admin).transferOwnership(expectedNewOwner.address);

        //then
        const actualNewOwner = await testData.josephDai.connect(userOne).owner();
        expect(admin.address).to.be.eql(actualNewOwner);
    });

    it("should not sent ETH to Joseph DAI, USDT, USDC", async () => {
        //given
        const testData = await prepareTestData([admin], ["DAI", "USDT", "USDC"], data, 0, 0, 0);

        await assertError(
            //when
            admin.sendTransaction({
                to: testData.josephDai.address,
                value: ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );

        await assertError(
            //when
            admin.sendTransaction({
                to: testData.josephUsdt.address,
                value: ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );

        await assertError(
            //when
            admin.sendTransaction({
                to: testData.josephUsdc.address,
                value: ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
    });
});
