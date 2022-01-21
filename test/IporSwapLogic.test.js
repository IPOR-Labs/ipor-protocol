const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const { SwapState } = require("./enums.js");

const DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS = "2419200"; //60 * 60 * 24 * 28
const YEAR_IN_SECONDS = BigInt("31536000");
const PERIOD_25_DAYS_IN_SECONDS = BigInt(60 * 60 * 24 * 25);

const ONE_18DEC = BigInt("1000000000000000000");

const prepareSwapPayFixedCase1 = async (fixedInterestRate, admin) => {
    const DaiMockedToken = await ethers.getContractFactory("DaiMockedToken");
    const daiMockedToken = await DaiMockedToken.deploy(
        BigInt("1000000000000000000"),
        18
    );
    await daiMockedToken.deployed();
    const collateral = BigInt("9870300000000000000000");
    const collateralizationFactor = BigInt("10");

    const timeStamp = Math.floor(Date.now() / 1000);
    const notionalAmount = collateral * collateralizationFactor;
    const derivative = {
        state: SwapState.ACTIVE,
        buyer: admin.address,
        asset: daiMockedToken.address,
        startingTimestamp: BigInt(timeStamp),
        endingTimestamp: BigInt(timeStamp + 60 * 60 * 24 * 28),
        id: BigInt("0"),
		idsIndex: BigInt("0"),
		userIdsIndex: BigInt("0"),
        collateral: BigInt("0"),
        liquidationDepositAmount: BigInt("20") * ONE_18DEC,
        notionalAmount,
        ibtQuantity: BigInt("987030000000000000000"), //ibtQuantity
        fixedInterestRate: fixedInterestRate,
    };

    return derivative;
};

