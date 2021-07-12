// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import '../../contracts/amm/IporAmmV1.sol';
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";

contract DerivativeLogicTest {

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
        uint256 derivativePeriodInSeconds = DerivativeLogic.DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS;

        //when
        uint256 result = DerivativeLogic.calculateInterestFixed(notionalAmount, derivativeFixedInterestRate, derivativePeriodInSeconds);

        //then
        Assert.equal(result, 99005869479452054794520, "Wrong interest fixed");
    }

    function testCalculateInterestFixedCase3() public {

        //given
        uint256 notionalAmount = 98703000000000000000000;
        uint256 derivativeFixedInterestRate = 40000000000000000;
        uint256 derivativePeriodInSeconds = DerivativeLogic.YEAR_IN_SECONDS;

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
        int256 result = DerivativeLogic.calculateInterestFloating(ibtQuantity, ibtCurrentPrice);

        //then
        Assert.equal(result, 98703000000000000000000, "Wrong interest floating");
    }

    function testCalculateInterestFloatingCase2() public {

        //given
        uint256 ibtQuantity = 987030000000000000000;
        uint256 ibtCurrentPrice = 150000000000000000000;

        //when
        int256 result = DerivativeLogic.calculateInterestFloating(ibtQuantity, ibtCurrentPrice);

        //then
        Assert.equal(result, 148054500000000000000000, "Wrong interest floating");
    }

    function testCalculateInterestCase1() public {

        //given
        DataTypes.IporDerivative memory derivative = prepareDerivativeCase1();

        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = DerivativeLogic.calculateInterest(
            derivative, block.timestamp, 100 * AmmMath.LAS_VEGAS_DECIMALS_FACTOR);

        //then
        Assert.equal(derivativeInterest.interestFixed, 98703000000000000000000, "Wrong interest fixed");
        Assert.equal(derivativeInterest.interestFloating, 98703000000000000000000, "Wrong interest floating");
        Assert.equal(derivativeInterest.interestDifferenceAmount, 0, "Wrong interest difference amount");
    }

    function testCalculateInterestCase2SameTimestampIBTPriceIncrease() public {

        //given
        DataTypes.IporDerivative memory derivative = prepareDerivativeCase1();

        uint256 ibtPriceSecond = 125 * AmmMath.LAS_VEGAS_DECIMALS_FACTOR;
        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = DerivativeLogic.calculateInterest(
            derivative, block.timestamp, ibtPriceSecond);

        //then
        Assert.equal(derivativeInterest.interestFixed, 98703000000000000000000, "Wrong interest fixed");
        Assert.equal(derivativeInterest.interestFloating, 123378750000000000000000, "Wrong interest floating");
        Assert.equal(derivativeInterest.interestDifferenceAmount, 24675750000000000000000, "Wrong interest difference amount");
    }

    function prepareDerivativeCase1() internal returns (DataTypes.IporDerivative memory) {

        uint256 ibtPriceSFirst = 100 * AmmMath.LAS_VEGAS_DECIMALS_FACTOR;

        DataTypes.IporDerivativeIndicator memory indicator = DataTypes.IporDerivativeIndicator(
            3 * 1e16, //ipor index value
            ibtPriceSFirst,
            987030000000000000000, //ibtQuantity
            40000000000000000, //fixed interest rate
            0 //soap
        );

        DataTypes.IporDerivativeFee memory fee = DataTypes.IporDerivativeFee(
            20 * AmmMath.LAS_VEGAS_DECIMALS_FACTOR, //liquidation deposit amount
            99700000000000000000, //opening fee amount
            10 * AmmMath.LAS_VEGAS_DECIMALS_FACTOR, //ipor publication amount
            1e16 // spread percentege
        );

        DataTypes.IporDerivative memory derivative = DataTypes.IporDerivative(
            0,
            DataTypes.DerivativeState.ACTIVE,
            msg.sender,
            "DAI",
            0, //Pay Fixed, Receive Floating (long position)
            9870300000000000000000,
            fee,
            10,
            98703000000000000000000,
            block.timestamp,
            block.timestamp + 60 * 60 * 24 * 28,
            indicator
        );

        return derivative;

    }

    //302 86947945 2054794520,

    //    IporAmmV1 amm = IporAmmV1(DeployedAddresses.IporAmmV1());
    //    function testInitialBalanceWithNewMetaCoin() {
    //        IporAmmV1 meta = new IporAmmV1();
    //
    //        uint expected = 10000;
    //
    //        Assert.equal(meta.getBalance(tx.origin), expected, "Owner should have 10000 MetaCoin initially");
    //    }
}