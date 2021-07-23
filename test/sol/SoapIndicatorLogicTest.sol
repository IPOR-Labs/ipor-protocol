// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import '../../contracts/amm/IporAmmV1.sol';
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/libraries/SoapIndicatorLogic.sol";

contract SoapIndicatorLogicTest {

    using SoapIndicatorLogic  for DataTypes.SoapIndicator;

    DataTypes.SoapIndicator public siStorage;

    //    constructor() public {
    //        siStorage = prepareInitialSoapIndicator(block.timestamp);
    //    }

    uint256 constant PERIOD_25_DAYS_IN_SECONDS = 60 * 60 * 24 * 25;

    function testCalculatInterestRateWhenOpenPositionSimpleCase() public {
        //given
        DataTypes.SoapIndicator memory soapIndicator = prepareSoapIndicatorCase1();
        uint256 derivativeNotional = 10000 * 1e18;
        uint256 derivativeFixedInterestRate = 4 * 1e16;

        //when
        uint256 actualInterestRate = soapIndicator.calculatInterestRateWhenOpenPosition(derivativeNotional, derivativeFixedInterestRate);

        //then
        uint256 expectedInterestRate = 66666666666666666;
        Assert.equal(expectedInterestRate, actualInterestRate, "Wrong interest rate when open position");
    }

    function testCalculatInterestRateWhenClosePositionSimpleCase() public {
        //given
        DataTypes.SoapIndicator memory soapIndicator = prepareSoapIndicatorCase1();
        uint256 derivativeNotional = 10000 * 1e18;
        uint256 derivativeFixedInterestRate = 4 * 1e16;

        //when
        uint256 actualInterestRate = soapIndicator.calculatInterestRateWhenClosePosition(derivativeNotional, derivativeFixedInterestRate);

        //then
        uint256 expectedInterestRate = 120000000000000000;
        Assert.equal(expectedInterestRate, actualInterestRate, "Wrong hypothetical interest rate when close position");

    }

    function testCalculatInterestRateWhenClosePositionDerivativeNotionalTooHigh() public {
        //given
        DataTypes.SoapIndicator memory soapIndicator = prepareSoapIndicatorCase1();
        uint256 derivativeNotional = 40000 * 1e18;
        uint256 derivativeFixedInterestRate = 4 * 1e16;

        //when
        try soapIndicator.calculatInterestRateWhenClosePosition(derivativeNotional, derivativeFixedInterestRate) returns (uint256) {
        } catch Error(string memory actualReason) {
            //then
            Assert.equal(actualReason, Errors.AMM_DERIVATIVE_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL, "Wrong reason");
        }
    }

    function testCalculateInterestDeltaSimpleCase() public {
        //given
        DataTypes.SoapIndicator memory soapIndicator = prepareSoapIndicatorCase1();
        uint256 timestamp = soapIndicator.rebalanceTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        uint256 actualInterestRate = soapIndicator.calculateHypotheticalInterestDelta(timestamp);

        //then
        uint256 expectedInterestDelta = 109589041095890410958;
        Assert.equal(actualInterestRate, expectedInterestDelta, "Incorrect interest in delta time");
    }

    function testCalculateHyphoteticalInterestTotalCase1() public {
        //given
        DataTypes.SoapIndicator memory soapIndicator = prepareSoapIndicatorCase1();
        uint256 timestamp = soapIndicator.rebalanceTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        uint256 actualHypotheticalInterestTotal = soapIndicator.calculateHyphoteticalInterestTotal(timestamp);

        //then
        uint256 expectedHypotheticalInterestTotal = 609589041095890410958;

        Assert.equal(actualHypotheticalInterestTotal, expectedHypotheticalInterestTotal, "Incorrect hypothetical interest total");

    }

    function testRebalanceSoapIndicatorsWhenOpenFirstPosition() public {
        //given
        siStorage = prepareInitialSoapIndicator(block.timestamp);
        uint256 rebalanceTimestamp = siStorage.rebalanceTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        uint256 derivativeNotional = 10000 * 1e18;
        uint256 derivativeFixedInterestRate = 5 * 1e16;
        uint256 derivativeIbtQuantity = 95 * 1e18;

        //when
        siStorage.rebalanceWhenOpenPosition(rebalanceTimestamp, derivativeNotional, derivativeFixedInterestRate, derivativeIbtQuantity);

        //then
        uint256 expectedRebalanceTimestamp = rebalanceTimestamp;
        uint256 expectedTotalNotional = derivativeNotional;
        uint256 expectedTotalIbtQuantity = derivativeIbtQuantity;
        uint256 expectedAverageInterestRate = derivativeFixedInterestRate;
        uint256 expectedHypotheticalInterestCumulative = 0;

        Assert.equal(siStorage.rebalanceTimestamp, expectedRebalanceTimestamp, 'Incorrect rebalance timestamp');
        Assert.equal(siStorage.totalNotional, expectedTotalNotional, 'Incorrect total notional');
        Assert.equal(siStorage.totalIbtQuantity, expectedTotalIbtQuantity, 'Incorrect total IBT quantity');
        Assert.equal(siStorage.averageInterestRate, expectedAverageInterestRate, 'Incorrect average weighted interest rate');
        Assert.equal(siStorage.hypotheticalInterestCumulative, expectedHypotheticalInterestCumulative, 'Incorrect hypothetical interest cumulative');
    }

    function testRebalanceSoapIndicatorsWhenOpenSecondPosition() public {
        //given
        siStorage = prepareInitialSoapIndicator(block.timestamp);
        uint256 rebalanceTimestampFirst = siStorage.rebalanceTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        uint256 derivativeNotionalFirst = 10000 * 1e18;
        uint256 derivativeFixedInterestRateFirst = 5 * 1e16;
        uint256 derivativeIbtQuantityFirst = 95 * 1e18;

        siStorage.rebalanceWhenOpenPosition(
            rebalanceTimestampFirst, derivativeNotionalFirst, derivativeFixedInterestRateFirst,
            derivativeIbtQuantityFirst);

        uint256 rebalanceTimestampSecond = siStorage.rebalanceTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        uint256 derivativeNotionalSecond = 20000 * 1e18;
        uint256 derivativeFixedInterestRateSecond = 8 * 1e16;
        uint256 derivativeIbtQuantitySecond = 173 * 1e18;

        //when
        siStorage.rebalanceWhenOpenPosition(
            rebalanceTimestampSecond,
            derivativeNotionalSecond,
            derivativeFixedInterestRateSecond,
            derivativeIbtQuantitySecond);

        //then
        uint256 expectedRebalanceTimestamp = rebalanceTimestampSecond;
        uint256 expectedTotalNotional = 30000 * 1e18;
        uint256 expectedTotalIbtQuantity = 268 * 1e18;
        uint256 expectedAverageInterestRate = 7 * 1e16;
        uint256 expectedHypotheticalInterestCumulative = 34246575342465753424;

        Assert.equal(siStorage.rebalanceTimestamp, expectedRebalanceTimestamp, 'Incorrect rebalance timestamp');
        Assert.equal(siStorage.totalNotional, expectedTotalNotional, 'Incorrect total notional');
        Assert.equal(siStorage.totalIbtQuantity, expectedTotalIbtQuantity, 'Incorrect total IBT quantity');
        Assert.equal(siStorage.averageInterestRate, expectedAverageInterestRate, 'Incorrect average weighted interest rate');
        Assert.equal(siStorage.hypotheticalInterestCumulative, expectedHypotheticalInterestCumulative, 'Incorrect hypothetical interest cumulative');
    }

    function testRebalanceSoapIndicatorsWhenCloseFirstPosition() public {
        //given
        siStorage = prepareInitialSoapIndicator(block.timestamp);
        uint256 rebalanceTimestampFirst = siStorage.rebalanceTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        uint256 derivativeNotionalFirst = 10000 * 1e18;
        uint256 derivativeFixedInterestRateFirst = 5 * 1e16;
        uint256 derivativeIbtQuantityFirst = 95 * 1e18;

        siStorage.rebalanceWhenOpenPosition(
            rebalanceTimestampFirst,
            derivativeNotionalFirst,
            derivativeFixedInterestRateFirst,
            derivativeIbtQuantityFirst);

        uint256 closeTimestamp = rebalanceTimestampFirst + PERIOD_25_DAYS_IN_SECONDS;

        //when
        siStorage.rebalanceWhenClosePosition(
            closeTimestamp,
            rebalanceTimestampFirst,
            derivativeNotionalFirst,
            derivativeFixedInterestRateFirst,
            derivativeIbtQuantityFirst
        );

        //then
        uint256 expectedRebalanceTimestamp = closeTimestamp;
        uint256 expectedTotalNotional = 0;
        uint256 expectedTotalIbtQuantity = 0;
        uint256 expectedAverageInterestRate = 0;
        uint256 expectedHypotheticalInterestCumulative = 0;

        Assert.equal(siStorage.rebalanceTimestamp, expectedRebalanceTimestamp, 'Incorrect rebalance timestamp');
        Assert.equal(siStorage.totalNotional, expectedTotalNotional, 'Incorrect total notional');
        Assert.equal(siStorage.totalIbtQuantity, expectedTotalIbtQuantity, 'Incorrect total IBT quantity');
        Assert.equal(siStorage.averageInterestRate, expectedAverageInterestRate, 'Incorrect average weighted interest rate');
        Assert.equal(siStorage.hypotheticalInterestCumulative, expectedHypotheticalInterestCumulative, 'Incorrect hypothetical interest cumulative');
    }

    function testRebalanceSoapIndicatorsWhenOpenTwoPositionCloseSecondPosition() public {

        //given
        siStorage = prepareInitialSoapIndicator(block.timestamp);
        uint256 rebalanceTimestampFirst = siStorage.rebalanceTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        uint256 derivativeNotionalFirst = 10000 * 1e18;
        uint256 derivativeFixedInterestRateFirst = 5 * 1e16;
        uint256 derivativeIbtQuantityFirst = 95 * 1e18;

        siStorage.rebalanceWhenOpenPosition(
            rebalanceTimestampFirst, derivativeNotionalFirst, derivativeFixedInterestRateFirst,
            derivativeIbtQuantityFirst);

        uint256 averageInterestRateAfterFirstOpen = siStorage.averageInterestRate;

        uint256 rebalanceTimestampSecond = siStorage.rebalanceTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        uint256 derivativeNotionalSecond = 20000 * 1e18;
        uint256 derivativeFixedInterestRateSecond = 8 * 1e16;
        uint256 derivativeIbtQuantitySecond = 173 * 1e18;

        siStorage.rebalanceWhenOpenPosition(
            rebalanceTimestampSecond,
            derivativeNotionalSecond,
            derivativeFixedInterestRateSecond,
            derivativeIbtQuantitySecond);

        uint256 closeTimestamp = rebalanceTimestampSecond + PERIOD_25_DAYS_IN_SECONDS;

        //when
        siStorage.rebalanceWhenClosePosition(
            closeTimestamp,
            rebalanceTimestampSecond,
            derivativeNotionalSecond,
            derivativeFixedInterestRateSecond,
            derivativeIbtQuantitySecond
        );

        //then
        uint256 expectedRebalanceTimestamp = closeTimestamp;
        uint256 expectedTotalNotional = 10000 * 1e18;
        uint256 expectedTotalIbtQuantity = 95 * 1e18;
        uint256 expectedAverageInterestRate = averageInterestRateAfterFirstOpen;
        uint256 expectedHypotheticalInterestCumulative = ;

        Assert.equal(siStorage.rebalanceTimestamp, expectedRebalanceTimestamp, 'Incorrect rebalance timestamp');
        Assert.equal(siStorage.totalNotional, expectedTotalNotional, 'Incorrect total notional');
        Assert.equal(siStorage.totalIbtQuantity, expectedTotalIbtQuantity, 'Incorrect total IBT quantity');
        Assert.equal(siStorage.averageInterestRate, expectedAverageInterestRate, 'Incorrect average weighted interest rate');
        Assert.equal(siStorage.hypotheticalInterestCumulative, expectedHypotheticalInterestCumulative, 'Incorrect hypothetical interest cumulative');
    }


    function prepareInitialSoapIndicator(uint256 timestamp) internal pure returns (DataTypes.SoapIndicator memory) {
        DataTypes.SoapIndicator memory soapIndicator = DataTypes.SoapIndicator(timestamp, 0, 0, 0, 0, 0);
        return soapIndicator;
    }

    function prepareSoapIndicatorCase1() internal view returns (DataTypes.SoapIndicator memory) {
        uint256 totalNotional = 20000 * 1e18;
        uint256 averageInterestRate = 8 * 1e16;
        uint256 totalIbtQuantity = 100 * 1e18;
        uint256 hypotheticalInterestCumulative = 500 * 1e18;

        DataTypes.SoapIndicator memory soapIndicator = DataTypes.SoapIndicator(
            block.timestamp,
            hypotheticalInterestCumulative,
            totalNotional,
            averageInterestRate,
            totalIbtQuantity,
            0
        );

        return soapIndicator;
    }
}