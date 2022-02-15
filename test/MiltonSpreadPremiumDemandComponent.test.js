const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");
const { utils } = require("web3");

const {
    USD_20_18DEC,
    USD_2_000_18DEC,
    USD_10_000_18DEC,
    USD_14_000_18DEC,
    ZERO,
} = require("./Const.js");

const {
    getLibraries,
    prepareData,
    prepareMiltonSpreadCase2,
    prepareMiltonSpreadCase3,
    prepareMiltonSpreadCase4,
    prepareMiltonSpreadCase5,
} = require("./Utils");

describe("MiltonSpreadModel - Spread Premium Demand Component", () => {
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

    it("should calculate spread - demand component - Pay Fixed Swap, PayFix Balance > RecFix Balance, SOAP+=0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("1000000000000000000000000");
        const payFixedSwapsBalance = BigInt("2000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("86545000000000000");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Swap, PayFix Balance = RecFix Balance, SOAP+=0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("1000000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("94120909090909091");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Swap, PayFix Balance < RecFix Balance, SOAP+=0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("1000000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("2000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("94120909090909091");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Swap, 100% utilization rate including position, SOAP+=0 ", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = BigInt("1000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("1000000000000000000000");
        const payFixedSwapsBalance = USD_20_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4210000000000000");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Swap, imbalance factor > 0, opening fee > 0, pay fixed swap balance > 0, SOAP+=0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4654230769230769");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Swap, imbalance factor > 0, opening fee > 0, pay fixed swap balance > 0, SOAP+>0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");
        const soap = BigInt("100000000000000000000");

        const expectedSpreadDemandComponentValue = BigInt("5010897435897436");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Swap, imbalance factor > 0, opening fee > 0, pay fixed swap balance > 0, SOAP+=1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();
        const spreadMaxValue = BigInt("300000000000000000");

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");
        const soap = payFixedSwapsBalance;

        const expectedSpreadDemandComponentValue = spreadMaxValue;

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Swap, imbalance factor > 0, opening fee > 0, pay fixed swap balance = 0, SOAP+=0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = ZERO;
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4860549450549451");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Swap, imbalance factor > 0, opening fee = 0, pay fixed swap balance = 0, SOAP+=0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = ZERO;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = ZERO;
        const receiveFixedSwapsBalance = BigInt("13000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4858351648351648");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Pay Fixed Swap, Adjusted Utilization Rate equal M , Kf denominator = 0, SOAP+=0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase3();
        const spreadMaxValue = BigInt("300000000000000000");

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = USD_14_000_18DEC;
        const payFixedSwapsBalance = USD_2_000_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = spreadMaxValue;

        //when
        const actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateDemandComponentPayFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance + swapCollateral,
                    receiveFixedSwapsBalance,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, PayFix Balance > RecFix Balance, SOAP+=0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase4();

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("13000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4576251939768483");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, PayFix Balance = RecFix Balance, SOAP+=0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("5000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("5000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4211333333333333");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, PayFix Balance < RecFix Balance, SOAP+=0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("3000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4365384615384615");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, 100% utilization rate including position, SOAP+=0 ", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const swapCollateral = BigInt("1000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("1000000000000000000000");
        const payFixedSwapsBalance = BigInt("1000000000000000000000");
        const receiveFixedSwapsBalance = USD_20_18DEC;
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4210000000000000");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, imbalance factor > 0, opening fee > 0, rec fixed swap balance > 0, SOAP+=0 ", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase4();

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("13000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4576251939768483");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, imbalance factor > 0, opening fee > 0, rec fixed swap balance > 0, SOAP+>0 ", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase4();

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("13000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("100000000000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4932918606435150");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, imbalance factor > 0, opening fee > 0, rec fixed swap balance > 0, SOAP+=1 ", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();
        const spreadMaxValue = BigInt("300000000000000000");

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("13000000000000000000000");
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = receiveFixedSwapsBalance;

        const expectedSpreadDemandComponentValue = spreadMaxValue;

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, imbalance factor > 0, opening fee > 0, rec fixed swap balance = 0, SOAP+=0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase4();

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("13000000000000000000000");
        const receiveFixedSwapsBalance = ZERO;
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4713447820250902");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, imbalance factor > 0, opening fee = 0, rec fixed swap balance = 0, SOAP+=0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase4();

        const swapCollateral = BigInt("10000000000000000000000");
        const swapOpeningFee = ZERO;
        const liquidityPoolBalance = BigInt("15000000000000000000000");
        const payFixedSwapsBalance = BigInt("13000000000000000000000");
        const receiveFixedSwapsBalance = ZERO;
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = BigInt("4711445892394376");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
                    soap
                )
        );

        //then
        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });

    it("should calculate spread - demand component - Rec Fixed Swap, Adjusted Utilization Rate equal M , Kf denominator = 0, KOmega denominator != 0, SOAP+=0 ", async () => {
        //given

        const miltonSpread = await prepareMiltonSpreadCase5();
        const spreadMaxValue = BigInt("300000000000000000");

        const swapCollateral = USD_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;
        const liquidityPoolBalance = USD_14_000_18DEC;
        const payFixedSwapsBalance = USD_2_000_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");
        const soap = BigInt("-1234560000000000000");

        const expectedSpreadDemandComponentValue = spreadMaxValue;

        //when
        const actualSpreadDemandComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateDemandComponentRecFixed(
                    swapCollateral,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
                    soap
                )
        );

        //then

        expect(
            expectedSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        ).to.be.eq(actualSpreadDemandComponentValue);
    });
});
