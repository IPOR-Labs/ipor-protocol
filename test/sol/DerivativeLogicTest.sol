// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import '../../contracts/amm/MiltonV1.sol';
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";

contract DerivativeLogicTest {

    using DerivativeLogic  for DataTypes.IporDerivative;
    uint256 constant PERIOD_25_DAYS_IN_SECONDS = 60 * 60 * 24 * 25;

    function testCalculateInterestFixedCase1() public {

        //given
        uint256 notionalAmount = 98703000000000000000000;
        uint256 derivativeFixedInterestRate = 40000000000000000;
        uint256 derivativePeriodInSeconds = 0;

        //when
        uint256 result = DerivativeLogic.calculateInterestFixed(notionalAmount, derivativeFixedInterestRate, derivativePeriodInSeconds);

        //then
        Assert.equal(result, notionalAmount, "Wrong interest fixed");
    }

    function testCalculateInterestFixedCase2() public {

        //given
        uint256 notionalAmount = 98703000000000000000000;
        uint256 derivativeFixedInterestRate = 40000000000000000;
        uint256 derivativePeriodInSeconds = Constants.DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS;

        //when
        uint256 result = DerivativeLogic.calculateInterestFixed(notionalAmount, derivativeFixedInterestRate, derivativePeriodInSeconds);

        //then
        Assert.equal(result, 99005869479452054794521, "Wrong interest fixed");
    }

    function testCalculateInterestFixedCase3() public {

        //given
        uint256 notionalAmount = 98703000000000000000000;
        uint256 derivativeFixedInterestRate = 40000000000000000;
        uint256 derivativePeriodInSeconds = Constants.YEAR_IN_SECONDS;

        //when
        uint256 result = DerivativeLogic.calculateInterestFixed(notionalAmount, derivativeFixedInterestRate, derivativePeriodInSeconds);

        //then
        Assert.equal(result, 102651120000000000000000, "Wrong interest fixed");
    }

    function testCalculateInterestFloatingCase1() public {

        //given
        uint256 ibtQuantity = 987030000000000000000;
        uint256 ibtCurrentPrice = 100000000000000000000;

        //when
        uint256 result = DerivativeLogic.calculateInterestFloating(ibtQuantity, ibtCurrentPrice);

        //then
        Assert.equal(result, 98703000000000000000000, "Wrong interest floating");
    }

    function testCalculateInterestFloatingCase2() public {

        //given
        uint256 ibtQuantity = 987030000000000000000;
        uint256 ibtCurrentPrice = 150000000000000000000;

        //when
        uint256 result = DerivativeLogic.calculateInterestFloating(ibtQuantity, ibtCurrentPrice);

        //then
        Assert.equal(result, 148054500000000000000000, "Wrong interest floating");
    }

    function testCalculateInterestCase1() public {

        //given
        uint256 fixedInterestRate = 40000000000000000;
        DataTypes.IporDerivative memory derivative = prepareDerivativeCase1(fixedInterestRate);

        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative.calculateInterest(
            derivative.startingTimestamp, 100 * Constants.MILTON_DECIMALS_FACTOR);

        //then
        Assert.equal(derivativeInterest.interestFixed, 98703000000000000000000, "Wrong interest fixed");
        Assert.equal(derivativeInterest.interestFloating, 98703000000000000000000, "Wrong interest floating");
        Assert.equal(derivativeInterest.interestDifferenceAmount, 0, "Wrong interest difference amount");
    }

    function testCalculateInterestCase2SameTimestampIBTPriceIncrease() public {

        //given
        uint256 fixedInterestRate = 40000000000000000;
        DataTypes.IporDerivative memory derivative = prepareDerivativeCase1(fixedInterestRate);


        uint256 ibtPriceSecond = 125 * Constants.MILTON_DECIMALS_FACTOR;
        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative.calculateInterest(
            derivative.startingTimestamp, ibtPriceSecond);

        //then
        Assert.equal(derivativeInterest.interestFixed, 98703000000000000000000, "Wrong interest fixed");
        Assert.equal(derivativeInterest.interestFloating, 123378750000000000000000, "Wrong interest floating");
        Assert.equal(derivativeInterest.interestDifferenceAmount, 24675750000000000000000, "Wrong interest difference amount");
    }

    function testCalculateInterestCase25daysLaterIBTPriceNotChanged() public {

        //given
        uint256 fixedInterestRate = 40000000000000000;
        DataTypes.IporDerivative memory derivative = prepareDerivativeCase1(fixedInterestRate);


        uint256 ibtPriceSecond = 100 * Constants.MILTON_DECIMALS_FACTOR;

        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative.calculateInterest(
            derivative.startingTimestamp + PERIOD_25_DAYS_IN_SECONDS, ibtPriceSecond);

        //then
        Assert.equal(derivativeInterest.interestFixed, 98973419178082191780822, "Wrong interest fixed");
        Assert.equal(derivativeInterest.interestFloating, 98703000000000000000000, "Wrong interest floating");
        Assert.equal(derivativeInterest.interestDifferenceAmount, -270419178082191780822, "Wrong interest difference amount");
    }

    function testCalculateInterestCase25daysLaterIBTPriceChanged() public {

        //given
        uint256 fixedInterestRate = 40000000000000000;
        DataTypes.IporDerivative memory derivative = prepareDerivativeCase1(fixedInterestRate);


        uint256 ibtPriceSecond = 125 * Constants.MILTON_DECIMALS_FACTOR;

        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative.calculateInterest(
            derivative.startingTimestamp + PERIOD_25_DAYS_IN_SECONDS, ibtPriceSecond);

        //then
        Assert.equal(derivativeInterest.interestFixed, 98973419178082191780822, "Wrong interest fixed");
        Assert.equal(derivativeInterest.interestFloating, 123378750000000000000000, "Wrong interest floating");
        Assert.equal(derivativeInterest.interestDifferenceAmount, 24405330821917808219178, "Wrong interest difference amount");
    }

    function testCalculateInterestCaseHugeIpor25daysLaterIBTPriceChangedUserLoses() public {

        //given
        uint256 iporIndex = 3650000000000000000;
        uint256 spread = 10000000000000000;
        uint256 fixedInterestRate = iporIndex + spread;

        DataTypes.IporDerivative memory derivative = prepareDerivativeCase1(fixedInterestRate);


        uint256 ibtPriceSecond = 125 * Constants.MILTON_DECIMALS_FACTOR;

        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative.calculateInterest(
            derivative.startingTimestamp + PERIOD_25_DAYS_IN_SECONDS, ibtPriceSecond);

        //then
        Assert.equal(derivativeInterest.interestFixed, 123446354794520547945205, "Wrong interest fixed");
        Assert.equal(derivativeInterest.interestFloating, 123378750000000000000000, "Wrong interest floating");
        Assert.equal(derivativeInterest.interestDifferenceAmount, -67604794520547945205, "Wrong interest difference amount");
    }

    function testCalculateInterestCase100daysLaterIBTPriceNotChanged() public {

        //given
        uint256 fixedInterestRate = 40000000000000000;
        DataTypes.IporDerivative memory derivative = prepareDerivativeCase1(fixedInterestRate);


        uint256 ibtPriceSecond = 100 * Constants.MILTON_DECIMALS_FACTOR;

        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative.calculateInterest(
            derivative.startingTimestamp + PERIOD_25_DAYS_IN_SECONDS * 4, ibtPriceSecond);

        //then
        Assert.equal(derivativeInterest.interestFixed, 99005869479452054794521, "Wrong interest fixed");
        Assert.equal(derivativeInterest.interestFloating, 98703000000000000000000, "Wrong interest floating");
        Assert.equal(derivativeInterest.interestDifferenceAmount, -302869479452054794521, "Wrong interest difference amount");
    }

    /*
    * @param fixedInterestRate is a spread with IPOR index
    */
    function prepareDerivativeCase1(uint256 fixedInterestRate) internal view returns (DataTypes.IporDerivative memory) {

        uint256 ibtPriceFirst = 100 * Constants.MILTON_DECIMALS_FACTOR;
        uint256 depositAmount = 9870300000000000000000;
        uint256 leverage = 10;

        DataTypes.IporDerivativeIndicator memory indicator = DataTypes.IporDerivativeIndicator(
            3 * 1e16, //ipor index value
            ibtPriceFirst,
            987030000000000000000, //ibtQuantity
            fixedInterestRate
        );

        DataTypes.IporDerivativeFee memory fee = DataTypes.IporDerivativeFee(
            20 * Constants.MILTON_DECIMALS_FACTOR, //liquidation deposit amount
            99700000000000000000, //opening fee amount
            10 * Constants.MILTON_DECIMALS_FACTOR, //ipor publication amount
            1e16 // spread percentege
        );

        DataTypes.IporDerivative memory derivative = DataTypes.IporDerivative(
            0,
            DataTypes.DerivativeState.ACTIVE,
            msg.sender,
            "DAI",
            0, //Pay Fixed, Receive Floating (long position)
            depositAmount,
            fee,
            leverage,
            depositAmount * leverage,
            block.timestamp,
            block.timestamp + 60 * 60 * 24 * 28,
            indicator
        );

        return derivative;

    }
}