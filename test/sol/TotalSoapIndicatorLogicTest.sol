// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../../contracts/amm/Milton.sol";
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/libraries/TotalSoapIndicatorLogic.sol";
import "./TestData.sol";

contract TotalSoapIndicatorLogicTest is TestData {
    using SoapIndicatorLogic for DataTypes.SoapIndicator;
    using TotalSoapIndicatorLogic for DataTypes.TotalSoapIndicator;

    DataTypes.TotalSoapIndicator public tsiStorage;

    function testCalculateSoapWhenOpenPayFixPositionD18() public {
        //given
        uint256 ibtPrice = 100 * Constants.D18;
        uint256 timestamp = block.timestamp;
        tsiStorage = prepareInitialTotalSoapIndicator(timestamp);
        simulateOpenPayFixPositionCase2D18(PERIOD_1_DAY_IN_SECONDS);

        //when
        (int256 soapPf, int256 soapRf) = tsiStorage.calculateSoap(
            timestamp + PERIOD_1_DAY_IN_SECONDS + PERIOD_25_DAYS_IN_SECONDS,
            ibtPrice
        );
        int256 soap = soapPf + soapRf;
        //then
        int256 expectedSOAP = -202814383561643835615;
        Assert.equal(soap, expectedSOAP, "Incorrect SOAP");
    }

    function testCalculateSoapWhenOpenPayFixAndRecFixPositionSameNotionalSameMomentD18()
        public
    {
        //given
        uint256 ibtPrice = 100 * Constants.D18;
        uint256 timestamp = block.timestamp;
        tsiStorage = prepareInitialTotalSoapIndicator(timestamp);
        simulateOpenPayFixPositionCase2D18(0);
        simulateOpenRecFixPositionCase2D18(0);

        //when
        (int256 qSoapPf, int256 qSoapRf) = tsiStorage.calculateQuasiSoap(
            timestamp + PERIOD_25_DAYS_IN_SECONDS,
            ibtPrice
        );
        int256 soap = qSoapPf + qSoapRf;
        //then
        int256 expectedSOAP = 0;
        Assert.equal(soap, expectedSOAP, "Incorrect SOAP");
    }

    function testCalculateSoapWhenOpenPayFixAndRecFixPositionSameNotionalDifferentMomentD18()
        public
    {
        //given
        uint256 ibtPrice = 100 * Constants.D18;
        uint256 timestamp = block.timestamp;
        tsiStorage = prepareInitialTotalSoapIndicator(timestamp);
        simulateOpenPayFixPositionCase2D18(PERIOD_25_DAYS_IN_SECONDS);
        simulateOpenRecFixPositionCase2D18(0);

        //when
        (int256 soapPf, int256 soapRf) = tsiStorage.calculateSoap(
            timestamp + PERIOD_25_DAYS_IN_SECONDS,
            ibtPrice
        );
        int256 soap = soapPf + soapRf;
        //then
        int256 expectedSOAP = 202814383561643835616;
        Assert.equal(soap, expectedSOAP, "Incorrect SOAP");
    }

    function testRebalanceSoapWhenOpenPayFixPositionD18() public {
        //given
        tsiStorage = prepareInitialTotalSoapIndicator(block.timestamp);

        //when
        simulateOpenPayFixPositionCase1D18(PERIOD_25_DAYS_IN_SECONDS);

        //then
        uint256 expectedRebalanceTimestamp = tsiStorage.pf.rebalanceTimestamp;
        uint256 expectedTotalNotional = 10000 * Constants.D18;
        uint256 expectedTotalIbtQuantity = 95 * Constants.D18;
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

    function testRebalanceSoapWhenOpenRecFixPositionD18() public {
        //given
        tsiStorage = prepareInitialTotalSoapIndicator(block.timestamp);

        //when
        simulateOpenRecFixPositionCase1D18(PERIOD_25_DAYS_IN_SECONDS);

        //then
        uint256 expectedRebalanceTimestamp = tsiStorage.rf.rebalanceTimestamp;
        uint256 expectedTotalNotional = 10000 * Constants.D18;
        uint256 expectedTotalIbtQuantity = 95 * Constants.D18;
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

    function testRebalanceSoapWhenPayFixAndRecFixPositionD18() public {
        //given
        tsiStorage = prepareInitialTotalSoapIndicator(block.timestamp);

        //when
        simulateOpenPayFixPositionCase1D18(PERIOD_25_DAYS_IN_SECONDS);
        simulateOpenRecFixPositionCase1D18(PERIOD_25_DAYS_IN_SECONDS);

        //then
        uint256 expectedRebalanceTimestamp = tsiStorage.pf.rebalanceTimestamp;
        uint256 expectedTotalNotional = 10000 * Constants.D18;
        uint256 expectedTotalIbtQuantity = 95 * Constants.D18;
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

    function simulateOpenPayFixPositionCase1D18(uint256 deltaTimeInSeconds)
        internal
    {
        uint256 rebalanceTimestamp = tsiStorage.pf.rebalanceTimestamp +
            deltaTimeInSeconds;
        uint256 derivativeNotional = 10000 * Constants.D18;
        uint256 derivativeFixedInterestRate = 5 * 1e16;
        uint256 derivativeIbtQuantity = 95 * Constants.D18;
        tsiStorage.pf.rebalanceWhenOpenPosition(
            rebalanceTimestamp,
            derivativeNotional,
            derivativeFixedInterestRate,
            derivativeIbtQuantity
        );
    }

    function simulateOpenPayFixPositionCase2D18(uint256 deltaTimeInSeconds)
        internal
    {
        uint256 rebalanceTimestamp = tsiStorage.pf.rebalanceTimestamp +
            deltaTimeInSeconds;
        uint256 derivativeNotional = 98703 * Constants.D18;
        uint256 derivativeFixedInterestRate = 3 * 1e16;
        uint256 derivativeIbtQuantity = 98703 * 1e16;
        tsiStorage.pf.rebalanceWhenOpenPosition(
            rebalanceTimestamp,
            derivativeNotional,
            derivativeFixedInterestRate,
            derivativeIbtQuantity
        );
    }

    function simulateOpenRecFixPositionCase1D18(uint256 deltaTimeInSeconds)
        internal
    {
        uint256 rebalanceTimestamp = tsiStorage.rf.rebalanceTimestamp +
            deltaTimeInSeconds;
        uint256 derivativeNotional = 10000 * Constants.D18;
        uint256 derivativeFixedInterestRate = 5 * 1e16;
        uint256 derivativeIbtQuantity = 95 * Constants.D18;
        tsiStorage.rf.rebalanceWhenOpenPosition(
            rebalanceTimestamp,
            derivativeNotional,
            derivativeFixedInterestRate,
            derivativeIbtQuantity
        );
    }

    function simulateOpenRecFixPositionCase2D18(uint256 deltaTimeInSeconds)
        internal
    {
        uint256 rebalanceTimestamp = tsiStorage.rf.rebalanceTimestamp +
            deltaTimeInSeconds;
        uint256 derivativeNotional = 98703 * Constants.D18;
        uint256 derivativeFixedInterestRate = 3 * 1e16;
        uint256 derivativeIbtQuantity = 98703 * 1e16;
        tsiStorage.rf.rebalanceWhenOpenPosition(
            rebalanceTimestamp,
            derivativeNotional,
            derivativeFixedInterestRate,
            derivativeIbtQuantity
        );
    }
}
