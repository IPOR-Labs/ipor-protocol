// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import '../../contracts/amm/IporAmmV1.sol';
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/libraries/TotalSoapIndicatorLogic.sol";
import "./TestData.sol";

contract TotalSoapIndicatorLogicTest is TestData {

    event Log(string name, uint256 value);

    using SoapIndicatorLogic  for DataTypes.SoapIndicator;
    using TotalSoapIndicatorLogic for DataTypes.TotalSoapIndicator;

    DataTypes.TotalSoapIndicator public tsiStorage;

    function testCalculateSoapWhenOpenPayFixPosition() public {
        //given
        uint256 ibtPrice = 100 * 1e18;
        uint256 timestamp = block.timestamp;
        tsiStorage = prepareInitialTotalSoapIndicator(timestamp);
        simulateOpenPayFixPositionCase2(0);

        //when
        int256 soap = tsiStorage.calculateSoap(timestamp + PERIOD_25_DAYS_IN_SECONDS, ibtPrice);

        //then
        int256 expectedSOAP = - 202814383561643835616;
        Assert.equal(soap, expectedSOAP, 'Incorrect SOAP');
    }

    function testCalculateSoapWhenOpenPayFixAndRecFixPositionSameNotional() public {
        //given
        uint256 ibtPrice = 100 * 1e18;
        uint256 timestamp = block.timestamp;
        tsiStorage = prepareInitialTotalSoapIndicator(timestamp);
        simulateOpenPayFixPositionCase2(0);
        simulateOpenRecFixPositionCase2(0);

        //when
        int256 soap = tsiStorage.calculateSoap(timestamp + PERIOD_25_DAYS_IN_SECONDS, ibtPrice);

        //then
        int256 expectedSOAP = 0;
        Assert.equal(soap, expectedSOAP, 'Incorrect SOAP');
    }

    function testRebalanceSoapWhenOpenPayFixPosition() public {
        //given
        tsiStorage = prepareInitialTotalSoapIndicator(block.timestamp);

        //when
        simulateOpenPayFixPositionCase1(PERIOD_25_DAYS_IN_SECONDS);

        //then
        uint256 expectedRebalanceTimestamp = tsiStorage.pf.rebalanceTimestamp;
        uint256 expectedTotalNotional = 10000 * 1e18;
        uint256 expectedTotalIbtQuantity = 95 * 1e18;
        uint256 expectedAverageInterestRate = 5 * 1e16;
        uint256 expectedHypotheticalInterestCumulative = 0;

        assertSoapIndicator(
            tsiStorage.pf,
            expectedRebalanceTimestamp,
            expectedTotalNotional,
            expectedTotalIbtQuantity,
            expectedAverageInterestRate,
            expectedHypotheticalInterestCumulative
        );

    }

    function testRebalanceSoapWhenOpenRecFixPosition() public {
        //given
        tsiStorage = prepareInitialTotalSoapIndicator(block.timestamp);

        //when
        simulateOpenRecFixPositionCase1(PERIOD_25_DAYS_IN_SECONDS);

        //then
        uint256 expectedRebalanceTimestamp = tsiStorage.rf.rebalanceTimestamp;
        uint256 expectedTotalNotional = 10000 * 1e18;
        uint256 expectedTotalIbtQuantity = 95 * 1e18;
        uint256 expectedAverageInterestRate = 5 * 1e16;
        uint256 expectedHypotheticalInterestCumulative = 0;

        assertSoapIndicator(
            tsiStorage.rf,
            expectedRebalanceTimestamp,
            expectedTotalNotional,
            expectedTotalIbtQuantity,
            expectedAverageInterestRate,
            expectedHypotheticalInterestCumulative
        );

    }

    function testRebalanceSoapWhenPayFixAndRecFixPosition() public {
        //given
        tsiStorage = prepareInitialTotalSoapIndicator(block.timestamp);

        //when
        simulateOpenPayFixPositionCase1(PERIOD_25_DAYS_IN_SECONDS);
        simulateOpenRecFixPositionCase1(PERIOD_25_DAYS_IN_SECONDS);

        //then
        uint256 expectedRebalanceTimestamp = tsiStorage.pf.rebalanceTimestamp;
        uint256 expectedTotalNotional = 10000 * 1e18;
        uint256 expectedTotalIbtQuantity = 95 * 1e18;
        uint256 expectedAverageInterestRate = 5 * 1e16;
        uint256 expectedHypotheticalInterestCumulative = 0;

        assertSoapIndicator(
            tsiStorage.pf,
            expectedRebalanceTimestamp,
            expectedTotalNotional,
            expectedTotalIbtQuantity,
            expectedAverageInterestRate,
            expectedHypotheticalInterestCumulative
        );

        assertSoapIndicator(
            tsiStorage.rf,
            expectedRebalanceTimestamp,
            expectedTotalNotional,
            expectedTotalIbtQuantity,
            expectedAverageInterestRate,
            expectedHypotheticalInterestCumulative
        );
    }

    function simulateOpenPayFixPositionCase1(uint256 deltaTimeInSeconds) internal {
        uint256 rebalanceTimestamp = tsiStorage.pf.rebalanceTimestamp + deltaTimeInSeconds;
        uint256 derivativeNotional = 10000 * 1e18;
        uint256 derivativeFixedInterestRate = 5 * 1e16;
        uint256 derivativeIbtQuantity = 95 * 1e18;
        tsiStorage.pf.rebalanceWhenOpenPosition(rebalanceTimestamp, derivativeNotional, derivativeFixedInterestRate, derivativeIbtQuantity);
    }

    function simulateOpenPayFixPositionCase2(uint256 deltaTimeInSeconds) internal {
        uint256 rebalanceTimestamp = tsiStorage.pf.rebalanceTimestamp + deltaTimeInSeconds;
        uint256 derivativeNotional = 98703 * 1e18;
        uint256 derivativeFixedInterestRate = 3 * 1e16;
        uint256 derivativeIbtQuantity = 98703 * 1e16;
        tsiStorage.pf.rebalanceWhenOpenPosition(rebalanceTimestamp, derivativeNotional, derivativeFixedInterestRate, derivativeIbtQuantity);
    }

    function simulateOpenRecFixPositionCase1(uint256 deltaTimeInSeconds) internal {
        uint256 rebalanceTimestamp = tsiStorage.rf.rebalanceTimestamp + deltaTimeInSeconds;
        uint256 derivativeNotional = 10000 * 1e18;
        uint256 derivativeFixedInterestRate = 5 * 1e16;
        uint256 derivativeIbtQuantity = 95 * 1e18;
        tsiStorage.rf.rebalanceWhenOpenPosition(rebalanceTimestamp, derivativeNotional, derivativeFixedInterestRate, derivativeIbtQuantity);
    }

    function simulateOpenRecFixPositionCase2(uint256 deltaTimeInSeconds) internal {
        uint256 rebalanceTimestamp = tsiStorage.rf.rebalanceTimestamp + deltaTimeInSeconds;
        uint256 derivativeNotional = 98703 * 1e18;
        uint256 derivativeFixedInterestRate = 3 * 1e16;
        uint256 derivativeIbtQuantity = 98703 * 1e16;
        tsiStorage.rf.rebalanceWhenOpenPosition(rebalanceTimestamp, derivativeNotional, derivativeFixedInterestRate, derivativeIbtQuantity);
    }
}