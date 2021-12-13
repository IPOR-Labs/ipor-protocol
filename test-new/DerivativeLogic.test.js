const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

const DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS = "2419200"; //60 * 60 * 24 * 28
const YEAR_IN_SECONDS = BigInt("31536000");

const ONE_18DEC = BigInt("1000000000000000000");

const prepareDerivativeCase1 = async (fixedInterestRate, admin) => {
    const DaiMockedToken = await ethers.getContractFactory("DaiMockedToken");
    const daiMockedToken = await DaiMockedToken.deploy(
        BigInt("1000000000000000000"),
        18
    );
    await daiMockedToken.deployed();
    const ibtPriceFirst = BigInt("100") * ONE_18DEC;
    const collateral = BigInt("9870300000000000000000");
    const collateralizationFactor = BigInt("10");

    const indicator = {
        iporIndexValue: BigInt("30000000000000000"), //ipor index value
        ibtPrice: ibtPriceFirst,
        ibtQuantity: BigInt("987030000000000000000"), //ibtQuantity
        fixedInterestRate: fixedInterestRate,
    };

    const liquidationDepositAmount = BigInt("20") * ONE_18DEC;
    const fee = {
        liquidationDepositAmount, //liquidation deposit amount
        openingAmount: BigInt("99700000000000000000"), //opening fee amount
        iporPublicationAmount: BigInt("10"), // * ONE_18DEC, //ipor publication amount
        spreadPayFixedValue: BigInt("10000000000000000"), // spread percentege
        spreadRecFixedValue: BigInt("10000000000000000"), // spread percentege
    };
    const timeStamp = Date.now();
    const notionalAmount = collateral * collateralizationFactor;
    const derivative = {
        id: BigInt("0"),
        state: "ACTIVE",
        buyer: admin.address,
        asset: daiMockedToken.address,
        direction: BigInt("0"), //Pay Fixed, Receive Floating (long position)
        collateral: BigInt("0"),
        fee,
        collateralizationFactor: BigInt("0"),
        notionalAmount: BigInt("0"),
        startingTimestamp: BigInt("1639430306"), //BigInt(timeStamp),
        endingTimestamp: BigInt("1639450306"), //BigInt(timeStamp + 60 * 60 * 24 * 28),
        indicator: BigInt("0"),
    };

    return derivative;
};

