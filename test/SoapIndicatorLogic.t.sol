// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "./TestCommons.sol";
import "./utils/TestConstants.sol";
import "../contracts/amm/libraries/SoapIndicatorLogic.sol";
import "../contracts/amm/libraries/SoapIndicatorRebalanceLogic.sol";

contract SoapIndicatorLogicTest is TestCommons {
    struct ExpectedBalances {
        uint256 expectedRebalanceTimestamp;
        uint256 expectedTotalNotional;
        uint256 expectedTotalIbtQuantity;
        uint256 expectedAverageInterestRate;
        uint256 expectedHypotheticalInterestCumulative;
    }

    struct RebalanceBalances {
        uint256 rebalanceTimestamp;
        uint256 totalNotional;
        uint256 totalIbtQuantity;
        uint256 averageInterestRate;
    }

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
    }

    function testShouldCalculateInterestRateWhenOpenPositionSimpleCase1And18Decimals() public {
        // given
        uint256 derivativeNotional = TestConstants.USD_10_000_18DEC;
        uint256 swapFixedInterestRate = TestConstants.PERCENTAGE_4_18DEC;
        uint256 expectedInterestRate = 66666666666666667;
        AmmStorageTypes.SoapIndicators memory soapIndicators;
        soapIndicators.hypotheticalInterestCumulative = 500 * TestConstants.D18;
        soapIndicators.totalNotional = 20000 * TestConstants.D18_128UINT;
        soapIndicators.totalIbtQuantity = 100 * TestConstants.D18_128UINT;
        soapIndicators.averageInterestRate = 8 * TestConstants.D16_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        // when
        uint256 actualInterestRate = SoapIndicatorRebalanceLogic.calculateAverageInterestRateWhenOpenSwap(
            soapIndicators.totalNotional,
            soapIndicators.averageInterestRate,
            derivativeNotional,
            swapFixedInterestRate
        );
        // then
        assertEq(actualInterestRate, expectedInterestRate);
    }

    function testShouldCalculateInterestRateWhenClosePositionSimpleCase1And18Decimals() public {
        // given
        uint256 derivativeNotional = TestConstants.USD_10_000_18DEC;
        uint256 swapFixedInterestRate = TestConstants.PERCENTAGE_4_18DEC;
        uint256 expectedInterestRate = 12 * TestConstants.D16;
        AmmStorageTypes.SoapIndicators memory soapIndicators;
        soapIndicators.hypotheticalInterestCumulative = 500 * TestConstants.D18;
        soapIndicators.totalNotional = 20000 * TestConstants.D18_128UINT;
        soapIndicators.totalIbtQuantity = 100 * TestConstants.D18_128UINT;
        soapIndicators.averageInterestRate = 8 * TestConstants.D16_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        // when
        uint256 actualInterestRate = SoapIndicatorRebalanceLogic.calculateAverageInterestRateWhenCloseSwap(
            soapIndicators.totalNotional,
            soapIndicators.averageInterestRate,
            derivativeNotional,
            swapFixedInterestRate
        );
        // then
        assertEq(actualInterestRate, expectedInterestRate);
    }

    function testShouldNotCalculateInterestRateWhenClosePositionNotionalTooHighAnd18Decimals() public {
        // given
        uint256 derivativeNotional = 40000 * TestConstants.D18;
        uint256 swapFixedInterestRate = TestConstants.PERCENTAGE_4_18DEC;
        AmmStorageTypes.SoapIndicators memory soapIndicators;
        soapIndicators.hypotheticalInterestCumulative = 500 * TestConstants.D18;
        soapIndicators.totalNotional = 20000 * TestConstants.D18_128UINT;
        soapIndicators.totalIbtQuantity = 100 * TestConstants.D18_128UINT;
        soapIndicators.averageInterestRate = 8 * TestConstants.D16_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        // when
        vm.expectRevert("IPOR_314");
        SoapIndicatorRebalanceLogic.calculateAverageInterestRateWhenCloseSwap(
            soapIndicators.totalNotional,
            soapIndicators.averageInterestRate,
            derivativeNotional,
            swapFixedInterestRate
        );
    }

    function testShouldNotCalculateInterestRateWhenClosePositionTotalNotionalTooLow() public {
        // given
        uint256 derivativeNotional = 40000 * TestConstants.D18;
        uint256 swapFixedInterestRate = TestConstants.PERCENTAGE_4_18DEC;
        uint256 averageInterestRate = 2029718087;

        // when
        vm.expectRevert("IPOR_314");
        SoapIndicatorRebalanceLogic.calculateAverageInterestRateWhenCloseSwap(
            derivativeNotional - 1,
            2029718087,
            derivativeNotional,
            swapFixedInterestRate
        );
    }

    function testShouldCalculateInterestRateEvenWhenClosePositionTotalNotionalAndAverageInterestRateTooLow() public {
        // given
        uint256 derivativeNotional = 40000 * TestConstants.D18;
        uint256 swapFixedInterestRate = TestConstants.PERCENTAGE_4_18DEC;

        // when
        uint256 newAverageInterestRate = SoapIndicatorRebalanceLogic.calculateAverageInterestRateWhenCloseSwap(
            61257906215921483127120,
            2029718087,
            61257906215921483127120,
            swapFixedInterestRate
        );

        //then
        assertEq(newAverageInterestRate, 0);
    }

    function testShouldCalculateInterestDeltaWhenSimpleCase1And18Decimals() public {
        // given
        uint256 expectedInterestDelta = 109889834186915586030;
        AmmStorageTypes.SoapIndicators memory soapIndicators;
        soapIndicators.totalNotional = 20000 * TestConstants.D18_128UINT;
        soapIndicators.totalIbtQuantity = 100 * TestConstants.D18_128UINT;
        soapIndicators.averageInterestRate = 8 * TestConstants.D16_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        uint256 timestamp = soapIndicators.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        // when
        uint256 actualInterest = SoapIndicatorLogic.calculateHypotheticalInterestDelta(
            timestamp,
            soapIndicators.rebalanceTimestamp,
            soapIndicators.totalNotional,
            soapIndicators.averageInterestRate
        );
        // then
        assertEq(actualInterest, expectedInterestDelta);
    }

    function testShouldRevertWhenCalculateTimestampIsGreaterThanOrEqualToLastRebalanceTimestamp() public {
        // when
        vm.expectRevert("IPOR_317");
        SoapIndicatorLogic.calculateHypotheticalInterestDelta(
            TestConstants.ZERO,
            1,
            TestConstants.ZERO,
            TestConstants.ZERO
        );
    }

    function testShouldRevertWhenCalculateTimestampIsGreaterThanOrEqualToDerivativeOpenTimestamp() public {
        // when
        vm.expectRevert("IPOR_318");
        SoapIndicatorRebalanceLogic.calculateInterestPaidOut(
            TestConstants.ZERO,
            1,
            TestConstants.ZERO,
            TestConstants.ZERO
        );
    }

    function testShouldCalculateHypotheticalInterestDeltaWhenSimpleCase1And18Decimals() public {
        // given
        uint256 expectedHypotheticalInterestTotal = 612637080041588475681;
        AmmStorageTypes.SoapIndicators memory soapIndicators;
        soapIndicators.hypotheticalInterestCumulative = 500 * TestConstants.D18;
        soapIndicators.totalNotional = 20000 * TestConstants.D18_128UINT;
        soapIndicators.totalIbtQuantity = 100 * TestConstants.D18_128UINT;
        soapIndicators.averageInterestRate = 8 * TestConstants.D16_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        uint256 timestamp = soapIndicators.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        // when
        uint256 actualHypotheticalInterestTotal = SoapIndicatorLogic.calculateHyphoteticalInterestTotal(
            soapIndicators,
            timestamp
        );

        // then
        assertEq(actualHypotheticalInterestTotal, expectedHypotheticalInterestTotal);
    }

    function testShouldRebalanceSOAPIndicatorsWhenOpenPositionAndOneRebalanceAnd18Decimals() public {
        // given
        AmmStorageTypes.SoapIndicators memory soapIndicators;
        soapIndicators.hypotheticalInterestCumulative = TestConstants.ZERO;
        soapIndicators.totalNotional = TestConstants.ZERO_128UINT;
        soapIndicators.totalIbtQuantity = TestConstants.ZERO_128UINT;
        soapIndicators.averageInterestRate = TestConstants.ZERO_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        RebalanceBalances memory rebalanceBalances;
        rebalanceBalances.rebalanceTimestamp =
            soapIndicators.rebalanceTimestamp +
            TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalances.totalNotional = 10000 * TestConstants.D18;
        rebalanceBalances.averageInterestRate = TestConstants.PERCENTAGE_5_18DEC;
        rebalanceBalances.totalIbtQuantity = 95 * TestConstants.D18;

        // when
        AmmStorageTypes.SoapIndicators memory actualSoapIndicators = SoapIndicatorRebalanceLogic.rebalanceWhenOpenSwap(
            soapIndicators,
            rebalanceBalances.rebalanceTimestamp,
            rebalanceBalances.totalNotional,
            rebalanceBalances.averageInterestRate,
            rebalanceBalances.totalIbtQuantity
        );

        // then
        assertEq(actualSoapIndicators.rebalanceTimestamp, rebalanceBalances.rebalanceTimestamp);
        assertEq(actualSoapIndicators.totalNotional, rebalanceBalances.totalNotional);
        assertEq(actualSoapIndicators.totalIbtQuantity, rebalanceBalances.totalIbtQuantity);
        assertEq(actualSoapIndicators.averageInterestRate, rebalanceBalances.averageInterestRate);
        assertEq(actualSoapIndicators.hypotheticalInterestCumulative, TestConstants.ZERO);
    }

    function testShouldRebalanceSOAPIndicatorsWhenOpenPositionAndTwoRebalancesAnd18Decimals() public {
        // given
        AmmStorageTypes.SoapIndicators memory soapIndicators;
        soapIndicators.hypotheticalInterestCumulative = TestConstants.ZERO;
        soapIndicators.totalNotional = TestConstants.ZERO_128UINT;
        soapIndicators.totalIbtQuantity = TestConstants.ZERO_128UINT;
        soapIndicators.averageInterestRate = TestConstants.ZERO_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        RebalanceBalances memory rebalanceBalancesFirst;
        rebalanceBalancesFirst.rebalanceTimestamp =
            soapIndicators.rebalanceTimestamp +
            TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalancesFirst.totalNotional = 10000 * TestConstants.D18;
        rebalanceBalancesFirst.averageInterestRate = TestConstants.PERCENTAGE_5_18DEC;
        rebalanceBalancesFirst.totalIbtQuantity = 95 * TestConstants.D18;
        AmmStorageTypes.SoapIndicators memory actualSoapIndicatorsFirst = SoapIndicatorRebalanceLogic
            .rebalanceWhenOpenSwap(
                soapIndicators,
                rebalanceBalancesFirst.rebalanceTimestamp,
                rebalanceBalancesFirst.totalNotional,
                rebalanceBalancesFirst.averageInterestRate,
                rebalanceBalancesFirst.totalIbtQuantity
            );
        RebalanceBalances memory rebalanceBalancesSecond;
        rebalanceBalancesSecond.rebalanceTimestamp =
            actualSoapIndicatorsFirst.rebalanceTimestamp +
            TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalancesSecond.totalNotional = 20000 * TestConstants.D18;
        rebalanceBalancesSecond.averageInterestRate = TestConstants.PERCENTAGE_8_18DEC;
        rebalanceBalancesSecond.totalIbtQuantity = 173 * TestConstants.D18;
        ExpectedBalances memory expectedBalances;
        expectedBalances.expectedRebalanceTimestamp = rebalanceBalancesSecond.rebalanceTimestamp;
        expectedBalances.expectedTotalNotional =
            rebalanceBalancesFirst.totalNotional +
            rebalanceBalancesSecond.totalNotional;
        expectedBalances.expectedTotalIbtQuantity =
            rebalanceBalancesFirst.totalIbtQuantity +
            rebalanceBalancesSecond.totalIbtQuantity;
        expectedBalances.expectedAverageInterestRate = TestConstants.PERCENTAGE_7_18DEC;
        expectedBalances.expectedHypotheticalInterestCumulative = 34305283738185983233;
        // when
        AmmStorageTypes.SoapIndicators memory actualSoapIndicatorsSecond = SoapIndicatorRebalanceLogic
            .rebalanceWhenOpenSwap(
                actualSoapIndicatorsFirst,
                rebalanceBalancesSecond.rebalanceTimestamp,
                rebalanceBalancesSecond.totalNotional,
                rebalanceBalancesSecond.averageInterestRate,
                rebalanceBalancesSecond.totalIbtQuantity
            );
        // then
        assertEq(actualSoapIndicatorsSecond.rebalanceTimestamp, expectedBalances.expectedRebalanceTimestamp);
        assertEq(actualSoapIndicatorsSecond.totalNotional, expectedBalances.expectedTotalNotional);
        assertEq(actualSoapIndicatorsSecond.totalIbtQuantity, expectedBalances.expectedTotalIbtQuantity);
        assertEq(actualSoapIndicatorsSecond.averageInterestRate, expectedBalances.expectedAverageInterestRate);
        assertEq(
            actualSoapIndicatorsSecond.hypotheticalInterestCumulative,
            expectedBalances.expectedHypotheticalInterestCumulative
        );
    }

    function testShouldRebalanceSOAPIndicatorsWhenClosePositionAndOneRebalanceAnd18Decimals() public {
        // given
        AmmStorageTypes.SoapIndicators memory soapIndicators;
        soapIndicators.hypotheticalInterestCumulative = TestConstants.ZERO;
        soapIndicators.totalNotional = TestConstants.ZERO_128UINT;
        soapIndicators.totalIbtQuantity = TestConstants.ZERO_128UINT;
        soapIndicators.averageInterestRate = TestConstants.ZERO_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        RebalanceBalances memory rebalanceBalances;
        rebalanceBalances.rebalanceTimestamp =
            soapIndicators.rebalanceTimestamp +
            TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalances.totalNotional = 10000 * TestConstants.D18;
        rebalanceBalances.averageInterestRate = TestConstants.PERCENTAGE_5_18DEC;
        rebalanceBalances.totalIbtQuantity = 95 * TestConstants.D18;
        AmmStorageTypes.SoapIndicators memory soapIndicatorsAfterOpen = SoapIndicatorRebalanceLogic
            .rebalanceWhenOpenSwap(
                soapIndicators,
                rebalanceBalances.rebalanceTimestamp,
                rebalanceBalances.totalNotional,
                rebalanceBalances.averageInterestRate,
                rebalanceBalances.totalIbtQuantity
            );
        uint256 closeTimestamp = soapIndicatorsAfterOpen.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        ExpectedBalances memory expectedBalances;
        expectedBalances.expectedRebalanceTimestamp = closeTimestamp;
        expectedBalances.expectedTotalNotional = TestConstants.ZERO_128UINT;
        expectedBalances.expectedTotalIbtQuantity = TestConstants.ZERO_128UINT;
        expectedBalances.expectedAverageInterestRate = TestConstants.ZERO_64UINT;
        expectedBalances.expectedHypotheticalInterestCumulative = TestConstants.ZERO;
        // when
        AmmStorageTypes.SoapIndicators memory soapIndicatorsAfterClose = SoapIndicatorRebalanceLogic
            .rebalanceWhenCloseSwap(
                soapIndicatorsAfterOpen,
                closeTimestamp,
                rebalanceBalances.rebalanceTimestamp,
                rebalanceBalances.totalNotional,
                rebalanceBalances.averageInterestRate,
                rebalanceBalances.totalIbtQuantity
            );
        // then
        assertEq(soapIndicatorsAfterClose.rebalanceTimestamp, expectedBalances.expectedRebalanceTimestamp);
        assertEq(soapIndicatorsAfterClose.totalNotional, expectedBalances.expectedTotalNotional);
        assertEq(soapIndicatorsAfterClose.totalIbtQuantity, expectedBalances.expectedTotalIbtQuantity);
        assertEq(soapIndicatorsAfterClose.averageInterestRate, expectedBalances.expectedAverageInterestRate);
        assertEq(
            soapIndicatorsAfterClose.hypotheticalInterestCumulative,
            expectedBalances.expectedHypotheticalInterestCumulative
        );
    }

    function testShouldRebalanceSOAPIndicatorsWhenOpenTwoPositionsAndCloseOnePositionAnd18Decimals() public {
        // given
        AmmStorageTypes.SoapIndicators memory soapIndicators;
        soapIndicators.hypotheticalInterestCumulative = TestConstants.ZERO;
        soapIndicators.totalNotional = TestConstants.ZERO_128UINT;
        soapIndicators.totalIbtQuantity = TestConstants.ZERO_128UINT;
        soapIndicators.averageInterestRate = TestConstants.ZERO_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        RebalanceBalances memory rebalanceBalancesFirst;
        rebalanceBalancesFirst.rebalanceTimestamp =
            soapIndicators.rebalanceTimestamp +
            TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalancesFirst.totalNotional = 10000 * TestConstants.D18;
        rebalanceBalancesFirst.averageInterestRate = TestConstants.PERCENTAGE_5_18DEC;
        rebalanceBalancesFirst.totalIbtQuantity = 95 * TestConstants.D18;
        AmmStorageTypes.SoapIndicators memory actualSoapIndicatorsAfterOpenFirst = SoapIndicatorRebalanceLogic
            .rebalanceWhenOpenSwap(
                soapIndicators,
                rebalanceBalancesFirst.rebalanceTimestamp,
                rebalanceBalancesFirst.totalNotional,
                rebalanceBalancesFirst.averageInterestRate,
                rebalanceBalancesFirst.totalIbtQuantity
            );
        uint256 averageInterestRateAfterFirstOpen = actualSoapIndicatorsAfterOpenFirst.averageInterestRate;
        RebalanceBalances memory rebalanceBalancesSecond;
        rebalanceBalancesSecond.rebalanceTimestamp =
            actualSoapIndicatorsAfterOpenFirst.rebalanceTimestamp +
            TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalancesSecond.totalNotional = 20000 * TestConstants.D18;
        rebalanceBalancesSecond.averageInterestRate = TestConstants.PERCENTAGE_8_18DEC;
        rebalanceBalancesSecond.totalIbtQuantity = 173 * TestConstants.D18;
        uint256 closeTimestamp = rebalanceBalancesSecond.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        ExpectedBalances memory expectedBalances;
        expectedBalances.expectedRebalanceTimestamp = closeTimestamp;
        expectedBalances.expectedTotalNotional = 10000 * TestConstants.D18;
        expectedBalances.expectedTotalIbtQuantity = 95 * TestConstants.D18;
        expectedBalances.expectedAverageInterestRate = averageInterestRateAfterFirstOpen;
        expectedBalances.expectedHypotheticalInterestCumulative = 68761301442321639744;
        AmmStorageTypes.SoapIndicators memory soapIndicatorsAfterOpenSecond = SoapIndicatorRebalanceLogic
            .rebalanceWhenOpenSwap(
                actualSoapIndicatorsAfterOpenFirst,
                rebalanceBalancesSecond.rebalanceTimestamp,
                rebalanceBalancesSecond.totalNotional,
                rebalanceBalancesSecond.averageInterestRate,
                rebalanceBalancesSecond.totalIbtQuantity
            );
        // when
        AmmStorageTypes.SoapIndicators memory soapIndicatorsAfterClose = SoapIndicatorRebalanceLogic
            .rebalanceWhenCloseSwap(
                soapIndicatorsAfterOpenSecond,
                closeTimestamp,
                rebalanceBalancesSecond.rebalanceTimestamp,
                rebalanceBalancesSecond.totalNotional,
                rebalanceBalancesSecond.averageInterestRate,
                rebalanceBalancesSecond.totalIbtQuantity
            );
        // then
        assertEq(soapIndicatorsAfterClose.rebalanceTimestamp, expectedBalances.expectedRebalanceTimestamp);
        assertEq(soapIndicatorsAfterClose.totalNotional, expectedBalances.expectedTotalNotional);
        assertEq(soapIndicatorsAfterClose.totalIbtQuantity, expectedBalances.expectedTotalIbtQuantity);
        assertEq(soapIndicatorsAfterClose.averageInterestRate, expectedBalances.expectedAverageInterestRate);
        assertEq(
            soapIndicatorsAfterClose.hypotheticalInterestCumulative,
            expectedBalances.expectedHypotheticalInterestCumulative
        );
    }

    function testShouldRebalanceSOAPIndicatorsWhenOpenTwoPositionsWithFixedRateEqualToZeroAndCloseOnePositionAnd18Decimals()
        public
    {
        /// @dev In this test we simulate situation when every opened swap has fixed rate = 0, so that average interest rate is equal zero.
        //given
        AmmStorageTypes.SoapIndicators memory soapIndicators;
        soapIndicators.hypotheticalInterestCumulative = TestConstants.ZERO;
        soapIndicators.totalNotional = TestConstants.ZERO_128UINT;
        soapIndicators.totalIbtQuantity = TestConstants.ZERO_128UINT;
        soapIndicators.averageInterestRate = TestConstants.ZERO_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        RebalanceBalances memory rebalanceBalancesFirst;
        rebalanceBalancesFirst.rebalanceTimestamp =
            soapIndicators.rebalanceTimestamp +
            TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalancesFirst.totalNotional = 10000 * TestConstants.D18;
        rebalanceBalancesFirst.averageInterestRate = TestConstants.ZERO_64UINT;
        rebalanceBalancesFirst.totalIbtQuantity = 95 * TestConstants.D18;
        AmmStorageTypes.SoapIndicators memory actualSoapIndicatorsAfterOpenFirst = SoapIndicatorRebalanceLogic
            .rebalanceWhenOpenSwap(
                soapIndicators,
                rebalanceBalancesFirst.rebalanceTimestamp,
                rebalanceBalancesFirst.totalNotional,
                rebalanceBalancesFirst.averageInterestRate,
                rebalanceBalancesFirst.totalIbtQuantity
            );
        uint256 averageInterestRateAfterFirstOpen = actualSoapIndicatorsAfterOpenFirst.averageInterestRate;
        RebalanceBalances memory rebalanceBalancesSecond;
        rebalanceBalancesSecond.rebalanceTimestamp =
            actualSoapIndicatorsAfterOpenFirst.rebalanceTimestamp +
            TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalancesSecond.totalNotional = 20000 * TestConstants.D18;
        rebalanceBalancesSecond.averageInterestRate = TestConstants.ZERO_64UINT;
        rebalanceBalancesSecond.totalIbtQuantity = 173 * TestConstants.D18;
        AmmStorageTypes.SoapIndicators memory actualSoapIndicatorsAfterOpenSecond = SoapIndicatorRebalanceLogic
            .rebalanceWhenOpenSwap(
                actualSoapIndicatorsAfterOpenFirst,
                rebalanceBalancesSecond.rebalanceTimestamp,
                rebalanceBalancesSecond.totalNotional,
                rebalanceBalancesSecond.averageInterestRate,
                rebalanceBalancesSecond.totalIbtQuantity
            );
        uint256 closeTimestamp = actualSoapIndicatorsAfterOpenSecond.rebalanceTimestamp +
            TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        ExpectedBalances memory expectedBalances;
        expectedBalances.expectedRebalanceTimestamp = closeTimestamp;
        expectedBalances.expectedTotalNotional = 10000 * TestConstants.D18;
        expectedBalances.expectedTotalIbtQuantity = 95 * TestConstants.D18;
        expectedBalances.expectedAverageInterestRate = averageInterestRateAfterFirstOpen;
        expectedBalances.expectedHypotheticalInterestCumulative = TestConstants.ZERO;
        // when
        AmmStorageTypes.SoapIndicators memory soapIndicatorsAfterClose = SoapIndicatorRebalanceLogic
            .rebalanceWhenCloseSwap(
                actualSoapIndicatorsAfterOpenSecond,
                closeTimestamp,
                rebalanceBalancesSecond.rebalanceTimestamp,
                rebalanceBalancesSecond.totalNotional,
                rebalanceBalancesSecond.averageInterestRate,
                rebalanceBalancesSecond.totalIbtQuantity
            );
        // then
        assertEq(soapIndicatorsAfterClose.rebalanceTimestamp, expectedBalances.expectedRebalanceTimestamp);
        assertEq(soapIndicatorsAfterClose.totalNotional, expectedBalances.expectedTotalNotional);
        assertEq(soapIndicatorsAfterClose.totalIbtQuantity, expectedBalances.expectedTotalIbtQuantity);
        assertEq(soapIndicatorsAfterClose.averageInterestRate, expectedBalances.expectedAverageInterestRate);
        assertEq(
            soapIndicatorsAfterClose.hypotheticalInterestCumulative,
            expectedBalances.expectedHypotheticalInterestCumulative
        );
    }

    function testShouldRebalanceSOAPIndicatorsWhenOpenTwoPositionsAndCloseTwoPositionsAnd18Decimals() public {
        // given
        AmmStorageTypes.SoapIndicators memory soapIndicators;
        soapIndicators.hypotheticalInterestCumulative = TestConstants.ZERO;
        soapIndicators.totalNotional = TestConstants.ZERO_128UINT;
        soapIndicators.totalIbtQuantity = TestConstants.ZERO_128UINT;
        soapIndicators.averageInterestRate = TestConstants.ZERO_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        RebalanceBalances memory rebalanceBalancesFirst;
        rebalanceBalancesFirst.rebalanceTimestamp =
            soapIndicators.rebalanceTimestamp +
            TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalancesFirst.totalNotional = 10000 * TestConstants.D18;
        rebalanceBalancesFirst.averageInterestRate = TestConstants.PERCENTAGE_5_18DEC;
        rebalanceBalancesFirst.totalIbtQuantity = 95 * TestConstants.D18;
        AmmStorageTypes.SoapIndicators memory actualSoapIndicatorsAfterOpenFirst = SoapIndicatorRebalanceLogic
            .rebalanceWhenOpenSwap(
                soapIndicators,
                rebalanceBalancesFirst.rebalanceTimestamp,
                rebalanceBalancesFirst.totalNotional,
                rebalanceBalancesFirst.averageInterestRate,
                rebalanceBalancesFirst.totalIbtQuantity
            );
        RebalanceBalances memory rebalanceBalancesSecond;
        rebalanceBalancesSecond.rebalanceTimestamp =
            actualSoapIndicatorsAfterOpenFirst.rebalanceTimestamp +
            TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalancesSecond.totalNotional = 20000 * TestConstants.D18;
        rebalanceBalancesSecond.averageInterestRate = TestConstants.PERCENTAGE_8_18DEC;
        rebalanceBalancesSecond.totalIbtQuantity = 173 * TestConstants.D18;
        AmmStorageTypes.SoapIndicators memory actualSoapIndicatorsAfterOpenSecond = SoapIndicatorRebalanceLogic
            .rebalanceWhenOpenSwap(
                actualSoapIndicatorsAfterOpenFirst,
                rebalanceBalancesSecond.rebalanceTimestamp,
                rebalanceBalancesSecond.totalNotional,
                rebalanceBalancesSecond.averageInterestRate,
                rebalanceBalancesSecond.totalIbtQuantity
            );
        AmmStorageTypes.SoapIndicators memory soapIndicatorsAfterCloseSecond = SoapIndicatorRebalanceLogic
            .rebalanceWhenCloseSwap(
                actualSoapIndicatorsAfterOpenSecond,
                actualSoapIndicatorsAfterOpenSecond.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
                rebalanceBalancesSecond.rebalanceTimestamp,
                rebalanceBalancesSecond.totalNotional,
                rebalanceBalancesSecond.averageInterestRate,
                rebalanceBalancesSecond.totalIbtQuantity
            );
        uint256 closeTimestampFirstPositon = soapIndicatorsAfterCloseSecond.rebalanceTimestamp +
            TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        ExpectedBalances memory expectedBalances;
        expectedBalances.expectedRebalanceTimestamp = closeTimestampFirstPositon;
        expectedBalances.expectedTotalNotional = TestConstants.ZERO;
        expectedBalances.expectedTotalIbtQuantity = TestConstants.ZERO;
        expectedBalances.expectedAverageInterestRate = TestConstants.ZERO;
        expectedBalances.expectedHypotheticalInterestCumulative = TestConstants.ZERO;
        // when
        AmmStorageTypes.SoapIndicators memory soapIndicatorsAfterCloseFirst = SoapIndicatorRebalanceLogic
            .rebalanceWhenCloseSwap(
                soapIndicatorsAfterCloseSecond,
                closeTimestampFirstPositon,
                rebalanceBalancesFirst.rebalanceTimestamp,
                rebalanceBalancesFirst.totalNotional,
                rebalanceBalancesFirst.averageInterestRate,
                rebalanceBalancesFirst.totalIbtQuantity
            );
        // then
        assertEq(soapIndicatorsAfterCloseFirst.rebalanceTimestamp, expectedBalances.expectedRebalanceTimestamp);
        assertEq(soapIndicatorsAfterCloseFirst.totalNotional, expectedBalances.expectedTotalNotional);
        assertEq(soapIndicatorsAfterCloseFirst.totalIbtQuantity, expectedBalances.expectedTotalIbtQuantity);
        assertEq(soapIndicatorsAfterCloseFirst.averageInterestRate, expectedBalances.expectedAverageInterestRate);
        assertEq(
            soapIndicatorsAfterCloseFirst.hypotheticalInterestCumulative,
            expectedBalances.expectedHypotheticalInterestCumulative
        );
    }
}
