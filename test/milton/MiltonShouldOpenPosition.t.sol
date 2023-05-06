// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase4MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase5MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/interfaces/types/MiltonStorageTypes.sol";

contract MiltonShouldOpenPositionTest is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolBuilder.IporProtocol internal _iporProtocol;

    struct ActualBalances {
        uint256 actualIncomeFeeValue;
        uint256 actualSumOfBalances;
        uint256 actualMiltonBalance;
        int256 actualPayoff;
        int256 actualOpenerUserBalance;
        int256 actualCloserUserBalance;
    }

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);

        _cfg.approvalsForUsers = _users;
        _cfg.iporOracleUpdater = _userOne;
        _cfg.spreadImplementation = address(
            new MockSpreadModel(
                TestConstants.PERCENTAGE_4_18DEC,
                TestConstants.ZERO,
                TestConstants.ZERO_INT,
                TestConstants.ZERO_INT
            )
        );
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
    }

    function testShouldOpenPositionPayFixedDAIWhenOwnerSimpleCase18Decimals() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 miltonBalanceBeforePayoutWad = TestConstants.USD_28_000_18DEC;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(miltonBalanceBeforePayoutWad, block.timestamp);

        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedMiltonBalance =
            miltonBalanceBeforePayoutWad +
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC;
        expectedBalances.expectedOpenerUserBalance = 9990000 * TestConstants.D18_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            miltonBalanceBeforePayoutWad +
            TestConstants.TC_OPENING_FEE_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            miltonBalanceBeforePayoutWad +
            TestConstants.USD_10_000_000_18DEC;

        uint256 expectedIporPublicationFee = TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC;
        uint256 expectedDerivativesTotalBalanceWad = TestConstants.TC_COLLATERAL_18DEC;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        uint256 actualOpenSwapsVolume;
        for (uint256 i = 0; i < swaps.length; i++) {
            if (swaps[i].state == 1) {
                actualOpenSwapsVolume++;
            }
        }
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol
            .miltonStorage
            .getExtendedBalance();
        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        uint256 actualDerivativesTotalBalanceWad = balance.totalCollateralPayFixed +
            balance.totalCollateralReceiveFixed;
        // then
        assertEq(actualOpenSwapsVolume, 1);
        assertEq(
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)),
            expectedBalances.expectedMiltonBalance
        );
        assertEq(
            int256(_iporProtocol.asset.balanceOf(_userTwo)),
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(actualDerivativesTotalBalanceWad, expectedDerivativesTotalBalanceWad);
        assertEq(balance.iporPublicationFee, expectedIporPublicationFee);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, TestConstants.ZERO);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
    }

    function testShouldOpenPositionPayFixedUSDTWhenOwnerSimpleCase6Decimals() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonUsdt());
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);

        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedMiltonBalance =
            TestConstants.USD_28_000_6DEC +
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC;
        expectedBalances.expectedOpenerUserBalance = 9990000000000;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.USD_28_000_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.USD_28_000_6DEC +
            TestConstants.USD_10_000_000_6DEC;

        uint256 expectedDerivativesTotalBalanceWad = TestConstants.TC_COLLATERAL_18DEC;
        uint256 expectedIporPublicationFee = TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );

        uint256 actualOpenSwapsVolume;

        for (uint256 i = 0; i < swaps.length; i++) {
            if (swaps[i].state == 1) {
                actualOpenSwapsVolume++;
            }
        }
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol
            .miltonStorage
            .getExtendedBalance();
        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        uint256 actualDerivativesTotalBalanceWad = balance.totalCollateralPayFixed +
            balance.totalCollateralReceiveFixed;

        // then
        assertEq(actualOpenSwapsVolume, 1);
        assertEq(
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)),
            expectedBalances.expectedMiltonBalance
        );
        assertEq(
            int256(_iporProtocol.asset.balanceOf(_userTwo)),
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(actualDerivativesTotalBalanceWad, expectedDerivativesTotalBalanceWad);
        assertEq(balance.iporPublicationFee, expectedIporPublicationFee);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, TestConstants.ZERO);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
    }

    function testShouldOpenPositionPayFixedDAIWhenCustomOpeningFeeForTreasuryIs50Percent() public {
        // given
        _cfg.miltonImplementation = address(new MockCase4MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedLiquidityPoolBalance = 28002840597820653803859;

        uint256 expectedTreasuryBalance = 149505148455463361;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol
            .miltonStorage
            .getExtendedBalance();

        // then
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedTreasuryBalance);
    }

    function testShouldOpenPositionPayFixedDAIWhenCustomOpeningFeeForTreasuryIs25Percent() public {
        // given
        _cfg.miltonImplementation = address(new MockCase5MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedLiquidityPoolBalance = 28002915350394881535539;
        uint256 expectedTreasuryBalance = 74752574227731681;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol
            .miltonStorage
            .getExtendedBalance();

        // then
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedTreasuryBalance);
    }

    function testShouldOpenPayFixedDAIWhenCustomLeverageSimpleCase1() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        uint256 expectedCollateralBalance = TestConstants.TC_COLLATERAL_18DEC;
        uint256 expectedNotionalBalance = 150751024692592222333298;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            15125000000000000000
        );

        IporTypes.IporSwapMemory memory swapPayFixed = _iporProtocol.miltonStorage.getSwapPayFixed(
            1
        );

        // then
        assertEq(swapPayFixed.collateral, expectedCollateralBalance);
        assertEq(swapPayFixed.notional, expectedNotionalBalance);
    }

    function testShouldOpenPayFixedPositionWhenOpenTimestampIsLongTimeAgo() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 longAgoTimestamp = 31536000; //1971-01-01

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, longAgoTimestamp);

        openSwapPayFixed(
            _userTwo,
            longAgoTimestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            _iporProtocol.milton
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            longAgoTimestamp
        );

        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.ZERO;
        expectedBalances.expectedIncomeFeeValue = TestConstants.ZERO;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.LEVERAGE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs -
            expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC -
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;

        uint256 endTimestamp = longAgoTimestamp;

        // when
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(
            endTimestamp,
            1
        );
        actualBalances.actualIncomeFeeValue = _iporProtocol.milton.itfCalculateIncomeFeeValue(
            actualBalances.actualPayoff
        );
        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(
            address(_iporProtocol.milton)
        );
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol
            .miltonStorage
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length, "Incorrect swaps length");
        assertEq(
            actualBalances.actualPayoff,
            -int256(expectedBalances.expectedPayoffAbs),
            "Incorrect payoff"
        );
        assertEq(
            actualBalances.actualIncomeFeeValue,
            expectedBalances.expectedIncomeFeeValue,
            "Incorrect income fee value"
        );
        assertEq(
            actualBalances.actualSumOfBalances,
            expectedBalances.expectedSumOfBalancesBeforePayout,
            "Incorrect sum of balances"
        );
        assertEq(
            actualBalances.actualMiltonBalance,
            expectedBalances.expectedMiltonBalance,
            "Incorrect milton balance"
        );
        assertEq(
            actualBalances.actualOpenerUserBalance,
            expectedBalances.expectedOpenerUserBalance,
            "Incorrect opener user balance"
        );
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO, "Incorrect total collateral");
        assertEq(
            balance.iporPublicationFee,
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC,
            "Incorrect ipor publication fee"
        );
        assertEq(
            balance.liquidityPool,
            expectedBalances.expectedLiquidityPoolBalance,
            "Incorrect lp"
        );
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue, "Incorrect treasury");
        assertEq(soap, TestConstants.ZERO_INT, "Incorrect soap");
    }

    function testShouldArraysHaveCorrectStateWhenOneUserOpensManyPositions() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(
            3 * TestConstants.USD_28_000_18DEC,
            block.timestamp
        );

        // when
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            _iporProtocol.milton
        );

        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            _iporProtocol.milton
        );

        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            _iporProtocol.milton
        );

        // then
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            10
        );
        (uint256 swapsCount, uint256[] memory swapIds) = _iporProtocol
            .miltonStorage
            .getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swaps.length, 3);
        assertEq(swapIds.length, 3);
        assertEq(swapsCount, 3);
        assertEq(swaps[0].idsIndex, 0);
        assertEq(swaps[1].idsIndex, 1);
        assertEq(swaps[2].idsIndex, 2);
    }

    function testShouldArraysHaveCorrectStateWhenTwoUsersOpenPositions() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(
            3 * TestConstants.USD_28_000_18DEC,
            block.timestamp
        );

        // when
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            _iporProtocol.milton
        );

        openSwapPayFixed(
            _userThree,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            _iporProtocol.milton
        );

        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            _iporProtocol.milton
        );

        // then
        (, IporTypes.IporSwapMemory[] memory swapsUserOne) = _iporProtocol
            .miltonStorage
            .getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) = _iporProtocol
            .miltonStorage
            .getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swapsUserOne.length, 2);
        assertEq(swapsUserOneIds.length, 2);
        assertEq(swapsUserOneCount, 2);
        assertEq(swapsUserOne[0].idsIndex, 0);
        assertEq(swapsUserOne[0].id, 1);
        assertEq(swapsUserOne[1].idsIndex, 1);
        assertEq(swapsUserOne[1].id, 3);
        (, IporTypes.IporSwapMemory[] memory swapsUserTwo) = _iporProtocol
            .miltonStorage
            .getSwapsPayFixed(_userThree, TestConstants.ZERO, 10);
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) = _iporProtocol
            .miltonStorage
            .getSwapPayFixedIds(_userThree, TestConstants.ZERO, 10);
        assertEq(swapsUserTwo.length, 1);
        assertEq(swapsUserTwoIds.length, 1);
        assertEq(swapsUserTwoCount, 1);
        assertEq(swapsUserTwo[0].idsIndex, 0);
        assertEq(swapsUserTwo[0].id, 2);
    }

    function testShouldPositionArraysHaveCorrectIdsWhenTwoUsersOpenPositionsAndOnePositionIsClosed()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(
            3 * TestConstants.USD_28_000_18DEC,
            block.timestamp
        );

        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            _iporProtocol.milton
        );

        openSwapPayFixed(
            _userThree,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            _iporProtocol.milton
        );

        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            _iporProtocol.milton
        );

        // when
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapPayFixed(
            2,
            block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS
        );

        // then
        (, IporTypes.IporSwapMemory[] memory swapsUserOne) = _iporProtocol
            .miltonStorage
            .getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) = _iporProtocol
            .miltonStorage
            .getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swapsUserOne.length, 2);
        assertEq(swapsUserOneIds.length, 2);
        assertEq(swapsUserOneCount, 2);
        assertEq(swapsUserOne[0].idsIndex, 0);
        assertEq(swapsUserOne[0].id, 1);
        assertEq(swapsUserOne[1].idsIndex, 1);
        assertEq(swapsUserOne[1].id, 3);
        (, IporTypes.IporSwapMemory[] memory swapsUserTwo) = _iporProtocol
            .miltonStorage
            .getSwapsPayFixed(_userThree, TestConstants.ZERO, 10);
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) = _iporProtocol
            .miltonStorage
            .getSwapPayFixedIds(_userThree, TestConstants.ZERO, 10);
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }

    function testShouldPositionArraysHaveCorrectIdsWhenTwoUsersOpenPositionsAndAllExceptOnePositionAreClosed()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(
            3 * TestConstants.USD_28_000_18DEC,
            block.timestamp
        );

        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            _iporProtocol.milton
        );

        openSwapPayFixed(
            _userThree,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            _iporProtocol.milton
        );

        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            _iporProtocol.milton
        );

        // when
        _iporProtocol.milton.itfCloseSwapPayFixed(
            2,
            block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS
        );

        _iporProtocol.milton.itfCloseSwapPayFixed(
            3,
            block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS
        );

        // then
        (, IporTypes.IporSwapMemory[] memory swapsUserOne) = _iporProtocol
            .miltonStorage
            .getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) = _iporProtocol
            .miltonStorage
            .getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swapsUserOne.length, 1);
        assertEq(swapsUserOneIds.length, 1);
        assertEq(swapsUserOneCount, 1);
        assertEq(swapsUserOne[0].idsIndex, 0);
        assertEq(swapsUserOne[0].id, 1);
        (, IporTypes.IporSwapMemory[] memory swapsUserTwo) = _iporProtocol
            .miltonStorage
            .getSwapsPayFixed(_userThree, TestConstants.ZERO, 10);
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) = _iporProtocol
            .miltonStorage
            .getSwapPayFixedIds(_userThree, TestConstants.ZERO, 10);
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }

    function testShouldFixLastByteDifferenceWhenTwoPositionsAreOpenedAndClosedAndArithmeticOverflowCase1()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(
            2 * TestConstants.USD_28_000_18DEC,
            block.timestamp
        );

        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            _iporProtocol.milton
        );

        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            _iporProtocol.milton
        );

        // when
        _iporProtocol.milton.itfCloseSwapPayFixed(
            1,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        _iporProtocol.milton.itfCloseSwapPayFixed(
            2,
            block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS
        );
        vm.stopPrank();

        // then
        (, IporTypes.IporSwapMemory[] memory swapsUserOne) = _iporProtocol
            .miltonStorage
            .getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) = _iporProtocol
            .miltonStorage
            .getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swapsUserOne.length, 0);
        assertEq(swapsUserOneIds.length, 0);
        assertEq(swapsUserOneCount, 0);
        (, IporTypes.IporSwapMemory[] memory swapsUserTwo) = _iporProtocol
            .miltonStorage
            .getSwapsPayFixed(_userThree, TestConstants.ZERO, 10);
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) = _iporProtocol
            .miltonStorage
            .getSwapPayFixedIds(_userThree, TestConstants.ZERO, 10);
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }

    function testShouldFixLastByteDifferenceWhenTwoPositionsAreOpenedAndClosedAndArithmeticOverflowCase1Minus3()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(
            2 * TestConstants.USD_28_000_18DEC,
            block.timestamp
        );

        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            _iporProtocol.milton
        );

        uint256 threeDaysInSeconds = 259200;

        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS - threeDaysInSeconds,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            _iporProtocol.milton
        );

        // when
        _iporProtocol.milton.itfCloseSwapPayFixed(
            1,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        _iporProtocol.milton.itfCloseSwapPayFixed(
            2,
            block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS
        );

        // then
        (, IporTypes.IporSwapMemory[] memory swapsUserOne) = _iporProtocol
            .miltonStorage
            .getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) = _iporProtocol
            .miltonStorage
            .getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swapsUserOne.length, 0);
        assertEq(swapsUserOneIds.length, 0);
        assertEq(swapsUserOneCount, 0);
        (, IporTypes.IporSwapMemory[] memory swapsUserTwo) = _iporProtocol
            .miltonStorage
            .getSwapsPayFixed(_userThree, TestConstants.ZERO, 10);
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) = _iporProtocol
            .miltonStorage
            .getSwapPayFixedIds(_userThree, TestConstants.ZERO, 10);
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }

    function testShouldHaveLastByteDifferenceWhenTwoPositionsAreOpenedAndClosedAndArithmeticOverflowCase1()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(
            2 * TestConstants.USD_28_000_18DEC,
            block.timestamp
        );

        openSwapPayFixed(
            _userThree,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            _iporProtocol.milton
        );

        openSwapPayFixed(
            _userThree,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            _iporProtocol.milton
        );

        // when
        vm.startPrank(_userThree);
        _iporProtocol.milton.itfCloseSwapPayFixed(
            1,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        _iporProtocol.milton.itfCloseSwapPayFixed(
            2,
            block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS
        );
        vm.stopPrank();

        // then
        (, IporTypes.IporSwapMemory[] memory swapsUserOne) = _iporProtocol
            .miltonStorage
            .getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) = _iporProtocol
            .miltonStorage
            .getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swapsUserOne.length, 0);
        assertEq(swapsUserOneIds.length, 0);
        assertEq(swapsUserOneCount, 0);
        (, IporTypes.IporSwapMemory[] memory swapsUserTwo) = _iporProtocol
            .miltonStorage
            .getSwapsPayFixed(_userThree, TestConstants.ZERO, 10);
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) = _iporProtocol
            .miltonStorage
            .getSwapPayFixedIds(_userThree, TestConstants.ZERO, 10);
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }
}
