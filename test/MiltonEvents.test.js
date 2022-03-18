const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");

const {
    PERCENTAGE_3_18DEC,
    PERCENTAGE_5_18DEC,
    PERCENTAGE_160_18DEC,
    USD_28_000_18DEC,
    USD_28_000_6DEC,
    PERIOD_28_DAYS_IN_SECONDS,
} = require("./Const.js");

const {
    getPayFixedDerivativeParamsDAICase1,
    getPayFixedDerivativeParamsUSDTCase1,
    prepareData,
    prepareComplexTestDataDaiCase000,
    prepareComplexTestDataUsdtCase000,
} = require("./Utils");

describe("Milton Events", () => {
    let data = null;
    let admin, userOne, userTwo, userThree, liquidityProvider;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await ethers.getSigners();
        data = await prepareData([admin, userOne, userTwo, userThree, liquidityProvider], 1);
    });

    it("should emit event when open Pay Fixed Swap - 18 decimals", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
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

        await expect(
            testData.miltonDai
                .connect(userTwo)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
                    params.leverage
                )
        )
            .to.emit(testData.miltonDai, "OpenSwap")
            .withArgs(
                BigInt("1"),
                userTwo.address,
                params.asset,
                0,
                [
                    BigInt("10000000000000000000000"),
                    BigInt("9967009897030890732780"),
                    BigInt("99670098970308907327800"),
                    BigInt("2990102969109267220"),
                    BigInt("10000000000000000000"),
                    BigInt("20000000000000000000"),
                ],
                params.openTimestamp,
                params.openTimestamp + PERIOD_28_DAYS_IN_SECONDS,
                [
                    BigInt("30000000000000000"),
                    BigInt("1000000000000000000"),
                    BigInt("99670098970308907327800"),
                    BigInt("40000000000000000"),
                ]
            );
    });

    it("should emit event when open Receive Fixed Swap - 18 decimals", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
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

        await expect(
            testData.miltonDai
                .connect(userTwo)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
                    params.leverage
                )
        )
            .to.emit(testData.miltonDai, "OpenSwap")
            .withArgs(
                BigInt("1"),
                userTwo.address,
                params.asset,
                1,
                [
                    BigInt("10000000000000000000000"),
                    BigInt("9967009897030890732780"),
                    BigInt("99670098970308907327800"),
                    BigInt("2990102969109267220"),
                    BigInt("10000000000000000000"),
                    BigInt("20000000000000000000"),
                ],
                params.openTimestamp,
                params.openTimestamp + PERIOD_28_DAYS_IN_SECONDS,
                [
                    BigInt("30000000000000000"),
                    BigInt("1000000000000000000"),
                    BigInt("99670098970308907327800"),
                    BigInt("20000000000000000"),
                ]
            );
    });

    it("should emit event when open Pay Fixed Swap - 6 decimals", async () => {
        //given
        const testData = await prepareComplexTestDataUsdtCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = getPayFixedDerivativeParamsUSDTCase1(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);
        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, params.openTimestamp);

        await expect(
            testData.miltonUsdt
                .connect(userTwo)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
                    params.leverage
                )
        )
            .to.emit(testData.miltonUsdt, "OpenSwap")
            .withArgs(
                BigInt("1"),
                userTwo.address,
                params.asset,
                0,
                [
                    BigInt("10000000000000000000000"),
                    BigInt("9967009897030890732780"),
                    BigInt("99670098970308907327800"),
                    BigInt("2990102969109267220"),
                    BigInt("10000000000000000000"),
                    BigInt("20000000000000000000"),
                ],
                params.openTimestamp,
                params.openTimestamp + PERIOD_28_DAYS_IN_SECONDS,
                [
                    BigInt("30000000000000000"),
                    BigInt("1000000000000000000"),
                    BigInt("99670098970308907327800"),
                    BigInt("40000000000000000"),
                ]
            );
    });

    it("should emit event when open Receive Fixed Swap - 6 decimals", async () => {
        //given
        const testData = await prepareComplexTestDataUsdtCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = getPayFixedDerivativeParamsUSDTCase1(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);
        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, params.openTimestamp);

        await expect(
            testData.miltonUsdt
                .connect(userTwo)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
                    params.leverage
                )
        )
            .to.emit(testData.miltonUsdt, "OpenSwap")
            .withArgs(
                BigInt("1"),
                userTwo.address,
                params.asset,
                1,
                [
                    BigInt("10000000000000000000000"),
                    BigInt("9967009897030890732780"),
                    BigInt("99670098970308907327800"),
                    BigInt("2990102969109267220"),
                    BigInt("10000000000000000000"),
                    BigInt("20000000000000000000"),
                ],
                params.openTimestamp,
                params.openTimestamp + PERIOD_28_DAYS_IN_SECONDS,
                [
                    BigInt("30000000000000000"),
                    BigInt("1000000000000000000"),
                    BigInt("99670098970308907327800"),
                    BigInt("20000000000000000"),
                ]
            );
    });

    it("should emit event when close Pay Fixed Swap - 18 decimals", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.toleratedQuoteValue,
                params.leverage
            );

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_160_18DEC, params.openTimestamp);

        await expect(
            testData.miltonDai
                .connect(userTwo)
                .itfCloseSwapPayFixed(1, params.openTimestamp + PERIOD_28_DAYS_IN_SECONDS)
        )
            .to.emit(testData.miltonDai, "CloseSwap")
            .withArgs(
                BigInt("1"),
                params.asset,
                params.openTimestamp + PERIOD_28_DAYS_IN_SECONDS,
                userTwo.address,
                BigInt("18957318804358692392282"),
                BigInt("0")
            );
    });

    it("should emit event when close Pay Fixed Swap - 6 decimals - taker closed swap", async () => {
        //given
        const testData = await prepareComplexTestDataUsdtCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = getPayFixedDerivativeParamsUSDTCase1(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, params.openTimestamp);

        await testData.miltonUsdt
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.toleratedQuoteValue,
                params.leverage
            );

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_160_18DEC, params.openTimestamp);

        await expect(
            testData.miltonUsdt
                .connect(userTwo)
                .itfCloseSwapPayFixed(1, params.openTimestamp + PERIOD_28_DAYS_IN_SECONDS)
        )
            .to.emit(testData.miltonUsdt, "CloseSwap")
            .withArgs(
                BigInt("1"),
                params.asset,
                params.openTimestamp + PERIOD_28_DAYS_IN_SECONDS,
                userTwo.address,
                BigInt("18957318804000000000000"),
                BigInt("0")
            );
    });

    it("should emit event when close Pay Fixed Swap - 6 decimals - NOT taker closed swap", async () => {
        //given
        const testData = await prepareComplexTestDataUsdtCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = getPayFixedDerivativeParamsUSDTCase1(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, params.openTimestamp);

        await testData.miltonUsdt
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.toleratedQuoteValue,
                params.leverage
            );

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_160_18DEC, params.openTimestamp);

        await expect(
            testData.miltonUsdt
                .connect(userThree)
                .itfCloseSwapPayFixed(1, params.openTimestamp + PERIOD_28_DAYS_IN_SECONDS)
        )
            .to.emit(testData.miltonUsdt, "CloseSwap")
            .withArgs(
                BigInt("1"),
                params.asset,
                params.openTimestamp + PERIOD_28_DAYS_IN_SECONDS,
                userThree.address,
                BigInt("18937318804000000000000"),
                BigInt("20000000000000000000")
            );
    });
});
