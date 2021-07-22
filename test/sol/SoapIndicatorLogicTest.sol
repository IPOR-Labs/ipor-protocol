// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import '../../contracts/amm/IporAmmV1.sol';
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/libraries/SoapIndicatorLogic.sol";

contract SoapIndicatorLogicTest {

    using SoapIndicatorLogic  for DataTypes.SoapIndicator;

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
        uint256 expectedInterestRate = 40000000000000000;
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

    function testUpdateWhenOpenFirstPosition() public {
        //given
        DataTypes.SoapIndicator memory si = prepareInitialSoapIndicator(block.timestamp);
        uint256 rebalanceTimestamp = si.rebalanceTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        uint256 ibtPrice = 105 * 1e18;
        uint256 derivativeNotional = 10000 * 1e18;
        uint256 derivativeFixedInterestRate = 5 * 1e16;
        uint256 derivativeIbtQuantity = 95 * 1e18;

        //when
        si.rebalanceWhenOpenPosition(rebalanceTimestamp, ibtPrice, derivativeNotional, derivativeFixedInterestRate, derivativeIbtQuantity);

        //then
        uint256 expectedTotalNotional = derivativeNotional;
        uint256 expectedTotalIbtQuantity = derivativeIbtQuantity;
        uint256 expectedAverageInterestRate = 10;
        uint256 expectedHypotheticalInterestCumulative = 10;

        Assert.equal(si.totalNotional, expectedTotalNotional, 'Incorrect total notional');
        Assert.equal(si.totalIbtQuantity, expectedTotalIbtQuantity, 'Incorrect total IBT quantity');
        Assert.equal(si.averageInterestRate, expectedAverageInterestRate, 'Incorrect average weighted interest rate');
        Assert.equal(si.hypotheticalInterestCumulative, expectedHypotheticalInterestCumulative, 'Incorrect hypothetical interest cumulative');
    }

    function testUpdateWhenOpenSecondPosition() public {
        //given
        DataTypes.SoapIndicator memory si = prepareInitialSoapIndicator(block.timestamp);
        //when

        //then
    }


    function prepareInitialSoapIndicator(uint256 timestamp) internal view returns (DataTypes.SoapIndicator memory) {
        DataTypes.SoapIndicator memory soapIndicator = DataTypes.SoapIndicator(timestamp, 0, 0, 0, 0);
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
            totalIbtQuantity
        );

        return soapIndicator;
    }
}