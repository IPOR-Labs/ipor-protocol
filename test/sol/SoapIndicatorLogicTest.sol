// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import '../../contracts/amm/MiltonV1.sol';
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/libraries/SoapIndicatorLogic.sol";
import "./TestData.sol";

contract SoapIndicatorLogicTest is TestData {

    using SoapIndicatorLogic  for DataTypes.SoapIndicator;

    DataTypes.SoapIndicator public siStorage;

    function testCalculateInterestRateWhenOpenPositionSimpleCase() public {
        //given
        DataTypes.SoapIndicator memory soapIndicator = prepareSoapIndicatorPfCase1();
        uint256 derivativeNotional = 10000 * 1e18;
        uint256 derivativeFixedInterestRate = 4 * 1e16;

        //when
        uint256 actualInterestRate = soapIndicator.calculateInterestRateWhenOpenPosition(derivativeNotional, derivativeFixedInterestRate);

        //then
        uint256 expectedInterestRate = 66666666666666667;
        Assert.equal(expectedInterestRate, actualInterestRate, "Wrong interest rate when open position");
    }

    function testCalculateInterestRateWhenClosePositionSimpleCase() public {
        //given
        DataTypes.SoapIndicator memory soapIndicator = prepareSoapIndicatorPfCase1();
        uint256 derivativeNotional = 10000 * 1e18;
        uint256 derivativeFixedInterestRate = 4 * 1e16;

        //when
        uint256 actualInterestRate = soapIndicator.calculateInterestRateWhenClosePosition(derivativeNotional, derivativeFixedInterestRate);

        //then
        uint256 expectedInterestRate = 120000000000000000;
        Assert.equal(expectedInterestRate, actualInterestRate, "Wrong hypothetical interest rate when close position");

    }

    function testCalculateInterestRateWhenClosePositionDerivativeNotionalTooHigh() public {
        //given
        DataTypes.SoapIndicator memory soapIndicator = prepareSoapIndicatorPfCase1();
        uint256 derivativeNotional = 40000 * 1e18;
        uint256 derivativeFixedInterestRate = 4 * 1e16;

        //when
        try soapIndicator.calculateInterestRateWhenClosePosition(derivativeNotional, derivativeFixedInterestRate) returns (uint256) {
        } catch Error(string memory actualReason) {
            //then
            Assert.equal(actualReason, Errors.AMM_DERIVATIVE_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL, "Wrong reason");
        }
    }

    function testCalculateInterestDeltaSimpleCase() public {
        //given
        DataTypes.SoapIndicator memory soapIndicator = prepareSoapIndicatorPfCase1();
        uint256 timestamp = soapIndicator.rebalanceTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        uint256 actualInterestRate = soapIndicator.calculateQuasiHypotheticalInterestDelta(timestamp);

        //then
        uint256 expectedInterestDelta = 3456000000 * 1e54;
        Assert.equal(actualInterestRate, expectedInterestDelta, "Incorrect interest in delta time");
    }

    function testCalculateHyphoteticalInterestTotalCase1() public {
        //given
        DataTypes.SoapIndicator memory soapIndicator = prepareSoapIndicatorPfCase1();
        uint256 timestamp = soapIndicator.rebalanceTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        uint256 actualQuasiHypotheticalInterestTotal = soapIndicator.calculateQuasiHyphoteticalInterestTotal(timestamp);

        //then
        uint256 expectedQuasiHypotheticalInterestTotal = 19224000000 * 1e54;

        Assert.equal(actualQuasiHypotheticalInterestTotal, expectedQuasiHypotheticalInterestTotal, "Incorrect hypothetical interest total quasi");

    }

    function testRebalanceSoapIndicatorsWhenOpenFirstPosition() public {
        //given
        siStorage = prepareInitialDefaultSoapIndicator(block.timestamp);
        uint256 rebalanceTimestamp = siStorage.rebalanceTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        uint256 derivativeNotional = 10000 * 1e18;
        uint256 derivativeFixedInterestRate = 5 * 1e16;
        uint256 derivativeIbtQuantity = 95 * 1e18;

        //when
        siStorage.rebalanceWhenOpenPosition(rebalanceTimestamp, derivativeNotional, derivativeFixedInterestRate, derivativeIbtQuantity);

        //then
        assertSoapIndicator(siStorage, rebalanceTimestamp, derivativeNotional, derivativeIbtQuantity, derivativeFixedInterestRate, 0);
    }

    function testRebalanceSoapIndicatorsWhenOpenSecondPosition() public {
        //given
        siStorage = prepareInitialDefaultSoapIndicator(block.timestamp);
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
        uint256 expectedQuasiHypotheticalInterestCumulative = 1080000000 * 1e54;

        assertSoapIndicator(
            siStorage,
            expectedRebalanceTimestamp,
            expectedTotalNotional,
            expectedTotalIbtQuantity,
            expectedAverageInterestRate,
            expectedQuasiHypotheticalInterestCumulative
        );

    }

    function testRebalanceSoapIndicatorsWhenCloseFirstPosition() public {
        //given
        siStorage = prepareInitialDefaultSoapIndicator(block.timestamp);
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

        assertSoapIndicator(
            siStorage,
            expectedRebalanceTimestamp,
            expectedTotalNotional,
            expectedTotalIbtQuantity,
            expectedAverageInterestRate,
            expectedHypotheticalInterestCumulative
        );
    }

    function testRebalanceSoapIndicatorsWhenOpenTwoPositionCloseSecondPosition() public {

        //given
        siStorage = prepareInitialDefaultSoapIndicator(block.timestamp);
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
        uint256 expectedHypotheticalInterestCumulative = 2160000000 * 1e54;

        assertSoapIndicator(
            siStorage,
            expectedRebalanceTimestamp,
            expectedTotalNotional,
            expectedTotalIbtQuantity,
            expectedAverageInterestRate,
            expectedHypotheticalInterestCumulative
        );
    }

    function testRebalanceSoapIndicatorsWhenOpenTwoPositionCloseTwoPosition() public {

        //given
        siStorage = prepareInitialDefaultSoapIndicator(block.timestamp);
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

        siStorage.rebalanceWhenOpenPosition(
            rebalanceTimestampSecond,
            derivativeNotionalSecond,
            derivativeFixedInterestRateSecond,
            derivativeIbtQuantitySecond);

        uint256 closeTimestampSecondPosition = rebalanceTimestampSecond + PERIOD_25_DAYS_IN_SECONDS;

        siStorage.rebalanceWhenClosePosition(
            closeTimestampSecondPosition,
            rebalanceTimestampSecond,
            derivativeNotionalSecond,
            derivativeFixedInterestRateSecond,
            derivativeIbtQuantitySecond
        );

        uint256 closeTimestampFirstPosition = siStorage.rebalanceTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        siStorage.rebalanceWhenClosePosition(
            closeTimestampFirstPosition,
            rebalanceTimestampFirst,
            derivativeNotionalFirst,
            derivativeFixedInterestRateFirst,
            derivativeIbtQuantityFirst
        );

        //then
        uint256 expectedRebalanceTimestamp = closeTimestampFirstPosition;
        uint256 expectedTotalNotional = 0;
        uint256 expectedTotalIbtQuantity = 0;
        uint256 expectedAverageInterestRate = 0;
        uint256 expectedHypotheticalInterestCumulative = 0;

        assertSoapIndicator(
            siStorage,
            expectedRebalanceTimestamp,
            expectedTotalNotional,
            expectedTotalIbtQuantity,
            expectedAverageInterestRate,
            expectedHypotheticalInterestCumulative
        );
    }

    function testSoapPayFixedSimpleCase() public {
        //given
        siStorage = prepareSoapIndicatorPfCase1();
        uint256 ibtPrice = 145 * 1e18;
        uint256 calculationTimestamp = siStorage.rebalanceTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        int256 actualSoapPf = siStorage.calculateSoap(ibtPrice, calculationTimestamp);

        //then
        int256 expectedSoapPf = -6109589041095890410958;
        Assert.equal(actualSoapPf, expectedSoapPf, 'Incorrect SOAP for Pay Fixed Derivatives');
    }

    function testSoapRecFixedSimpleCase() public {
        //given
        siStorage = prepareSoapIndicatorRfCase1();
        uint256 ibtPrice = 145 * 1e18;
        uint256 calculationTimestamp = siStorage.rebalanceTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        int256 actualSoapPf = siStorage.calculateSoap(ibtPrice, calculationTimestamp);

        //then
        int256 expectedSoapPf = 6109589041095890410959;
        Assert.equal(actualSoapPf, expectedSoapPf, 'Incorrect SOAP for Pay Fixed Derivatives');
    }

}