describe("DerivativeLogic", () => {
    let derivativeLogic;
    let admin, userOne, userTwo, userThree, liquidityProvider;

    before(async () => {
        const MockDerivativeLogic = await ethers.getContractFactory(
            "MockDerivativeLogic"
        );
        derivativeLogic = await MockDerivativeLogic.deploy();
        derivativeLogic.deployed();
        [admin, userOne, userTwo, userThree, liquidityProvider] =
            await ethers.getSigners();
    });

    it("Calculate Interest Fixed Case 1", async () => {
        //given
        const notionalAmount = BigInt(98703) * ONE_18DEC;
        const derivativeFixedInterestRate = BigInt(4) * BigInt(1e16);
        const derivativePeriodInSeconds = 0;

        //when
        const result = await derivativeLogic.calculateQuasiInterestFixed(
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
        const result = await derivativeLogic.calculateQuasiInterestFixed(
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
        const result = await derivativeLogic.calculateQuasiInterestFixed(
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
        const result = await derivativeLogic.calculateQuasiInterestFloating(
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
        const result = await derivativeLogic.calculateQuasiInterestFloating(
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
        const result = await derivativeLogic.calculateQuasiInterestFloating(
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
        const result = await derivativeLogic.calculateQuasiInterestFloating(
            ibtQuantity,
            ibtCurrentPrice
        );
        //then
        expect(result, "Wrong interest floating").to.be.equal(
            "4669046712000000000000000"
        );
    });
    // FIXME :  fix test invalid BigNumber string
    // it("Calculate Interest Case 1", async () => {
    //     //given
    //     const fixedInterestRate = BigInt("40000000000000000");
    //     const derivative = await prepareDerivativeCase1(
    //         fixedInterestRate,
    //         admin
    //     );
    //     console.log(derivative);
    //     //when
    //     const derivativeInterest = await derivativeLogic.calculateInterest(
    //         derivative,
    //         BigInt("1639430306"),
    //         BigInt(100) // * ONE_18DEC
    //     );
    //     console.log("----------------");
    //     //then
    //     expect(
    //         derivativeInterest.quasiInterestFixed,
    //         "Wrong interest fixed"
    //     ).to.be.equal("111");
    //     // expect(
    //     //     AmmMath.division(
    //     //         derivativeInterest.quasiInterestFloating,
    //     //         Constants.YEAR_IN_SECONDS * Constants.D18
    //     //     ),
    //     //     98703 * Constants.D18,
    //     //     "Wrong interest floating"
    //     // );
    //     // expect(
    //     //     derivativeInterest.positionValue,
    //     //     0,
    //     //     "Wrong interest difference amount"
    //     // );
    // });

    // function testCalculateInterestCase1() public {
    //     //given
    //     uint256 fixedInterestRate = 40000000000000000;
    //     DataTypes.IporDerivative memory derivative = prepareDerivativeCase1(
    //         fixedInterestRate
    //     );

    //     //when
    //     DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
    //         .calculateInterest(
    //             derivative.startingTimestamp,
    //             100 * Constants.D18
    //         );

    //     //then
    //     Assert.equal(
    //         AmmMath.division(
    //             derivativeInterest.quasiInterestFixed,
    //             Constants.YEAR_IN_SECONDS * Constants.D18
    //         ),
    //         98703 * Constants.D18,
    //         "Wrong interest fixed"
    //     );
    //     Assert.equal(
    //         AmmMath.division(
    //             derivativeInterest.quasiInterestFloating,
    //             Constants.YEAR_IN_SECONDS * Constants.D18
    //         ),
    //         98703 * Constants.D18,
    //         "Wrong interest floating"
    //     );
    //     Assert.equal(
    //         derivativeInterest.positionValue,
    //         0,
    //         "Wrong interest difference amount"
    //     );
    // }

    // function testCalculateInterestCase2SameTimestampIBTPriceIncreaseDecimal18Case1()
    //     public
    // {
    //     //given
    //     uint256 fixedInterestRate = 40000000000000000;
    //     DataTypes.IporDerivative memory derivative = prepareDerivativeCase1(
    //         fixedInterestRate
    //     );

    //     uint256 ibtPriceSecond = 125 * Constants.D18;
    //     //when
    //     DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
    //         .calculateInterest(derivative.startingTimestamp, ibtPriceSecond);

    //     //then
    //     Assert.equal(
    //         AmmMath.division(
    //             derivativeInterest.quasiInterestFixed,
    //             Constants.YEAR_IN_SECONDS * Constants.D18
    //         ),
    //         98703 * Constants.D18,
    //         "Wrong interest fixed"
    //     );
    //     Assert.equal(
    //         AmmMath.division(
    //             derivativeInterest.quasiInterestFloating,
    //             Constants.YEAR_IN_SECONDS * Constants.D18
    //         ),
    //         123378750000000000000000,
    //         "Wrong interest floating"
    //     );
    //     Assert.equal(
    //         derivativeInterest.positionValue,
    //         24675750000000000000000,
    //         "Wrong interest difference amount"
    //     );
    // }

    // function testCalculateInterestCase25daysLaterIBTPriceNotChangedDecimal18()
    //     public
    // {
    //     //given
    //     uint256 fixedInterestRate = 40000000000000000;
    //     DataTypes.IporDerivative memory derivative = prepareDerivativeCase1(
    //         fixedInterestRate
    //     );

    //     uint256 ibtPriceSecond = 100 * Constants.D18;

    //     //when
    //     DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
    //         .calculateInterest(
    //             derivative.startingTimestamp + PERIOD_25_DAYS_IN_SECONDS,
    //             ibtPriceSecond
    //         );

    //     //then
    //     Assert.equal(
    //         AmmMath.division(
    //             derivativeInterest.quasiInterestFixed,
    //             Constants.YEAR_IN_SECONDS * Constants.D18
    //         ),
    //         98973419178082191780822,
    //         "Wrong interest fixed"
    //     );
    //     Assert.equal(
    //         AmmMath.division(
    //             derivativeInterest.quasiInterestFloating,
    //             Constants.YEAR_IN_SECONDS * Constants.D18
    //         ),
    //         98703000000000000000000,
    //         "Wrong interest floating"
    //     );
    //     Assert.equal(
    //         derivativeInterest.positionValue,
    //         -270419178082191780821,
    //         "Wrong interest difference amount"
    //     );
    // }

    // function testCalculateInterestCase25daysLaterIBTPriceChangedDecimals18()
    //     public
    // {
    //     //given
    //     uint256 fixedInterestRate = 40000000000000000;
    //     DataTypes.IporDerivative memory derivative = prepareDerivativeCase1(
    //         fixedInterestRate
    //     );

    //     uint256 ibtPriceSecond = 125 * Constants.D18;

    //     //when
    //     DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
    //         .calculateInterest(
    //             derivative.startingTimestamp + PERIOD_25_DAYS_IN_SECONDS,
    //             ibtPriceSecond
    //         );

    //     //then
    //     Assert.equal(
    //         AmmMath.division(
    //             derivativeInterest.quasiInterestFixed,
    //             Constants.YEAR_IN_SECONDS * Constants.D18
    //         ),
    //         98973419178082191780822,
    //         "Wrong interest fixed"
    //     );
    //     Assert.equal(
    //         AmmMath.division(
    //             derivativeInterest.quasiInterestFloating,
    //             Constants.YEAR_IN_SECONDS * Constants.D18
    //         ),
    //         123378750000000000000000,
    //         "Wrong interest floating"
    //     );
    //     Assert.equal(
    //         derivativeInterest.positionValue,
    //         24405330821917808219178,
    //         "Wrong interest difference amount"
    //     );
    // }

    // function testCalculateInterestCaseHugeIpor25daysLaterIBTPriceChangedUserLosesDecimals18()
    //     public
    // {
    //     //given
    //     uint256 iporIndex = 3650000000000000000;
    //     uint256 spread = 10000000000000000;
    //     uint256 fixedInterestRate = iporIndex + spread;

    //     DataTypes.IporDerivative memory derivative = prepareDerivativeCase1(
    //         fixedInterestRate
    //     );

    //     uint256 ibtPriceSecond = 125 * Constants.D18;

    //     //when
    //     DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
    //         .calculateInterest(
    //             derivative.startingTimestamp + PERIOD_25_DAYS_IN_SECONDS,
    //             ibtPriceSecond
    //         );

    //     //then
    //     Assert.equal(
    //         AmmMath.division(
    //             derivativeInterest.quasiInterestFixed,
    //             Constants.YEAR_IN_SECONDS * Constants.D18
    //         ),
    //         123446354794520547945205,
    //         "Wrong interest fixed"
    //     );
    //     Assert.equal(
    //         AmmMath.division(
    //             derivativeInterest.quasiInterestFloating,
    //             Constants.YEAR_IN_SECONDS * Constants.D18
    //         ),
    //         123378750000000000000000,
    //         "Wrong interest floating"
    //     );
    //     Assert.equal(
    //         derivativeInterest.positionValue,
    //         -67604794520547945204,
    //         "Wrong interest difference amount"
    //     );
    // }

    // function testCalculateInterestCase100daysLaterIBTPriceNotChangedDecimals18()
    //     public
    // {
    //     //given
    //     uint256 fixedInterestRate = 40000000000000000;
    //     DataTypes.IporDerivative memory derivative = prepareDerivativeCase1(
    //         fixedInterestRate
    //     );

    //     uint256 ibtPriceSecond = 100 * Constants.D18;

    //     //when
    //     DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
    //         .calculateInterest(
    //             derivative.startingTimestamp + PERIOD_25_DAYS_IN_SECONDS * 4,
    //             ibtPriceSecond
    //         );

    //     //then
    //     Assert.equal(
    //         AmmMath.division(
    //             derivativeInterest.quasiInterestFixed,
    //             Constants.YEAR_IN_SECONDS * Constants.D18
    //         ),
    //         99005869479452054794521,
    //         "Wrong interest fixed"
    //     );
    //     Assert.equal(
    //         AmmMath.division(
    //             derivativeInterest.quasiInterestFloating,
    //             Constants.YEAR_IN_SECONDS * Constants.D18
    //         ),
    //         98703000000000000000000,
    //         "Wrong interest floating"
    //     );
    //     Assert.equal(
    //         derivativeInterest.positionValue,
    //         -302869479452054794520,
    //         "Wrong interest difference amount"
    //     );
    // }
});
