const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const { SwapState } = require("./enums.js");

const SWAP_DEFAULT_PERIOD_IN_SECONDS = "2419200"; //60 * 60 * 24 * 28
const YEAR_IN_SECONDS = BigInt("31536000");
const PERIOD_25_DAYS_IN_SECONDS = BigInt(60 * 60 * 24 * 25);

const ONE_18DEC = BigInt("1000000000000000000");
const TC_50_000_18DEC = BigInt("50000000000000000000000");

const prepareSwapPayFixedCase1 = async (fixedInterestRate, admin) => {
    const DaiMockedToken = await ethers.getContractFactory("DaiMockedToken");
    const daiMockedToken = await DaiMockedToken.deploy(BigInt("1000000000000000000"), 18);
    await daiMockedToken.deployed();
    const collateral = BigInt("9870300000000000000000");
    const leverage = BigInt("10");

    const timeStamp = Math.floor(Date.now() / 1000);
    const notionalAmount = collateral * leverage;
    const swap = {
        state: SwapState.ACTIVE,
        buyer: admin.address,
        asset: daiMockedToken.address,
        openTimestamp: BigInt(timeStamp),
        endTimestamp: BigInt(timeStamp + 60 * 60 * 24 * 28),
        id: BigInt("0"),
        idsIndex: BigInt("0"),
        idsIndex: BigInt("0"),
        collateral: TC_50_000_18DEC,
        liquidationDepositAmount: BigInt("20") * ONE_18DEC,
        notionalAmount,
        ibtQuantity: BigInt("987030000000000000000"), //ibtQuantity
        fixedInterestRate: fixedInterestRate,
    };
    return swap;
};

