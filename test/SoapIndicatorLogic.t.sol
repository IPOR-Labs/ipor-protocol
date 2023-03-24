// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./TestCommons.sol";
import "./utils/TestConstants.sol";
import {DataUtils} from "./utils/DataUtils.sol";
import "../contracts/amm/libraries/types/AmmMiltonStorageTypes.sol";
import "../contracts/mocks/MockSoapIndicatorLogic.sol";

contract SoapIndicatorLogicTest is TestCommons, DataUtils {
    MockSoapIndicatorLogic internal _mockSoapIndicatorLogic;

    struct ExpectedBalances {
        uint256 expectedRebalanceTimestamp;
        uint256 expectedTotalNotional;
        uint256 expectedTotalIbtQuantity;
        uint256 expectedAverageInterestRate;
        uint256 expectedQuasiHypotheticalInterestCumulative;
    }

    struct RebalanceBalances {
        uint256 rebalanceTimestamp;
        uint256 totalNotional;
        uint256 totalIbtQuantity;
        uint256 averageInterestRate;
    }

    function setUp() public {
        _mockSoapIndicatorLogic = new MockSoapIndicatorLogic();
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
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory soapIndicators;
        soapIndicators.quasiHypotheticalInterestCumulative =
            500 * TestConstants.D18 * TestConstants.D18 * TestConstants.D18 * TestConstants.YEAR_IN_SECONDS;
        soapIndicators.totalNotional = 20000 * TestConstants.D18_128UINT;
        soapIndicators.totalIbtQuantity = 100 * TestConstants.D18_128UINT;
        soapIndicators.averageInterestRate = 8 * TestConstants.D16_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        // when
        uint256 actualInterestRate = _mockSoapIndicatorLogic.calculateAverageInterestRateWhenOpenSwap(
            soapIndicators.totalNotional, soapIndicators.averageInterestRate, derivativeNotional, swapFixedInterestRate
        );
        // then
        assertEq(actualInterestRate, expectedInterestRate);
    }

    function testShouldCalculateInterestRateWhenClosePositionSimpleCase1And18Decimals() public {
        // given
        uint256 derivativeNotional = TestConstants.USD_10_000_18DEC;
        uint256 swapFixedInterestRate = TestConstants.PERCENTAGE_4_18DEC;
        uint256 expectedInterestRate = 12 * TestConstants.D16;
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory soapIndicators;
        soapIndicators.quasiHypotheticalInterestCumulative =
            500 * TestConstants.D18 * TestConstants.D18 * TestConstants.D18 * TestConstants.YEAR_IN_SECONDS;
        soapIndicators.totalNotional = 20000 * TestConstants.D18_128UINT;
        soapIndicators.totalIbtQuantity = 100 * TestConstants.D18_128UINT;
        soapIndicators.averageInterestRate = 8 * TestConstants.D16_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        // when
        uint256 actualInterestRate = _mockSoapIndicatorLogic.calculateAverageInterestRateWhenCloseSwap(
            soapIndicators.totalNotional, soapIndicators.averageInterestRate, derivativeNotional, swapFixedInterestRate
        );
        // then
        assertEq(actualInterestRate, expectedInterestRate);
    }

    function testShouldCalculateInterestRateWhenClosePositionNotionalTooHighAnd18Decimals() public {
        // given
        uint256 derivativeNotional = 40000 * TestConstants.D18;
        uint256 swapFixedInterestRate = TestConstants.PERCENTAGE_4_18DEC;
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory soapIndicators;
        soapIndicators.quasiHypotheticalInterestCumulative =
            500 * TestConstants.D18 * TestConstants.D18 * TestConstants.D18 * TestConstants.YEAR_IN_SECONDS;
        soapIndicators.totalNotional = 20000 * TestConstants.D18_128UINT;
        soapIndicators.totalIbtQuantity = 100 * TestConstants.D18_128UINT;
        soapIndicators.averageInterestRate = 8 * TestConstants.D16_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        // when
        vm.expectRevert("IPOR_314");
        _mockSoapIndicatorLogic.calculateAverageInterestRateWhenCloseSwap(
            soapIndicators.totalNotional, soapIndicators.averageInterestRate, derivativeNotional, swapFixedInterestRate
        );
    }

    function testShouldCalculateInterestDeltaWhenSimpleCase1And18Decimals() public {
        // given
        uint256 expectedQuasiInterestDelta = 3456000000 * TestConstants.D18 * TestConstants.D18 * TestConstants.D18;
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory soapIndicators;
        soapIndicators.quasiHypotheticalInterestCumulative =
            500 * TestConstants.D18 * TestConstants.D18 * TestConstants.D18 * TestConstants.YEAR_IN_SECONDS;
        soapIndicators.totalNotional = 20000 * TestConstants.D18_128UINT;
        soapIndicators.totalIbtQuantity = 100 * TestConstants.D18_128UINT;
        soapIndicators.averageInterestRate = 8 * TestConstants.D16_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        uint256 timestamp = soapIndicators.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        uint256 actualQuasiInterest = _mockSoapIndicatorLogic.calculateQuasiHypotheticalInterestDelta(
            timestamp,
            soapIndicators.rebalanceTimestamp,
            soapIndicators.totalNotional,
            soapIndicators.averageInterestRate
        );
        // then
        assertEq(actualQuasiInterest, expectedQuasiInterestDelta);
    }

    function testShouldRevertWhenCalculateTimestampIsGreaterThanOrEqualToLastRebalanceTimestamp() public {
        // when
        vm.expectRevert("IPOR_317");
        _mockSoapIndicatorLogic.calculateQuasiHypotheticalInterestDelta(
            TestConstants.ZERO, 1, TestConstants.ZERO, TestConstants.ZERO
        );
    }

    function testShouldRevertWhenCalculateTimestampIsGreaterThanOrEqualToDerivativeOpenTimestamp() public {
        // when
        vm.expectRevert("IPOR_318");
        _mockSoapIndicatorLogic.calculateQuasiInterestPaidOut(
            TestConstants.ZERO, 1, TestConstants.ZERO, TestConstants.ZERO
        );
    }

    function testShouldCalculateHypotheticalInterestDeltaWhenSimpleCase1And18Decimals() public {
        // given
        uint256 expectedQuasiHypotheticalInterestTotal =
            19224000000 * TestConstants.D18 * TestConstants.D18 * TestConstants.D18;
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory soapIndicators;
        soapIndicators.quasiHypotheticalInterestCumulative =
            500 * TestConstants.D18 * TestConstants.D18 * TestConstants.D18 * TestConstants.YEAR_IN_SECONDS;
        soapIndicators.totalNotional = 20000 * TestConstants.D18_128UINT;
        soapIndicators.totalIbtQuantity = 100 * TestConstants.D18_128UINT;
        soapIndicators.averageInterestRate = 8 * TestConstants.D16_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        uint256 timestamp = soapIndicators.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        uint256 actualQuasiHypotheticalInterestTotal =
            _mockSoapIndicatorLogic.calculateQuasiHyphoteticalInterestTotal(soapIndicators, timestamp);
        // then
        assertEq(actualQuasiHypotheticalInterestTotal, expectedQuasiHypotheticalInterestTotal);
    }

    function testShouldRebalanceSOAPIndicatorsWhenOpenPositionAndOneRebalanceAnd18Decimals() public {
        // given
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory soapIndicators;
        soapIndicators.quasiHypotheticalInterestCumulative = TestConstants.ZERO;
        soapIndicators.totalNotional = TestConstants.ZERO_128UINT;
        soapIndicators.totalIbtQuantity = TestConstants.ZERO_128UINT;
        soapIndicators.averageInterestRate = TestConstants.ZERO_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        RebalanceBalances memory rebalanceBalances;
        rebalanceBalances.rebalanceTimestamp =
            soapIndicators.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalances.totalNotional = 10000 * TestConstants.D18;
        rebalanceBalances.averageInterestRate = TestConstants.PERCENTAGE_5_18DEC;
        rebalanceBalances.totalIbtQuantity = 95 * TestConstants.D18;
        // when
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory actualSoapIndicators = _mockSoapIndicatorLogic
            .rebalanceWhenOpenSwap(
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
        assertEq(actualSoapIndicators.quasiHypotheticalInterestCumulative, TestConstants.ZERO);
    }

    function testShouldRebalanceSOAPIndicatorsWhenOpenPositionAndTwoRebalancesAnd18Decimals() public {
        // given
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory soapIndicators;
        soapIndicators.quasiHypotheticalInterestCumulative = TestConstants.ZERO;
        soapIndicators.totalNotional = TestConstants.ZERO_128UINT;
        soapIndicators.totalIbtQuantity = TestConstants.ZERO_128UINT;
        soapIndicators.averageInterestRate = TestConstants.ZERO_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        RebalanceBalances memory rebalanceBalancesFirst;
        rebalanceBalancesFirst.rebalanceTimestamp =
            soapIndicators.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalancesFirst.totalNotional = 10000 * TestConstants.D18;
        rebalanceBalancesFirst.averageInterestRate = TestConstants.PERCENTAGE_5_18DEC;
        rebalanceBalancesFirst.totalIbtQuantity = 95 * TestConstants.D18;
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory actualSoapIndicatorsFirst = _mockSoapIndicatorLogic
            .rebalanceWhenOpenSwap(
            soapIndicators,
            rebalanceBalancesFirst.rebalanceTimestamp,
            rebalanceBalancesFirst.totalNotional,
            rebalanceBalancesFirst.averageInterestRate,
            rebalanceBalancesFirst.totalIbtQuantity
        );
        RebalanceBalances memory rebalanceBalancesSecond;
        rebalanceBalancesSecond.rebalanceTimestamp =
            actualSoapIndicatorsFirst.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalancesSecond.totalNotional = 20000 * TestConstants.D18;
        rebalanceBalancesSecond.averageInterestRate = TestConstants.PERCENTAGE_8_18DEC;
        rebalanceBalancesSecond.totalIbtQuantity = 173 * TestConstants.D18;
        ExpectedBalances memory expectedBalances;
        expectedBalances.expectedRebalanceTimestamp = rebalanceBalancesSecond.rebalanceTimestamp;
        expectedBalances.expectedTotalNotional =
            rebalanceBalancesFirst.totalNotional + rebalanceBalancesSecond.totalNotional;
        expectedBalances.expectedTotalIbtQuantity =
            rebalanceBalancesFirst.totalIbtQuantity + rebalanceBalancesSecond.totalIbtQuantity;
        expectedBalances.expectedAverageInterestRate = TestConstants.PERCENTAGE_7_18DEC;
        expectedBalances.expectedQuasiHypotheticalInterestCumulative =
            1080000000 * TestConstants.D18 * TestConstants.D18 * TestConstants.D18;
        // when
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory actualSoapIndicatorsSecond = _mockSoapIndicatorLogic
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
            actualSoapIndicatorsSecond.quasiHypotheticalInterestCumulative,
            expectedBalances.expectedQuasiHypotheticalInterestCumulative
        );
    }

    function testShouldRebalanceSOAPIndicatorsWhenClosePositionAndOneRebalanceAnd18Decimals() public {
        // given
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory soapIndicators;
        soapIndicators.quasiHypotheticalInterestCumulative = TestConstants.ZERO;
        soapIndicators.totalNotional = TestConstants.ZERO_128UINT;
        soapIndicators.totalIbtQuantity = TestConstants.ZERO_128UINT;
        soapIndicators.averageInterestRate = TestConstants.ZERO_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        RebalanceBalances memory rebalanceBalances;
        rebalanceBalances.rebalanceTimestamp =
            soapIndicators.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalances.totalNotional = 10000 * TestConstants.D18;
        rebalanceBalances.averageInterestRate = TestConstants.PERCENTAGE_5_18DEC;
        rebalanceBalances.totalIbtQuantity = 95 * TestConstants.D18;
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory soapIndicatorsAfterOpen = _mockSoapIndicatorLogic
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
        expectedBalances.expectedQuasiHypotheticalInterestCumulative = TestConstants.ZERO;
        // when
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory soapIndicatorsAfterClose = _mockSoapIndicatorLogic
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
            soapIndicatorsAfterClose.quasiHypotheticalInterestCumulative,
            expectedBalances.expectedQuasiHypotheticalInterestCumulative
        );
    }

    function testShouldRebalanceSOAPIndicatorsWhenOpenTwoPositionsAndCloseOnePositionAnd18Decimals() public {
        // given
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory soapIndicators;
        soapIndicators.quasiHypotheticalInterestCumulative = TestConstants.ZERO;
        soapIndicators.totalNotional = TestConstants.ZERO_128UINT;
        soapIndicators.totalIbtQuantity = TestConstants.ZERO_128UINT;
        soapIndicators.averageInterestRate = TestConstants.ZERO_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        RebalanceBalances memory rebalanceBalancesFirst;
        rebalanceBalancesFirst.rebalanceTimestamp =
            soapIndicators.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalancesFirst.totalNotional = 10000 * TestConstants.D18;
        rebalanceBalancesFirst.averageInterestRate = TestConstants.PERCENTAGE_5_18DEC;
        rebalanceBalancesFirst.totalIbtQuantity = 95 * TestConstants.D18;
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory actualSoapIndicatorsAfterOpenFirst = _mockSoapIndicatorLogic
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
            actualSoapIndicatorsAfterOpenFirst.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalancesSecond.totalNotional = 20000 * TestConstants.D18;
        rebalanceBalancesSecond.averageInterestRate = TestConstants.PERCENTAGE_8_18DEC;
        rebalanceBalancesSecond.totalIbtQuantity = 173 * TestConstants.D18;
        uint256 closeTimestamp = rebalanceBalancesSecond.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        ExpectedBalances memory expectedBalances;
        expectedBalances.expectedRebalanceTimestamp = closeTimestamp;
        expectedBalances.expectedTotalNotional = 10000 * TestConstants.D18;
        expectedBalances.expectedTotalIbtQuantity = 95 * TestConstants.D18;
        expectedBalances.expectedAverageInterestRate = averageInterestRateAfterFirstOpen;
        expectedBalances.expectedQuasiHypotheticalInterestCumulative =
            2160000000 * TestConstants.D18 * TestConstants.D18 * TestConstants.D18;
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory soapIndicatorsAfterOpenSecond = _mockSoapIndicatorLogic
            .rebalanceWhenOpenSwap(
            actualSoapIndicatorsAfterOpenFirst,
            rebalanceBalancesSecond.rebalanceTimestamp,
            rebalanceBalancesSecond.totalNotional,
            rebalanceBalancesSecond.averageInterestRate,
            rebalanceBalancesSecond.totalIbtQuantity
        );
        // when
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory soapIndicatorsAfterClose = _mockSoapIndicatorLogic
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
            soapIndicatorsAfterClose.quasiHypotheticalInterestCumulative,
            expectedBalances.expectedQuasiHypotheticalInterestCumulative
        );
    }

    function testShouldRebalanceSOAPIndicatorsWhenOpenTwoPositionsWithFixedRateEqualToZeroAndCloseOnePositionAnd18Decimals(
    ) public {
        /// @dev In this test we simulate situation when every opened swap has fixed rate = 0, so that average interest rate is equal zero.
        //given
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory soapIndicators;
        soapIndicators.quasiHypotheticalInterestCumulative = TestConstants.ZERO;
        soapIndicators.totalNotional = TestConstants.ZERO_128UINT;
        soapIndicators.totalIbtQuantity = TestConstants.ZERO_128UINT;
        soapIndicators.averageInterestRate = TestConstants.ZERO_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        RebalanceBalances memory rebalanceBalancesFirst;
        rebalanceBalancesFirst.rebalanceTimestamp =
            soapIndicators.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalancesFirst.totalNotional = 10000 * TestConstants.D18;
        rebalanceBalancesFirst.averageInterestRate = TestConstants.ZERO_64UINT;
        rebalanceBalancesFirst.totalIbtQuantity = 95 * TestConstants.D18;
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory actualSoapIndicatorsAfterOpenFirst = _mockSoapIndicatorLogic
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
            actualSoapIndicatorsAfterOpenFirst.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalancesSecond.totalNotional = 20000 * TestConstants.D18;
        rebalanceBalancesSecond.averageInterestRate = TestConstants.ZERO_64UINT;
        rebalanceBalancesSecond.totalIbtQuantity = 173 * TestConstants.D18;
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory actualSoapIndicatorsAfterOpenSecond = _mockSoapIndicatorLogic
            .rebalanceWhenOpenSwap(
            actualSoapIndicatorsAfterOpenFirst,
            rebalanceBalancesSecond.rebalanceTimestamp,
            rebalanceBalancesSecond.totalNotional,
            rebalanceBalancesSecond.averageInterestRate,
            rebalanceBalancesSecond.totalIbtQuantity
        );
        uint256 closeTimestamp =
            actualSoapIndicatorsAfterOpenSecond.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        ExpectedBalances memory expectedBalances;
        expectedBalances.expectedRebalanceTimestamp = closeTimestamp;
        expectedBalances.expectedTotalNotional = 10000 * TestConstants.D18;
        expectedBalances.expectedTotalIbtQuantity = 95 * TestConstants.D18;
        expectedBalances.expectedAverageInterestRate = averageInterestRateAfterFirstOpen;
        expectedBalances.expectedQuasiHypotheticalInterestCumulative = TestConstants.ZERO;
        // when
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory soapIndicatorsAfterClose = _mockSoapIndicatorLogic
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
            soapIndicatorsAfterClose.quasiHypotheticalInterestCumulative,
            expectedBalances.expectedQuasiHypotheticalInterestCumulative
        );
    }

    function testShouldRebalanceSOAPIndicatorsWhenOpenTwoPositionsAndCloseTwoPositionsAnd18Decimals() public {
        // given
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory soapIndicators;
        soapIndicators.quasiHypotheticalInterestCumulative = TestConstants.ZERO;
        soapIndicators.totalNotional = TestConstants.ZERO_128UINT;
        soapIndicators.totalIbtQuantity = TestConstants.ZERO_128UINT;
        soapIndicators.averageInterestRate = TestConstants.ZERO_64UINT;
        soapIndicators.rebalanceTimestamp = uint32(block.timestamp);
        RebalanceBalances memory rebalanceBalancesFirst;
        rebalanceBalancesFirst.rebalanceTimestamp =
            soapIndicators.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalancesFirst.totalNotional = 10000 * TestConstants.D18;
        rebalanceBalancesFirst.averageInterestRate = TestConstants.PERCENTAGE_5_18DEC;
        rebalanceBalancesFirst.totalIbtQuantity = 95 * TestConstants.D18;
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory actualSoapIndicatorsAfterOpenFirst = _mockSoapIndicatorLogic
            .rebalanceWhenOpenSwap(
            soapIndicators,
            rebalanceBalancesFirst.rebalanceTimestamp,
            rebalanceBalancesFirst.totalNotional,
            rebalanceBalancesFirst.averageInterestRate,
            rebalanceBalancesFirst.totalIbtQuantity
        );
        RebalanceBalances memory rebalanceBalancesSecond;
        rebalanceBalancesSecond.rebalanceTimestamp =
            actualSoapIndicatorsAfterOpenFirst.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        rebalanceBalancesSecond.totalNotional = 20000 * TestConstants.D18;
        rebalanceBalancesSecond.averageInterestRate = TestConstants.PERCENTAGE_8_18DEC;
        rebalanceBalancesSecond.totalIbtQuantity = 173 * TestConstants.D18;
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory actualSoapIndicatorsAfterOpenSecond = _mockSoapIndicatorLogic
            .rebalanceWhenOpenSwap(
            actualSoapIndicatorsAfterOpenFirst,
            rebalanceBalancesSecond.rebalanceTimestamp,
            rebalanceBalancesSecond.totalNotional,
            rebalanceBalancesSecond.averageInterestRate,
            rebalanceBalancesSecond.totalIbtQuantity
        );
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory soapIndicatorsAfterCloseSecond = _mockSoapIndicatorLogic
            .rebalanceWhenCloseSwap(
            actualSoapIndicatorsAfterOpenSecond,
            actualSoapIndicatorsAfterOpenSecond.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            rebalanceBalancesSecond.rebalanceTimestamp,
            rebalanceBalancesSecond.totalNotional,
            rebalanceBalancesSecond.averageInterestRate,
            rebalanceBalancesSecond.totalIbtQuantity
        );
        uint256 closeTimestampFirstPositon =
            soapIndicatorsAfterCloseSecond.rebalanceTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        ExpectedBalances memory expectedBalances;
        expectedBalances.expectedRebalanceTimestamp = closeTimestampFirstPositon;
        expectedBalances.expectedTotalNotional = TestConstants.ZERO;
        expectedBalances.expectedTotalIbtQuantity = TestConstants.ZERO;
        expectedBalances.expectedAverageInterestRate = TestConstants.ZERO;
        expectedBalances.expectedQuasiHypotheticalInterestCumulative = TestConstants.ZERO;
        // when
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory soapIndicatorsAfterCloseFirst = _mockSoapIndicatorLogic
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
            soapIndicatorsAfterCloseFirst.quasiHypotheticalInterestCumulative,
            expectedBalances.expectedQuasiHypotheticalInterestCumulative
        );
    }
}
