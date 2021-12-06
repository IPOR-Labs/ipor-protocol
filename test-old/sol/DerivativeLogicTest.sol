// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../../contracts/amm/Milton.sol";
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "./TestData.sol";

contract DerivativeLogicTest is TestData {
    using DerivativeLogic for DataTypes.IporDerivative;

    function testCalculateInterestFixedCase1() public {
        //given
        uint256 notionalAmount = 98703 * Constants.D18;
        uint256 derivativeFixedInterestRate = 4 * 1e16;
        uint256 derivativePeriodInSeconds = 0;
        uint256 multiplicator = Constants.D18;

        //when
        uint256 result = DerivativeLogic.calculateQuasiInterestFixed(
            notionalAmount,
            derivativeFixedInterestRate,
            derivativePeriodInSeconds,
            multiplicator
        );

        //then
        Assert.equal(
            AmmMath.division(result, Constants.YEAR_IN_SECONDS * multiplicator),
            notionalAmount,
            "Wrong interest fixed"
        );
    }

    function testCalculateInterestFixedCase2() public {
        //given
        uint256 notionalAmount = 98703 * Constants.D18;
        uint256 derivativeFixedInterestRate = 4 * 1e16;
        uint256 derivativePeriodInSeconds = Constants
            .DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS;
        uint256 multiplicator = Constants.D18;

        //when
        uint256 result = DerivativeLogic.calculateQuasiInterestFixed(
            notionalAmount,
            derivativeFixedInterestRate,
            derivativePeriodInSeconds,
            multiplicator
        );

        //then
        Assert.equal(
            AmmMath.division(result, Constants.YEAR_IN_SECONDS * multiplicator),
            99005869479452054794521,
            "Wrong interest fixed"
        );
    }

    function testCalculateInterestFixedCase3() public {
        //given
        uint256 notionalAmount = 98703 * Constants.D18;
        uint256 derivativeFixedInterestRate = 4 * 1e16;
        uint256 derivativePeriodInSeconds = Constants.YEAR_IN_SECONDS;
        uint256 multiplicator = Constants.D18;

        //when
        uint256 result = DerivativeLogic.calculateQuasiInterestFixed(
            notionalAmount,
            derivativeFixedInterestRate,
            derivativePeriodInSeconds,
            multiplicator
        );

        //then
        Assert.equal(
            AmmMath.division(result, Constants.YEAR_IN_SECONDS * multiplicator),
            102651120000000000000000,
            "Wrong interest fixed"
        );
    }

    function testCalculateInterestFixedCase4() public {
        //given
        uint256 notionalAmount = 98703 * Constants.D6;
        uint256 derivativeFixedInterestRate = 4 * 1e4;
        uint256 derivativePeriodInSeconds = 0;
        uint256 multiplicator = Constants.D6;

        //when
        uint256 result = DerivativeLogic.calculateQuasiInterestFixed(
            notionalAmount,
            derivativeFixedInterestRate,
            derivativePeriodInSeconds,
            multiplicator
        );

        //then
        Assert.equal(
            AmmMath.division(result, Constants.YEAR_IN_SECONDS * multiplicator),
            notionalAmount,
            "Wrong interest fixed"
        );
    }

    function testCalculateInterestFixedCase5() public {
        //given
        uint256 notionalAmount = 98703 * Constants.D6;
        uint256 derivativeFixedInterestRate = 4 * 1e4;
        uint256 derivativePeriodInSeconds = Constants
            .DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS;
        uint256 multiplicator = Constants.D6;

        //when
        uint256 result = DerivativeLogic.calculateQuasiInterestFixed(
            notionalAmount,
            derivativeFixedInterestRate,
            derivativePeriodInSeconds,
            multiplicator
        );

        //then
        Assert.equal(
            AmmMath.division(result, Constants.YEAR_IN_SECONDS * multiplicator),
            99005869479,
            "Wrong interest fixed"
        );
    }

    function testCalculateInterestFixedCase6() public {
        //given
        uint256 notionalAmount = 98703 * Constants.D6;
        uint256 derivativeFixedInterestRate = 4 * 1e4;
        uint256 derivativePeriodInSeconds = Constants.YEAR_IN_SECONDS;
        uint256 multiplicator = Constants.D6;

        //when
        uint256 result = DerivativeLogic.calculateQuasiInterestFixed(
            notionalAmount,
            derivativeFixedInterestRate,
            derivativePeriodInSeconds,
            multiplicator
        );

        //then
        Assert.equal(
            AmmMath.division(result, Constants.YEAR_IN_SECONDS * multiplicator),
            102651120000,
            "Wrong interest fixed"
        );
    }

    function testCalculateInterestFloatingCase1() public {
        //given
        uint256 ibtQuantity = 987030000000000000000;
        uint256 ibtCurrentPrice = 100 * Constants.D18;

        //when
        uint256 result = DerivativeLogic.calculateQuasiInterestFloating(
            ibtQuantity,
            ibtCurrentPrice
        );

        //then
        Assert.equal(
            AmmMath.division(result, Constants.YEAR_IN_SECONDS * Constants.D18),
            98703 * Constants.D18,
            "Wrong interest floating"
        );
    }

    function testCalculateInterestFloatingCase2() public {
        //given
        uint256 ibtQuantity = 987030000000000000000;
        uint256 ibtCurrentPrice = 150 * Constants.D18;

        //when
        uint256 result = DerivativeLogic.calculateQuasiInterestFloating(
            ibtQuantity,
            ibtCurrentPrice
        );

        //then
        Assert.equal(
            AmmMath.division(result, Constants.YEAR_IN_SECONDS * Constants.D18),
            148054500000000000000000,
            "Wrong interest floating"
        );
    }

    function testCalculateInterestFloatingCase3() public {
        //given
        uint256 ibtQuantity = 987030000;
        uint256 ibtCurrentPrice = 100 * Constants.D6;

        //when
        uint256 result = DerivativeLogic.calculateQuasiInterestFloating(
            ibtQuantity,
            ibtCurrentPrice
        );

        //then
        Assert.equal(
            AmmMath.division(result, Constants.YEAR_IN_SECONDS * Constants.D6),
            98703 * Constants.D6,
            "Wrong interest floating"
        );
    }

    function testCalculateInterestFloatingCase4() public {
        //given
        uint256 ibtQuantity = 987030000;
        uint256 ibtCurrentPrice = 150 * Constants.D6;

        //when
        uint256 result = DerivativeLogic.calculateQuasiInterestFloating(
            ibtQuantity,
            ibtCurrentPrice
        );

        //then
        Assert.equal(
            AmmMath.division(result, Constants.YEAR_IN_SECONDS * Constants.D6),
            148054500000,
            "Wrong interest floating"
        );
    }

    function testCalculateInterestCase1() public {
        //given
        uint256 fixedInterestRate = 40000000000000000;
        DataTypes.IporDerivative memory derivative = prepareDerivativeCase1(
            fixedInterestRate
        );

        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
            .calculateInterest(
                derivative.startingTimestamp,
                100 * Constants.D18
            );

        //then
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFixed,
                Constants.YEAR_IN_SECONDS * Constants.D18
            ),
            98703 * Constants.D18,
            "Wrong interest fixed"
        );
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFloating,
                Constants.YEAR_IN_SECONDS * Constants.D18
            ),
            98703 * Constants.D18,
            "Wrong interest floating"
        );
        Assert.equal(
            derivativeInterest.positionValue,
            0,
            "Wrong interest difference amount"
        );
    }

    function testCalculateInterestCase2() public {
        //given
        uint256 fixedInterestRate = 40000;
        DataTypes.IporDerivative memory derivative = prepareDerivativeCase2(
            fixedInterestRate
        );

        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
            .calculateInterest(
                derivative.startingTimestamp,
                100 * Constants.D6
            );

        //then
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFixed,
                Constants.YEAR_IN_SECONDS * Constants.D6
            ),
            98703 * Constants.D6,
            "Wrong interest fixed"
        );
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFloating,
                Constants.YEAR_IN_SECONDS * Constants.D6
            ),
            98703 * Constants.D6,
            "Wrong interest floating"
        );
        Assert.equal(
            derivativeInterest.positionValue,
            0,
            "Wrong interest difference amount"
        );
    }

    function testCalculateInterestCase2SameTimestampIBTPriceIncreaseDecimal18Case1()
        public
    {
        //given
        uint256 fixedInterestRate = 40000000000000000;
        DataTypes.IporDerivative memory derivative = prepareDerivativeCase1(
            fixedInterestRate
        );

        uint256 ibtPriceSecond = 125 * Constants.D18;
        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
            .calculateInterest(derivative.startingTimestamp, ibtPriceSecond);

        //then
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFixed,
                Constants.YEAR_IN_SECONDS * Constants.D18
            ),
            98703 * Constants.D18,
            "Wrong interest fixed"
        );
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFloating,
                Constants.YEAR_IN_SECONDS * Constants.D18
            ),
            123378750000000000000000,
            "Wrong interest floating"
        );
        Assert.equal(
            derivativeInterest.positionValue,
            24675750000000000000000,
            "Wrong interest difference amount"
        );
    }

    function testCalculateInterestCase2SameTimestampIBTPriceIncreaseDecimal6Case2()
        public
    {
        //given
        uint256 fixedInterestRate = 40000;
        DataTypes.IporDerivative memory derivative = prepareDerivativeCase2(
            fixedInterestRate
        );

        uint256 ibtPriceSecond = 125 * Constants.D6;
        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
            .calculateInterest(derivative.startingTimestamp, ibtPriceSecond);

        //then
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFixed,
                Constants.YEAR_IN_SECONDS * Constants.D6
            ),
            98703 * Constants.D6,
            "Wrong interest fixed"
        );
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFloating,
                Constants.YEAR_IN_SECONDS * Constants.D6
            ),
            123378750000,
            "Wrong interest floating"
        );
        Assert.equal(
            derivativeInterest.positionValue,
            24675750000,
            "Wrong interest difference amount"
        );
    }

    function testCalculateInterestCase25daysLaterIBTPriceNotChangedDecimal18()
        public
    {
        //given
        uint256 fixedInterestRate = 40000000000000000;
        DataTypes.IporDerivative memory derivative = prepareDerivativeCase1(
            fixedInterestRate
        );

        uint256 ibtPriceSecond = 100 * Constants.D18;

        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
            .calculateInterest(
                derivative.startingTimestamp + PERIOD_25_DAYS_IN_SECONDS,
                ibtPriceSecond
            );

        //then
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFixed,
                Constants.YEAR_IN_SECONDS * Constants.D18
            ),
            98973419178082191780822,
            "Wrong interest fixed"
        );
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFloating,
                Constants.YEAR_IN_SECONDS * Constants.D18
            ),
            98703000000000000000000,
            "Wrong interest floating"
        );
        Assert.equal(
            derivativeInterest.positionValue,
            -270419178082191780821,
            "Wrong interest difference amount"
        );
    }

    function testCalculateInterestCase25daysLaterIBTPriceNotChangedDecimal6()
        public
    {
        //given
        uint256 fixedInterestRate = 40000;
        DataTypes.IporDerivative memory derivative = prepareDerivativeCase2(
            fixedInterestRate
        );

        uint256 ibtPriceSecond = 100 * Constants.D6;

        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
            .calculateInterest(
                derivative.startingTimestamp + PERIOD_25_DAYS_IN_SECONDS,
                ibtPriceSecond
            );

        //then
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFixed,
                Constants.YEAR_IN_SECONDS * Constants.D6
            ),
            98973419178,
            "Wrong interest fixed"
        );
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFloating,
                Constants.YEAR_IN_SECONDS * Constants.D6
            ),
            98703000000,
            "Wrong interest floating"
        );
        Assert.equal(
            derivativeInterest.positionValue,
            -270419177,
            "Wrong interest difference amount"
        );
    }

    function testCalculateInterestCase25daysLaterIBTPriceChangedDecimals18()
        public
    {
        //given
        uint256 fixedInterestRate = 40000000000000000;
        DataTypes.IporDerivative memory derivative = prepareDerivativeCase1(
            fixedInterestRate
        );

        uint256 ibtPriceSecond = 125 * Constants.D18;

        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
            .calculateInterest(
                derivative.startingTimestamp + PERIOD_25_DAYS_IN_SECONDS,
                ibtPriceSecond
            );

        //then
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFixed,
                Constants.YEAR_IN_SECONDS * Constants.D18
            ),
            98973419178082191780822,
            "Wrong interest fixed"
        );
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFloating,
                Constants.YEAR_IN_SECONDS * Constants.D18
            ),
            123378750000000000000000,
            "Wrong interest floating"
        );
        Assert.equal(
            derivativeInterest.positionValue,
            24405330821917808219178,
            "Wrong interest difference amount"
        );
    }

    function testCalculateInterestCase25daysLaterIBTPriceChangedDecimals6()
        public
    {
        //given
        uint256 fixedInterestRate = 40000;
        DataTypes.IporDerivative memory derivative = prepareDerivativeCase2(
            fixedInterestRate
        );

        uint256 ibtPriceSecond = 125 * Constants.D6;

        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
            .calculateInterest(
                derivative.startingTimestamp + PERIOD_25_DAYS_IN_SECONDS,
                ibtPriceSecond
            );

        //then
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFixed,
                Constants.YEAR_IN_SECONDS * Constants.D6
            ),
            98973419178,
            "Wrong interest fixed"
        );
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFloating,
                Constants.YEAR_IN_SECONDS * Constants.D6
            ),
            123378750000,
            "Wrong interest floating"
        );
        Assert.equal(
            derivativeInterest.positionValue,
            24405330822,
            "Wrong interest difference amount"
        );
    }

    function testCalculateInterestCaseHugeIpor25daysLaterIBTPriceChangedUserLosesDecimals18()
        public
    {
        //given
        uint256 iporIndex = 3650000000000000000;
        uint256 spread = 10000000000000000;
        uint256 fixedInterestRate = iporIndex + spread;

        DataTypes.IporDerivative memory derivative = prepareDerivativeCase1(
            fixedInterestRate
        );

        uint256 ibtPriceSecond = 125 * Constants.D18;

        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
            .calculateInterest(
                derivative.startingTimestamp + PERIOD_25_DAYS_IN_SECONDS,
                ibtPriceSecond
            );

        //then
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFixed,
                Constants.YEAR_IN_SECONDS * Constants.D18
            ),
            123446354794520547945205,
            "Wrong interest fixed"
        );
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFloating,
                Constants.YEAR_IN_SECONDS * Constants.D18
            ),
            123378750000000000000000,
            "Wrong interest floating"
        );
        Assert.equal(
            derivativeInterest.positionValue,
            -67604794520547945204,
            "Wrong interest difference amount"
        );
    }

    function testCalculateInterestCaseHugeIpor25daysLaterIBTPriceChangedUserLosesDecimals6()
        public
    {
        //given
        uint256 iporIndex = 3650000;
        uint256 spread = 10000;
        uint256 fixedInterestRate = iporIndex + spread;

        DataTypes.IporDerivative memory derivative = prepareDerivativeCase2(
            fixedInterestRate
        );

        uint256 ibtPriceSecond = 125 * Constants.D6;

        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
            .calculateInterest(
                derivative.startingTimestamp + PERIOD_25_DAYS_IN_SECONDS,
                ibtPriceSecond
            );

        //then
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFixed,
                Constants.YEAR_IN_SECONDS * Constants.D6
            ),
            123446354795,
            "Wrong interest fixed"
        );
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFloating,
                Constants.YEAR_IN_SECONDS * Constants.D6
            ),
            123378750000,
            "Wrong interest floating"
        );
        Assert.equal(
            derivativeInterest.positionValue,
            -67604794,
            "Wrong interest difference amount"
        );
    }

    function testCalculateInterestCase100daysLaterIBTPriceNotChangedDecimals18()
        public
    {
        //given
        uint256 fixedInterestRate = 40000000000000000;
        DataTypes.IporDerivative memory derivative = prepareDerivativeCase1(
            fixedInterestRate
        );

        uint256 ibtPriceSecond = 100 * Constants.D18;

        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
            .calculateInterest(
                derivative.startingTimestamp + PERIOD_25_DAYS_IN_SECONDS * 4,
                ibtPriceSecond
            );

        //then
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFixed,
                Constants.YEAR_IN_SECONDS * Constants.D18
            ),
            99005869479452054794521,
            "Wrong interest fixed"
        );
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFloating,
                Constants.YEAR_IN_SECONDS * Constants.D18
            ),
            98703000000000000000000,
            "Wrong interest floating"
        );
        Assert.equal(
            derivativeInterest.positionValue,
            -302869479452054794520,
            "Wrong interest difference amount"
        );
    }

    function testCalculateInterestCase100daysLaterIBTPriceNotChangedDecimals6()
        public
    {
        //given
        uint256 fixedInterestRate = 40000;
        DataTypes.IporDerivative memory derivative = prepareDerivativeCase2(
            fixedInterestRate
        );

        uint256 ibtPriceSecond = 100 * Constants.D6;

        //when
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
            .calculateInterest(
                derivative.startingTimestamp + PERIOD_25_DAYS_IN_SECONDS * 4,
                ibtPriceSecond
            );

        //then
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFixed,
                Constants.YEAR_IN_SECONDS * Constants.D6
            ),
            99005869479,
            "Wrong interest fixed"
        );
        Assert.equal(
            AmmMath.division(
                derivativeInterest.quasiInterestFloating,
                Constants.YEAR_IN_SECONDS * Constants.D6
            ),
            98703000000,
            "Wrong interest floating"
        );
        Assert.equal(
            derivativeInterest.positionValue,
            -302869478,
            "Wrong interest difference amount"
        );
    }
}