describe("IporSwapLogic", () => {
    let iporSwapLogic;
    let admin, userOne, userTwo, userThree, liquidityProvider;

    before(async () => {
        const MockIporSwapLogic = await ethers.getContractFactory("MockIporSwapLogic");
        iporSwapLogic = await MockIporSwapLogic.deploy();
        iporSwapLogic.deployed();
        [admin, userOne, userTwo, userThree, liquidityProvider] = await ethers.getSigners();
    });

    it("Calculate Interest Fixed Case 1", async () => {
        //given
        const notionalAmount = BigInt(98703) * ONE_18DEC;
        const swapFixedInterestRate = BigInt(4) * BigInt(1e16);
        const swapPeriodInSeconds = 0;

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFixed(
            notionalAmount,
            swapFixedInterestRate,
            swapPeriodInSeconds
        );
        //then
        expect(result, "Wrong interest fixed").to.be.equal(
            "3112697808000000000000000000000000000000000000000"
        );
    });

    it("Calculate Interest Fixed Case 2", async () => {
        //given
        const notionalAmount = BigInt(98703) * ONE_18DEC;
        const swapFixedInterestRate = BigInt(4 * 1e16);
        const swapPeriodInSeconds = BigInt(SWAP_DEFAULT_PERIOD_IN_SECONDS);

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFixed(
            notionalAmount,
            swapFixedInterestRate,
            swapPeriodInSeconds
        );

        //then
        expect(result, "Wrong interest fixed").to.be.equal(
            "3122249099904000000000000000000000000000000000000"
        );
    });

    it("Calculate Interest Fixed Case 3", async () => {
        //given
        const notionalAmount = BigInt(98703) * ONE_18DEC;
        const swapFixedInterestRate = BigInt(4 * 1e16);
        const swapPeriodInSeconds = YEAR_IN_SECONDS;

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFixed(
            notionalAmount,
            swapFixedInterestRate,
            swapPeriodInSeconds
        );

        //then
        expect(result, "Wrong interest fixed").to.be.equal(
            "3237205720320000000000000000000000000000000000000"
        );
    });

    it("Calculate Interest Floating Case", async () => {
        //given
        const ibtQuantity = BigInt(987030000000000000000);
        const ibtCurrentPrice = BigInt(100) * ONE_18DEC;

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFloating(
            ibtQuantity,
            ibtCurrentPrice
        );

        //then
        expect(result, "Wrong interest floating").to.be.equal(
            "3112697808000000206674329600000000000000000000000"
        );
    });

    it("Calculate Interest Floating Case 2", async () => {
        //given
        const ibtQuantity = BigInt(987030000000000000000);
        const ibtCurrentPrice = BigInt(150) * ONE_18DEC;

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFloating(
            ibtQuantity,
            ibtCurrentPrice
        );

        //then
        expect(result, "Wrong interest floating").to.be.equal(
            "4669046712000000310011494400000000000000000000000"
        );
    });

    it("Calculate Interest Floating Case 3", async () => {
        //given
        const ibtQuantity = BigInt(987030000);
        const ibtCurrentPrice = BigInt(100) * ONE_18DEC;

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFloating(
            ibtQuantity,
            ibtCurrentPrice
        );

        //then
        expect(result, "Wrong interest floating").to.be.equal(
            "3112697808000000000000000000000000000"
        );
    });

    it("Calculate Interest Floating Case 4", async () => {
        //given
        const ibtQuantity = BigInt(987030000);
        const ibtCurrentPrice = BigInt(150 * 1e6);

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFloating(
            ibtQuantity,
            ibtCurrentPrice
        );
        //then
        expect(result, "Wrong interest floating").to.be.equal("4669046712000000000000000");
    });

    it("Calculate Interest Case 1", async () => {
        //given
        const fixedInterestRate = BigInt("40000000000000000");
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);
        //when
        const swapValue = await iporSwapLogic.calculateSwapPayFixedValue(
            swap,
            BigInt(Date.now() + 60 * 60 * 24 * 28),
            ONE_18DEC
        );
        //then
        expect(swapValue, "Wrong interest difference amount").to.be.equal(
            BigInt("-50000000000000000000000")
        );
    });

    it("Calculate Quasi Interest Case 1", async () => {
        //given
        const fixedInterestRate = BigInt("40000000000000000");
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);
        //when
        const quastiInterest = await iporSwapLogic.calculateQuasiInterest(
            swap,
            BigInt(Date.now() + 60 * 60 * 24 * 28),
            ONE_18DEC
        );
        //then
        expect(quastiInterest.quasiIFixed, "Wrong Quasi Interest Fixed").to.be.equal(
            "3122249099904000000000000000000000000000000000000"
        );
        expect(quastiInterest.quasiIFloating, "Wrong Quasi Interest Floating").to.be.equal(
            BigInt("31126978080000000000000000000000000000000000000")
        );
    });

    it("Calculate Interest Case 2 Same Timestamp IBT Price Increase Decimal 18 Case1", async () => {
        //given
        const fixedInterestRate = BigInt("40000000000000000");
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);

        const ibtPriceSecond = BigInt(125) * ONE_18DEC;
        //when
        const swapValue = await iporSwapLogic.calculateSwapPayFixedValue(
            swap,
            swap.openTimestamp,
            ibtPriceSecond
        );

        //then
        expect(swapValue, "Wrong interest difference amount").to.be.equal(
            "24675750000000000000000"
        );
    });

    it("Calculate Quasi Interest Case 2 Same Timestamp IBT Price Increase Decimal 18 Case1", async () => {
        //given
        const fixedInterestRate = BigInt("40000000000000000");
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);

        const ibtPriceSecond = BigInt(125) * ONE_18DEC;
        //when
        const quasiInterest = await iporSwapLogic.calculateQuasiInterest(
            swap,
            swap.openTimestamp,
            ibtPriceSecond
        );

        //then
        expect(quasiInterest.quasiIFixed, "Wrong Quasi Interest Fixed").to.be.equal(
            "3112697808000000000000000000000000000000000000000"
        );
        expect(quasiInterest.quasiIFloating, "Wrong Quasi Interest Floating").to.be.equal(
            "3890872260000000000000000000000000000000000000000"
        );
    });

    it("Calculate Interest Case 25 days Later IBT Price Not Changed Decimal18", async () => {
        //given

        const fixedInterestRate = BigInt("40000000000000000");
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);
        const ibtPriceSecond = BigInt(100) * ONE_18DEC;

        //when

        const swapValue = await iporSwapLogic.calculateSwapPayFixedValue(
            swap,
            swap.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            ibtPriceSecond
        );

        //then
        expect(swapValue, "Wrong interest difference amount").to.be.equal("-270419178082191780821");
    });

    it("Calculate Quasi Interest Case 25 days Later IBT Price Not Changed Decimal18", async () => {
        //given

        const fixedInterestRate = BigInt("40000000000000000");
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);
        const ibtPriceSecond = BigInt(100) * ONE_18DEC;

        //when

        const quasiInterest = await iporSwapLogic.calculateQuasiInterest(
            swap,
            swap.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            ibtPriceSecond
        );

        //then
        expect(quasiInterest.quasiIFixed, "Wrong Quasi Interest Fixed").to.be.equal(
            "3121225747200000000000000000000000000000000000000"
        );
        expect(quasiInterest.quasiIFloating, "Wrong Quasi Interest Floating").to.be.equal(
            "3112697808000000000000000000000000000000000000000"
        );
    });

    it("Calculate Interest Case 25 days Later IBT Price Changed Decimals 18", async () => {
        const fixedInterestRate = BigInt("40000000000000000");
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);
        const ibtPriceSecond = BigInt(125) * ONE_18DEC;

        //when

        const swapValue = await iporSwapLogic.calculateSwapPayFixedValue(
            swap,
            swap.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            ibtPriceSecond
        );

        //then
        expect(swapValue, "Wrong interest difference amount").to.be.equal(
            "24405330821917808219178"
        );
    });

    it("Calculate Quasi Interest Case 25 days Later IBT Price Changed Decimals 18", async () => {
        const fixedInterestRate = BigInt("40000000000000000");
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);
        const ibtPriceSecond = BigInt(125) * ONE_18DEC;

        //when

        const quasiInterest = await iporSwapLogic.calculateQuasiInterest(
            swap,
            swap.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            ibtPriceSecond
        );

        //then
        expect(quasiInterest.quasiIFixed, "Wrong Quasi Interest Fixed").to.be.equal(
            "3121225747200000000000000000000000000000000000000"
        );
        expect(quasiInterest.quasiIFloating, "Wrong Quasi Interest Floating").to.be.equal(
            "3890872260000000000000000000000000000000000000000"
        );
    });

    it("Calculate Interest Case Huge Ipor 25 days Later IBT Price Changed User Loses Decimals 18", async () => {
        const iporIndex = BigInt(3650000000000000000);
        const spread = BigInt(10000000000000000);
        const fixedInterestRate = iporIndex + spread;

        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);

        const ibtPriceSecond = BigInt(125) * ONE_18DEC;

        //when
        const swapValue = await iporSwapLogic.calculateSwapPayFixedValue(
            swap,
            swap.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            ibtPriceSecond
        );

        //then
        expect(swapValue, "Wrong interest difference amount").to.be.equal("-67604794520547945204");
    });

    it("Calculate Quasi Interest Case Huge Ipor 25 days Later IBT Price Changed User Loses Decimals 18", async () => {
        const iporIndex = BigInt(3650000000000000000);
        const spread = BigInt(10000000000000000);
        const fixedInterestRate = iporIndex + spread;

        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);

        const ibtPriceSecond = BigInt(125) * ONE_18DEC;

        //when
        const quasiInterest = await iporSwapLogic.calculateQuasiInterest(
            swap,
            swap.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            ibtPriceSecond
        );

        //then
        expect(
            quasiInterest.quasiIFixed,

            "Wrong interest fixed"
        ).to.be.equal("3893004244800000000000000000000000000000000000000");
        expect(
            quasiInterest.quasiIFloating,

            "Wrong interest floating"
        ).to.be.equal("3890872260000000000000000000000000000000000000000");
    });

    it("Calculate Interest Case 100 days Later IBT Price Not Changed Decimals 18", async () => {
        //given

        const fixedInterestRate = BigInt("40000000000000000");
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);
        const ibtPriceSecond = BigInt(120) * ONE_18DEC;

        //when

        const swapValue = await iporSwapLogic.calculateSwapPayFixedValue(
            swap,
            swap.openTimestamp + PERIOD_25_DAYS_IN_SECONDS * BigInt(4),
            ibtPriceSecond
        );

        //then
        expect(swapValue, "Wrong interest difference amount").to.be.equal(
            "19437730520547945205479"
        );
    });

    it("Calculate Quasi Interest Case 100 days Later IBT Price Not Changed Decimals 18", async () => {
        //given

        const fixedInterestRate = BigInt("40000000000000000");
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);
        const ibtPriceSecond = BigInt(120) * ONE_18DEC;

        //when

        const quasiInterest = await iporSwapLogic.calculateQuasiInterest(
            swap,
            swap.openTimestamp + PERIOD_25_DAYS_IN_SECONDS * BigInt(4),
            ibtPriceSecond
        );

        //then
        expect(quasiInterest.quasiIFixed, "Wrong quasi interest fixed").to.be.equal(
            "3122249099904000000000000000000000000000000000000"
        );
        expect(quasiInterest.quasiIFloating, "Wrong interest floating").to.be.equal(
            "3735237369600000000000000000000000000000000000000"
        );
    });
});
