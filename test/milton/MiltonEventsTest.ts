import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    PERCENTAGE_3_18DEC,
    USD_28_000_18DEC,
    PERIOD_28_DAYS_IN_SECONDS,
    N1__0_18DEC,
    ZERO,
    N0__01_18DEC,
    USD_28_000_6DEC,
    PERCENTAGE_160_18DEC,
    PERCENTAGE_5_18DEC,
} from "../utils/Constants";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    prepareMockMiltonSpreadModel,
} from "../utils/MiltonUtils";
import {
    prepareComplexTestDataDaiCase000,
    getPayFixedDerivativeParamsDAICase1,
    getReceiveFixedDerivativeParamsDAICase1,
    prepareComplexTestDataUsdtCase000,
    getPayFixedDerivativeParamsUSDTCase1,
    getReceiveFixedDerivativeParamsUSDTCase1,
} from "../utils/DataUtils";

const { expect } = chai;

describe("Milton Events", () => {
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

    it("should emit event when open Pay Fixed Swap - 18 decimals", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, miltonDai, iporOracle } = testData;

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await expect(
            miltonDai
                .connect(userTwo)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.acceptableFixedInterestRate,
                    params.leverage
                )
        )
            .to.emit(miltonDai, "OpenSwap")
            .withArgs(
                BigNumber.from("1"),
                await userTwo.getAddress(),
                params.asset,
                0,
                [
                    BigNumber.from("10000").mul(N1__0_18DEC),
                    BigNumber.from("9967009897030890732780"),
                    BigNumber.from("99670098970308907327800"),
                    BigNumber.from("2990102969109267220"),
                    BigNumber.from("0"),
                    BigNumber.from("10").mul(N1__0_18DEC),
                    BigNumber.from("20").mul(N1__0_18DEC),
                ],
                params.openTimestamp,
                params.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS),
                [
                    BigNumber.from("3").mul(N0__01_18DEC),
                    BigNumber.from("1").mul(N1__0_18DEC),
                    BigNumber.from("99670098970308907327800"),
                    BigNumber.from("4").mul(N0__01_18DEC),
                ]
            );
    });

    it("should emit event when open Receive Fixed Swap - 18 decimals", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        const { tokenDai, josephDai, miltonDai, iporOracle } = testData;

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await expect(
            miltonDai
                .connect(userTwo)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.acceptableFixedInterestRate,
                    params.leverage
                )
        )
            .to.emit(miltonDai, "OpenSwap")
            .withArgs(
                BigNumber.from("1"),
                await userTwo.getAddress(),
                params.asset,
                1,
                [
                    BigNumber.from("10000").mul(N1__0_18DEC),
                    BigNumber.from("9967009897030890732780"),
                    BigNumber.from("99670098970308907327800"),
                    BigNumber.from("2990102969109267220"),
                    ZERO,
                    BigNumber.from("10").mul(N1__0_18DEC),
                    BigNumber.from("20").mul(N1__0_18DEC),
                ],
                params.openTimestamp,
                params.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS),
                [
                    BigNumber.from("3").mul(N0__01_18DEC),
                    BigNumber.from("1").mul(N1__0_18DEC),
                    BigNumber.from("99670098970308907327800"),
                    BigNumber.from("2").mul(N0__01_18DEC),
                ]
            );
    });

    it("should emit event when open Pay Fixed Swap - 6 decimals", async () => {
        //given
        const testData = await prepareComplexTestDataUsdtCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenUsdt, josephUsdt, miltonUsdt, iporOracle } = testData;

        if (tokenUsdt === undefined || josephUsdt === undefined || miltonUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getPayFixedDerivativeParamsUSDTCase1(userTwo, tokenUsdt);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);
        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, params.openTimestamp);

        await expect(
            miltonUsdt
                .connect(userTwo)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.acceptableFixedInterestRate,
                    params.leverage
                )
        )
            .to.emit(miltonUsdt, "OpenSwap")
            .withArgs(
                BigNumber.from("1"),
                await userTwo.getAddress(),
                params.asset,
                0,
                [
                    BigNumber.from("10000").mul(N1__0_18DEC),

                    BigNumber.from("9967009897030890732780"),
                    BigNumber.from("99670098970308907327800"),
                    BigNumber.from("2990102969109267220"),
                    ZERO,
                    BigNumber.from("10").mul(N1__0_18DEC),
                    BigNumber.from("20").mul(N1__0_18DEC),
                ],
                params.openTimestamp,
                params.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS),
                [
                    BigNumber.from("3").mul(N0__01_18DEC),
                    N1__0_18DEC,
                    BigNumber.from("99670098970308907327800"),
                    BigNumber.from("4").mul(N0__01_18DEC),
                ]
            );
    });

    it("should emit event when open Receive Fixed Swap - 6 decimals", async () => {
        //given
        const testData = await prepareComplexTestDataUsdtCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenUsdt, josephUsdt, miltonUsdt, iporOracle } = testData;

        if (tokenUsdt === undefined || josephUsdt === undefined || miltonUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }
        const params = getReceiveFixedDerivativeParamsUSDTCase1(userTwo, tokenUsdt);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);
        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, params.openTimestamp);

        await expect(
            miltonUsdt
                .connect(userTwo)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.acceptableFixedInterestRate,
                    params.leverage
                )
        )
            .to.emit(miltonUsdt, "OpenSwap")
            .withArgs(
                BigNumber.from("1"),
                await userTwo.getAddress(),
                params.asset,
                1,
                [
                    BigNumber.from("10000").mul(N1__0_18DEC),
                    BigNumber.from("9967009897030890732780"),
                    BigNumber.from("99670098970308907327800"),
                    BigNumber.from("2990102969109267220"),
                    ZERO,
                    BigNumber.from("10").mul(N1__0_18DEC),
                    BigNumber.from("20").mul(N1__0_18DEC),
                ],
                params.openTimestamp,
                params.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS),
                [
                    BigNumber.from("3").mul(N0__01_18DEC),
                    N1__0_18DEC,
                    BigNumber.from("99670098970308907327800"),
                    BigNumber.from("2").mul(N0__01_18DEC),
                ]
            );
    });

    it("should emit event when close Pay Fixed Swap - 18 decimals", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, miltonDai, iporOracle } = testData;

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.acceptableFixedInterestRate,
                params.leverage
            );

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_160_18DEC, params.openTimestamp);

        await expect(
            miltonDai
                .connect(userTwo)
                .itfCloseSwapPayFixed(1, params.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS))
        )
            .to.emit(miltonDai, "CloseSwap")
            .withArgs(
                BigNumber.from("1"),
                params.asset,
                params.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS),
                await userTwo.getAddress(),
                BigNumber.from("18957318804358692392282"),
                ZERO
            );
    });

    it("should emit event when close Pay Fixed Swap - 6 decimals - taker closed swap", async () => {
        //given
        const testData = await prepareComplexTestDataUsdtCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenUsdt, josephUsdt, miltonUsdt, iporOracle } = testData;

        if (tokenUsdt === undefined || josephUsdt === undefined || miltonUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getPayFixedDerivativeParamsUSDTCase1(userTwo, tokenUsdt);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);

        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, params.openTimestamp);

        await miltonUsdt
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.acceptableFixedInterestRate,
                params.leverage
            );

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_160_18DEC, params.openTimestamp);

        await expect(
            miltonUsdt
                .connect(userTwo)
                .itfCloseSwapPayFixed(1, params.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS))
        )
            .to.emit(miltonUsdt, "CloseSwap")
            .withArgs(
                BigNumber.from("1"),
                params.asset,
                params.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS),
                await userTwo.getAddress(),
                BigNumber.from("18957318804000000000000"),
                ZERO
            );
    });

    it("should emit event when close Pay Fixed Swap - 6 decimals - NOT taker closed swap", async () => {
        //given
        const testData = await prepareComplexTestDataUsdtCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenUsdt, josephUsdt, miltonUsdt, iporOracle } = testData;

        if (tokenUsdt === undefined || josephUsdt === undefined || miltonUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getPayFixedDerivativeParamsUSDTCase1(userTwo, tokenUsdt);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);

        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, params.openTimestamp);

        await miltonUsdt
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.acceptableFixedInterestRate,
                params.leverage
            );

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_160_18DEC, params.openTimestamp);

        await expect(
            miltonUsdt
                .connect(userThree)
                .itfCloseSwapPayFixed(1, params.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS))
        )
            .to.emit(miltonUsdt, "CloseSwap")
            .withArgs(
                BigNumber.from("1"),
                params.asset,
                params.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS),
                await userThree.getAddress(),
                BigNumber.from("18937318804000000000000"),
                BigNumber.from("20").mul(N1__0_18DEC)
            );
    });
});
