const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");
const { utils } = require("web3");

const {} = require("./Const.js");

const {
    assertError,
    getLibraries,
    prepareData,
    prepareMiltonSpreadCase6,
    prepareMiltonSpreadCase7,
    prepareMiltonSpreadCase8,
    prepareMiltonSpreadCase9,
} = require("./Utils");

describe("MiltonSpreadModel - Pay Fixed", () => {
    let data = null;
    let admin, userOne, userTwo, userThree, liquidityProvider;
    let libraries;

    before(async () => {
        libraries = await getLibraries();
        [admin, userOne, userTwo, userThree, liquidityProvider] =
            await ethers.getSigners();
        data = await prepareData(libraries, [
            admin,
            userOne,
            userTwo,
            userThree,
            liquidityProvider,
        ]);
    });
    it("should calculate Quote Value Pay Fixed Value - Kf part + KOmega part + KVol part + KHist < Spread Max Value", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();

        const calculateTimestamp = Math.floor(Date.now() / 1000);

        const accruedIpor = {
            indexValue: 1,
            ibtPrice: 1,

            exponentialMovingAverage: 1,
            exponentialWeightedMovingVariance: 1,
        };

        const swapCollateral = BigInt("23");
        const swapOpeningFee = BigInt("24");

        // //when
        // let actualSpreadValue = BigInt(
        //     await miltonSpread
        //         .connect(userOne)
        //         .calculateQuotePayFixed(
        //             accruedIpor,
        //             swapCollateral,
        //             swapOpeningFee,
        //             liquidityPoolBalance,
        //             payFixedSwapsBalance,
        //             receiveFixedSwapsBalance,
        //             soap
        //         )
        // );

        //then
    });

    it("should calculate Spread Premiums Pay Fixed Value - Kf part + KOmega part + KVol part + KHist < Spread Max Value", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();

        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = BigInt("20000000000000000000");

        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("40000000000000000"),
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };

        const expectedSpreadValue = BigInt("107709997242251128");

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase7();

        const spreadMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = BigInt("20000000000000000000");

        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("40000000000000000"),
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf denominator = 0, Komega denominator != 0, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase7();

        const spreadMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = BigInt("20000000000000000000");

        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("40000000000000000"),
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase8();

        const spreadMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = BigInt("20000000000000000000");

        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");

        const soap = payFixedSwapsBalance;

        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("40000000000000000"),
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator = 0, KHist denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase8();

        const spreadMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = BigInt("20000000000000000000");

        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");

        const soap = payFixedSwapsBalance;

        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("40000000000000000"),
            exponentialWeightedMovingVariance: BigInt("1000000000000000000"),
        };

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase8();

        const spreadMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = BigInt("20000000000000000000");

        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");

        const soap = payFixedSwapsBalance;

        const iporIndexValue = BigInt("30000000000000000");

        const accruedIpor = {
            indexValue: iporIndexValue,
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage:
                BigInt("1000000000000000000") + iporIndexValue,
            exponentialWeightedMovingVariance: BigInt("1000000000000000000"),
        };

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf denominator != 0, Komega denominator = 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase7();
        const spreadMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = BigInt("20000000000000000000");

        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");

        const soap = payFixedSwapsBalance;

        const iporIndexValue = BigInt("30000000000000000");

        const accruedIpor = {
            indexValue: iporIndexValue,
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage:
                BigInt("1000000000000000000") + iporIndexValue,
            exponentialWeightedMovingVariance: BigInt("1000000000000000000"),
        };

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();
        const spreadMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = BigInt("20000000000000000000");

        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");

        const accruedIpor = {
            indexValue: iporIndexValue,
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage:
                BigInt("1000000000000000000") + iporIndexValue,
            exponentialWeightedMovingVariance: BigInt("1000000000000000000"),
        };

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator != 0, KHist denominator = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();

        const spreadMaxValue = BigInt("300000000000000000");
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = BigInt("20000000000000000000");

        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");

        const accruedIpor = {
            indexValue: iporIndexValue,
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage:
                BigInt("1000000000000000000") + iporIndexValue,
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf part very high, Komega part normal, KVol part normal, KHist part normal", async () => {
        //given

        const miltonSpread = await prepareMiltonSpreadCase9();

        const spreadMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = BigInt("100000000000000001500");
        const swapCollateral = BigInt("1000");
        const swapOpeningFee = BigInt("0");

        const payFixedSwapsBalance = BigInt("1000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");

        const soap = BigInt("100");

        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("40000000000000000"),
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf part normal, KOmega part very high, KVol part normal, KHist part normal", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();

        const spreadMaxValue = BigInt("300000000000000000");
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = BigInt("20000000000000000000");

        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");

        const soap = BigInt("999999999999999999000");

        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("40000000000000000"),
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf part normal, KOmega part normal, KVol part very high, KHist part normal", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();
        const spreadMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = BigInt("20000000000000000000");

        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("40000000000000000"),
            exponentialWeightedMovingVariance: BigInt("999999999999999899"),
        };

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf part normal, KOmega part normal, KVol part normal, KHist very high", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();
        const spreadMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = BigInt("20000000000000000000");

        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const accruedIpor = {
            indexValue: BigInt("2000000000000000010"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("3000000000000000000"),
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Pay Fixed Value = Spread Max Value - Kf part + KOmega part + KVol part + KHist > Spread Max Value", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase7();
        const spreadMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = BigInt("20000000000000000000");

        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("40000000000000000"),
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should NOT calculate Spread Premiums Pay Fixed - Liquidity Pool + Opening Fee = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();

        const liquidityPoolBalance = BigInt("0");
        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = BigInt("0");

        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("40000000000000000"),
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };

        await assertError(
            //when
            miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    swapCollateral
                ),
            //then
            "IPOR_49"
        );
    });
});