describe("IporSwapLogic", () => {
    let iporSwapLogic;
    let admin, userOne, userTwo, userThree, liquidityProvider;

    before(async () => {
        const MockIporSwapLogic = await ethers.getContractFactory(
            "MockIporSwapLogic"
        );
        iporSwapLogic = await MockIporSwapLogic.deploy();
        iporSwapLogic.deployed();
        [admin, userOne, userTwo, userThree, liquidityProvider] =
            await ethers.getSigners();
    });

    it("Calculate Interest Fixed Case 1", async () => {
        //given
        const notionalAmount = BigInt(98703) * ONE_18DEC;
        const derivativeFixedInterestRate = BigInt(4) * BigInt(1e16);
        const derivativePeriodInSeconds = 0;

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFixed(
            notionalAmount,
            derivativeFixedInterestRate,
            derivativePeriodInSeconds
        );
        //then
        expect(result, "Wrong interest fixed").to.be.equal(
            "3112697808000000000000000000000000000000000000000"
        );
    });

    it("Calculate Interest Fixed Case 2", async () => {
        //given
        const notionalAmount = BigInt(98703) * ONE_18DEC;
        const derivativeFixedInterestRate = BigInt(4 * 1e16);
        const derivativePeriodInSeconds = BigInt(
            DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS
        );

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFixed(
            notionalAmount,
            derivativeFixedInterestRate,
            derivativePeriodInSeconds
        );

        //then
        expect(result, "Wrong interest fixed").to.be.equal(
            "3122249099904000000000000000000000000000000000000"
        );
    });

    it("Calculate Interest Fixed Case 3", async () => {
        //given
        const notionalAmount = BigInt(98703) * ONE_18DEC;
        const derivativeFixedInterestRate = BigInt(4 * 1e16);
        const derivativePeriodInSeconds = YEAR_IN_SECONDS;

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFixed(
            notionalAmount,
            derivativeFixedInterestRate,
            derivativePeriodInSeconds
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
        expect(result, "Wrong interest floating").to.be.equal(
            "4669046712000000000000000"
        );
    });

    it("Calculate Interest Case 1", async () => {
        //given
        const fixedInterestRate = BigInt("40000000000000000");
        const derivative = await prepareSwapPayFixedCase1(
            fixedInterestRate,
            admin
        );
        //when
        const derivativeInterest =
            await iporSwapLogic.calculateInterestForSwapPayFixed(
                derivative,
                BigInt(Date.now() + 60 * 60 * 24 * 28),
                ONE_18DEC
            );
        //then
        expect(
            derivativeInterest.quasiInterestFixed,
            "Wrong interest fixed"
        ).to.be.equal("3122249099904000000000000000000000000000000000000");
        expect(
            derivativeInterest.quasiInterestFloating,
            "Wrong interest floating"
        ).to.be.equal(
            BigInt("31126978080000000000000000000000000000000000000")
        );
        expect(
            derivativeInterest.positionValue,
            "Wrong interest difference amount"
        ).to.be.equal(BigInt("-98018839479452054794520"));
    });

    it("Calculate Interest Case 2 Same Timestamp IBT Price Increase Decimal 18 Case1", async () => {
        //given
        const fixedInterestRate = BigInt("40000000000000000");
        const derivative = await prepareSwapPayFixedCase1(
            fixedInterestRate,
            admin
        );

        const ibtPriceSecond = BigInt(125) * ONE_18DEC;
        //when
        const derivativeInterest =
            await iporSwapLogic.calculateInterestForSwapPayFixed(
                derivative,
                derivative.startingTimestamp,
                ibtPriceSecond
            );

        //then
        expect(
            derivativeInterest.quasiInterestFixed,

            "Wrong interest fixed"
        ).to.be.equal("3112697808000000000000000000000000000000000000000");
        expect(
            derivativeInterest.quasiInterestFloating,
            "Wrong interest floating"
        ).to.be.equal("3890872260000000000000000000000000000000000000000");
        expect(
            derivativeInterest.positionValue,
            "Wrong interest difference amount"
        ).to.be.equal("24675750000000000000000");
    });

    it("Calculate Interest Case 25 days Later IBT Price Not Changed Decimal18", async () => {
        //given

        const fixedInterestRate = BigInt("40000000000000000");
        const derivative = await prepareSwapPayFixedCase1(
            fixedInterestRate,
            admin
        );
        const ibtPriceSecond = BigInt(100) * ONE_18DEC;

        //when

        const derivativeInterest =
            await iporSwapLogic.calculateInterestForSwapPayFixed(
                derivative,
                derivative.startingTimestamp + PERIOD_25_DAYS_IN_SECONDS,
                ibtPriceSecond
            );

        //then
        expect(
            derivativeInterest.quasiInterestFixed,
            "Wrong interest fixed"
        ).to.be.equal("3121225747200000000000000000000000000000000000000");
        expect(
            derivativeInterest.quasiInterestFloating,
            "Wrong interest floating"
        ).to.be.equal("3112697808000000000000000000000000000000000000000");
        expect(
            derivativeInterest.positionValue,
            "Wrong interest difference amount"
        ).to.be.equal("-270419178082191780821");
    });

    it("Calculate Interest Case 25 days Later IBT Price Changed Decimals 18", async () => {
        const fixedInterestRate = BigInt("40000000000000000");
        const derivative = await prepareSwapPayFixedCase1(
            fixedInterestRate,
            admin
        );
        const ibtPriceSecond = BigInt(125) * ONE_18DEC;

        //when

        const derivativeInterest =
            await iporSwapLogic.calculateInterestForSwapPayFixed(
                derivative,
                derivative.startingTimestamp + PERIOD_25_DAYS_IN_SECONDS,
                ibtPriceSecond
            );

        //then
        expect(
            derivativeInterest.quasiInterestFixed,
            "Wrong interest fixed"
        ).to.be.equal("3121225747200000000000000000000000000000000000000");
        expect(
            derivativeInterest.quasiInterestFloating,
            "Wrong interest floating"
        ).to.be.equal("3890872260000000000000000000000000000000000000000");
        expect(
            derivativeInterest.positionValue,
            "Wrong interest difference amount"
        ).to.be.equal("24405330821917808219178");
    });

    it("Calculate Interest Case Huge Ipor 25 days Later IBT Price Changed User Loses Decimals 18", async () => {
        const iporIndex = BigInt(3650000000000000000);
        const spread = BigInt(10000000000000000);
        const fixedInterestRate = iporIndex + spread;

        const derivative = await prepareSwapPayFixedCase1(
            fixedInterestRate,
            admin
        );

        const ibtPriceSecond = BigInt(125) * ONE_18DEC;

        //when
        const derivativeInterest =
            await iporSwapLogic.calculateInterestForSwapPayFixed(
                derivative,
                derivative.startingTimestamp + PERIOD_25_DAYS_IN_SECONDS,
                ibtPriceSecond
            );

        //then
        expect(
            derivativeInterest.quasiInterestFixed,

            "Wrong interest fixed"
        ).to.be.equal("3893004244800000000000000000000000000000000000000");
        expect(
            derivativeInterest.quasiInterestFloating,

            "Wrong interest floating"
        ).to.be.equal("3890872260000000000000000000000000000000000000000");
        expect(
            derivativeInterest.positionValue,
            "Wrong interest difference amount"
        ).to.be.equal("-67604794520547945204");
    });

    it("Calculate Interest Case 100 days Later IBT Price Not Changed Decimals 18", async () => {
        //given

        const fixedInterestRate = BigInt("40000000000000000");
        const derivative = await prepareSwapPayFixedCase1(
            fixedInterestRate,
            admin
        );
        const ibtPriceSecond = BigInt(120) * ONE_18DEC;

        //when

        const derivativeInterest =
            await iporSwapLogic.calculateInterestForSwapPayFixed(
                derivative,
                derivative.startingTimestamp +
                    PERIOD_25_DAYS_IN_SECONDS * BigInt(4),
                ibtPriceSecond
            );

        //then
        expect(
            derivativeInterest.quasiInterestFixed,
            "Wrong interest fixed"
        ).to.be.equal("3122249099904000000000000000000000000000000000000");
        expect(
            derivativeInterest.quasiInterestFloating,

            "Wrong interest floating"
        ).to.be.equal("3735237369600000000000000000000000000000000000000");
        expect(
            derivativeInterest.positionValue,
            "Wrong interest difference amount"
        ).to.be.equal("19437730520547945205479");
    });
});
