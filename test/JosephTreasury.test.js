const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");

const {
    PERCENTAGE_3_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USD_10_18DEC,
    USD_28_000_18DEC,
    USER_SUPPLY_10MLN_18DEC,
} = require("./Const.js");

const {
    assertError,
    prepareData,
    prepareComplexTestDataDaiCase00,
    prepareComplexTestDataDaiCase40,
    getPayFixedDerivativeParamsDAICase1,
} = require("./Utils");

describe("Joseph Treasury", () => {
    let data = null;
    let admin, userOne, userTwo, userThree, liquidityProvider;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await ethers.getSigners();
        data = await prepareData([admin, userOne, userTwo, userThree, liquidityProvider], 1);
    });

    it("should NOT transfer Publication Fee to Charlie Treasury - caller not publication fee transferer", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase00(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        //when
        await assertError(
            //when
            testData.josephDai.connect(userThree).transferPublicationFee(BigInt("100")),
            //then
            "IPOR_406"
        );
    });

    it("should NOT transfer Publication Fee to Charlie Treasury - Charlie Treasury address incorrect", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase00(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        await testData.josephDai.connect(admin).setPublicationFeeTransferer(userThree.address);

        //when
        await assertError(
            //when
            testData.josephDai.connect(userThree).transferPublicationFee(BigInt("100")),
            //then
            "IPOR_407"
        );
    });

    it("should transfer Publication Fee to Charlie Treasury - simple case 1", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase00(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.toleratedQuoteValue,
                params.collateralizationFactor
            );

        await testData.josephDai.connect(admin).setPublicationFeeTransferer(userThree.address);

        await testData.josephDai.connect(admin).setCharlieTreasurer(userOne.address);

        const transferedValue = BigInt("100");

        //when
        await testData.josephDai.connect(userThree).transferPublicationFee(transferedValue);

        //then
        let balance = await testData.miltonStorageDai.getExtendedBalance();

        let expectedErc20BalanceCharlieTreasurer = USER_SUPPLY_10MLN_18DEC + transferedValue;
        let actualErc20BalanceCharlieTreasurer = BigInt(
            await testData.tokenDai.balanceOf(userOne.address)
        );

        let expectedErc20BalanceMilton =
            USD_28_000_18DEC + TC_TOTAL_AMOUNT_10_000_18DEC - transferedValue;
        let actualErc20BalanceMilton = BigInt(
            await testData.tokenDai.balanceOf(testData.miltonDai.address)
        );

        let expectedPublicationFeeBalanceMilton = USD_10_18DEC - transferedValue;
        const actualPublicationFeeBalanceMilton = BigInt(balance.iporPublicationFee);

        expect(
            expectedErc20BalanceCharlieTreasurer,
            `Incorrect ERC20 Charlie Treasurer balance for ${params.asset}, actual:  ${actualErc20BalanceCharlieTreasurer},
                expected: ${expectedErc20BalanceCharlieTreasurer}`
        ).to.be.eq(actualErc20BalanceCharlieTreasurer);

        expect(
            expectedErc20BalanceMilton,
            `Incorrect ERC20 Milton balance for ${params.asset}, actual:  ${actualErc20BalanceMilton},
                expected: ${expectedErc20BalanceMilton}`
        ).to.be.eq(actualErc20BalanceMilton);

        expect(
            expectedPublicationFeeBalanceMilton,
            `Incorrect Milton balance for ${params.asset}, actual:  ${actualPublicationFeeBalanceMilton},
                expected: ${expectedPublicationFeeBalanceMilton}`
        ).to.be.eq(actualPublicationFeeBalanceMilton);
    });

    it("should NOT transfer Treasure Treasury - caller not treasure transferer", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase00(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        //when
        await assertError(
            //when
            testData.josephDai.connect(userThree).transferTreasury(BigInt("100")),
            //then
            "IPOR_404"
        );
    });

    it("should NOT transfer Publication Fee to Charlie Treasury - Treasure Treasury address incorrect", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase00(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        await testData.josephDai.connect(admin).setTreasureTransferer(userThree.address);

        //when
        await assertError(
            //when
            testData.josephDai.connect(userThree).transferTreasury(BigInt("100")),
            //then
            "IPOR_405"
        );
    });

    it("should transfer Treasury to Treasure Treasurer - simple case 1", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase40(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.toleratedQuoteValue,
                params.collateralizationFactor
            );

        await testData.josephDai.connect(admin).setTreasureTransferer(userThree.address);

        await testData.josephDai.connect(admin).setTreasureTreasurer(userOne.address);

        const transferedValue = BigInt("100");

        //when
        await testData.josephDai.connect(userThree).transferTreasury(transferedValue);

        //then
        let balance = await testData.miltonStorageDai.getExtendedBalance();

        let expectedErc20BalanceTreasureTreasurer = USER_SUPPLY_10MLN_18DEC + transferedValue;
        let actualErc20BalanceTreasureTreasurer = BigInt(
            await testData.tokenDai.balanceOf(userOne.address)
        );

        let expectedErc20BalanceMilton =
            USD_28_000_18DEC + TC_TOTAL_AMOUNT_10_000_18DEC - transferedValue;
        let actualErc20BalanceMilton = BigInt(
            await testData.tokenDai.balanceOf(testData.miltonDai.address)
        );

        let expectedTreasuryBalanceMilton = BigInt("149505148455463261");
        const actualTreasuryBalanceMilton = BigInt(balance.treasury);

        expect(
            expectedErc20BalanceTreasureTreasurer,
            `Incorrect ERC20 Treasury Treasurer balance`
        ).to.be.eq(actualErc20BalanceTreasureTreasurer);

        expect(expectedErc20BalanceMilton, `Incorrect ERC20 Milton balance`).to.be.eq(
            actualErc20BalanceMilton
        );

        expect(expectedTreasuryBalanceMilton, `Incorrect Treasury Balance in Milton`).to.be.eq(
            actualTreasuryBalanceMilton
        );
    });
});
