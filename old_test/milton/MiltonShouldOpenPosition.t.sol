// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@ipor-protocol/test/TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "@ipor-protocol/contracts/amm/AmmStorage.sol";
import "@ipor-protocol/test/mocks/spread/MockSpreadModel.sol";
import "@ipor-protocol/contracts/interfaces/types/IporTypes.sol";
import "@ipor-protocol/contracts/interfaces/types/AmmStorageTypes.sol";

contract AmmTreasuryShouldOpenPositionTest is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

    struct ActualBalances {
        uint256 actualSumOfBalances;
        uint256 actualAmmTreasuryBalance;
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
        _cfg.iporRiskManagementOracleUpdater = _userOne;

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
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 ammTreasuryBalanceBeforePayoutWad = TestConstants.USD_28_000_18DEC;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(ammTreasuryBalanceBeforePayoutWad);

        ExpectedAmmTreasuryBalances memory expectedBalances;

        expectedBalances.expectedAmmTreasuryBalance =
            ammTreasuryBalanceBeforePayoutWad +
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC;
        expectedBalances.expectedOpenerUserBalance = 9990000 * TestConstants.D18_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            ammTreasuryBalanceBeforePayoutWad +
            TestConstants.TC_OPENING_FEE_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            ammTreasuryBalanceBeforePayoutWad +
            TestConstants.USD_10_000_000_18DEC;

        uint256 expectedIporPublicationFee = TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC;
        uint256 expectedDerivativesTotalBalanceWad = TestConstants.TC_COLLATERAL_18DEC;

        // when
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
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
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        uint256 actualDerivativesTotalBalanceWad = balance.totalCollateralPayFixed +
            balance.totalCollateralReceiveFixed;
        // then
        assertEq(actualOpenSwapsVolume, 1);
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedBalances.expectedAmmTreasuryBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(
            actualDerivativesTotalBalanceWad,
            expectedDerivativesTotalBalanceWad,
            "incorrect derivatives total balance"
        );
        assertEq(balance.iporPublicationFee, expectedIporPublicationFee, "incorrect ipor publication fee");
        assertEq(
            balance.liquidityPool,
            expectedBalances.expectedLiquidityPoolBalance,
            "incorrect liquidity pool balance"
        );
        assertEq(balance.treasury, TestConstants.ZERO, "incorrect treasury balance");
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances, "incorrect sum of balances");
    }

    function testShouldOpenPositionPayFixedUSDTWhenOwnerSimpleCase6Decimals() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_6DEC);

        ExpectedAmmTreasuryBalances memory expectedBalances;

        expectedBalances.expectedAmmTreasuryBalance =
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
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
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
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        uint256 actualDerivativesTotalBalanceWad = balance.totalCollateralPayFixed +
            balance.totalCollateralReceiveFixed;

        // then
        assertEq(actualOpenSwapsVolume, 1);
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedBalances.expectedAmmTreasuryBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(
            actualDerivativesTotalBalanceWad,
            expectedDerivativesTotalBalanceWad,
            "incorrect derivatives total balance"
        );
        assertEq(balance.iporPublicationFee, expectedIporPublicationFee, "incorrect ipor publication fee");
        assertEq(
            balance.liquidityPool,
            expectedBalances.expectedLiquidityPoolBalance,
            "incorrect liquidity pool balance"
        );
        assertEq(balance.treasury, TestConstants.ZERO, "incorrect treasury balance");
        assertEq(
            expectedBalances.expectedSumOfBalancesBeforePayout,
            actualSumOfBalances,
            "incorrect sum of balances before payout"
        );
    }

    function testShouldOpenPositionPayFixedUSDTWhenRiskManagementOracleProvidesLargeValues() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _cfg.iporRiskManagementOracleInitialParamsTestCase = BuilderUtils
            .IporRiskManagementOracleInitialParamsTestCase
            .CASE4;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_6DEC);
        ExpectedAmmTreasuryBalances memory expectedBalances;
        expectedBalances.expectedAmmTreasuryBalance =
            TestConstants.USD_28_000_6DEC +
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC;
        expectedBalances.expectedOpenerUserBalance = 9990000000000;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.USD_28_000_18DEC +
            TestConstants.TC_OPENING_FEE_1000LEV_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.USD_28_000_6DEC +
            TestConstants.USD_10_000_000_6DEC;

        uint256 expectedDerivativesTotalBalanceWad = TestConstants.TC_COLLATERAL_1000LEV_18DEC;
        uint256 expectedIporPublicationFee = TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC;
        // when
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
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
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        uint256 actualDerivativesTotalBalanceWad = balance.totalCollateralPayFixed +
            balance.totalCollateralReceiveFixed;
        // then
        assertEq(actualOpenSwapsVolume, 1, "incorrect open swaps volume");
        assertEq(
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)),
            expectedBalances.expectedAmmTreasuryBalance,
            "incorrect ammTreasury balance"
        );
        assertEq(
            int256(_iporProtocol.asset.balanceOf(_userTwo)),
            expectedBalances.expectedOpenerUserBalance,
            "incorrect opener user balance"
        );
        assertEq(
            actualDerivativesTotalBalanceWad,
            expectedDerivativesTotalBalanceWad,
            "incorrect derivatives total balance"
        );
        assertEq(balance.iporPublicationFee, expectedIporPublicationFee, "incorrect ipor publication fee");
        assertEq(
            balance.liquidityPool,
            expectedBalances.expectedLiquidityPoolBalance,
            "incorrect liquidity pool balance"
        );
        assertEq(balance.treasury, TestConstants.ZERO, "incorrect treasury balance");
        assertEq(
            expectedBalances.expectedSumOfBalancesBeforePayout,
            actualSumOfBalances,
            "incorrect sum of balances before payout"
        );
    }

    function testShouldOpenPositionPayFixedDAIWhenCustomOpeningFeeForTreasuryIs50Percent() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE4;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        ExpectedAmmTreasuryBalances memory expectedBalances;
        expectedBalances.expectedLiquidityPoolBalance = 28002179240941810653092;

        uint256 expectedTreasuryBalance = 114696891674244900;
        // when
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();

        // then
        assertEq(
            balance.liquidityPool,
            expectedBalances.expectedLiquidityPoolBalance,
            "incorrect liquidity pool balance"
        );
        assertEq(balance.treasury, expectedTreasuryBalance, "incorrect treasury balance");
    }

    function testShouldOpenPositionPayFixedDAIWhenCustomOpeningFeeForTreasuryIs25Percent() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE5;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        ExpectedAmmTreasuryBalances memory expectedBalances;
        expectedBalances.expectedLiquidityPoolBalance = 28002236589387647775542;
        uint256 expectedTreasuryBalance = 57348445837122450;
        // when
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();

        // then
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedTreasuryBalance);
    }

    function testShouldOpenPayFixedDAIWhenCustomLeverageSimpleCase1() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        uint256 expectedCollateralBalance = 9966530828104902114760;
        uint256 expectedNotionalBalance = 150743778775086644485745;
        // when
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            15125000000000000000
        );

        AmmTypes.Swap memory swapPayFixed = _iporProtocol.ammStorage.getSwapPayFixed(1);

        // then
        assertEq(swapPayFixed.collateral, expectedCollateralBalance, "incorrect collateral");
        assertEq(swapPayFixed.notional, expectedNotionalBalance, "incorrect notional");
    }

    function testShouldOpenPayFixedPositionWhenOpenTimestampIsLongTimeAgo() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 longAgoTimestamp = 31536000; //1971-01-01

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, longAgoTimestamp);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.itfOpenSwapPayFixed(
            longAgoTimestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            longAgoTimestamp
        );

        ExpectedAmmTreasuryBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.ZERO;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedAmmTreasuryBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.LEVERAGE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC -
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;

        uint256 endTimestamp = longAgoTimestamp;

        // when
        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualAmmTreasuryBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);
        assertEq(TestConstants.ZERO, swaps.length, "Incorrect swaps length");
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs), "Incorrect payoff");
        assertEq(
            actualBalances.actualSumOfBalances,
            expectedBalances.expectedSumOfBalancesBeforePayout,
            "Incorrect sum of balances"
        );
        assertEq(
            actualBalances.actualAmmTreasuryBalance,
            expectedBalances.expectedAmmTreasuryBalance,
            "Incorrect ammTreasury balance"
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
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance, "Incorrect lp");

        assertEq(soap, TestConstants.ZERO_INT, "Incorrect soap");
    }

    function testShouldArraysHaveCorrectStateWhenOneUserOpensManyPositions() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(3 * TestConstants.USD_28_000_18DEC);

        // when
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        // then
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            10
        );
        (uint256 swapsCount, uint256[] memory swapIds) = _iporProtocol.ammStorage.getSwapIds(
            _userTwo,
            TestConstants.ZERO,
            10
        );
        assertEq(swaps.length, 3);
        assertEq(swapIds.length, 3);
        assertEq(swapsCount, 3);
        assertEq(swaps[0].idsIndex, 0);
        assertEq(swaps[1].idsIndex, 1);
        assertEq(swaps[2].idsIndex, 2);
    }

    function testShouldArraysHaveCorrectStateWhenTwoUsersOpenPositions() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(3 * TestConstants.USD_28_000_18DEC);

        // when
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );
        vm.prank(_userThree);
        _iporProtocol.ammTreasury.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        // then
        (, AmmTypes.Swap[] memory swapsUserOne) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            10
        );
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) = _iporProtocol.ammStorage.getSwapIds(
            _userTwo,
            TestConstants.ZERO,
            10
        );
        assertEq(swapsUserOne.length, 2);
        assertEq(swapsUserOneIds.length, 2);
        assertEq(swapsUserOneCount, 2);
        assertEq(swapsUserOne[0].idsIndex, 0);
        assertEq(swapsUserOne[0].id, 1);
        assertEq(swapsUserOne[1].idsIndex, 1);
        assertEq(swapsUserOne[1].id, 3);
        (, AmmTypes.Swap[] memory swapsUserTwo) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userThree,
            TestConstants.ZERO,
            10
        );
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) = _iporProtocol.ammStorage.getSwapIds(
            _userThree,
            TestConstants.ZERO,
            10
        );
        assertEq(swapsUserTwo.length, 1);
        assertEq(swapsUserTwoIds.length, 1);
        assertEq(swapsUserTwoCount, 1);
        assertEq(swapsUserTwo[0].idsIndex, 0);
        assertEq(swapsUserTwo[0].id, 2);
    }

    function testShouldPositionArraysHaveCorrectIdsWhenTwoUsersOpenPositionsAndOnePositionIsClosed() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(3 * TestConstants.USD_28_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );
        vm.prank(_userThree);
        _iporProtocol.ammTreasury.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        vm.prank(_userThree);
        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(2, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        // then
        (, AmmTypes.Swap[] memory swapsUserOne) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            10
        );
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) = _iporProtocol.ammStorage.getSwapIds(
            _userTwo,
            TestConstants.ZERO,
            10
        );
        assertEq(swapsUserOne.length, 2);
        assertEq(swapsUserOneIds.length, 2);
        assertEq(swapsUserOneCount, 2);
        assertEq(swapsUserOne[0].idsIndex, 0);
        assertEq(swapsUserOne[0].id, 1);
        assertEq(swapsUserOne[1].idsIndex, 1);
        assertEq(swapsUserOne[1].id, 3);
        (, AmmTypes.Swap[] memory swapsUserTwo) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userThree,
            TestConstants.ZERO,
            10
        );
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) = _iporProtocol.ammStorage.getSwapIds(
            _userThree,
            TestConstants.ZERO,
            10
        );
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }

    function testShouldPositionArraysHaveCorrectIdsWhenTwoUsersOpenPositionsAndAllExceptOnePositionAreClosed() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(3 * TestConstants.USD_28_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(2, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(3, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        // then
        (, AmmTypes.Swap[] memory swapsUserOne) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            10
        );
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) = _iporProtocol.ammStorage.getSwapIds(
            _userTwo,
            TestConstants.ZERO,
            10
        );
        assertEq(swapsUserOne.length, 1);
        assertEq(swapsUserOneIds.length, 1);
        assertEq(swapsUserOneCount, 1);
        assertEq(swapsUserOne[0].idsIndex, 0);
        assertEq(swapsUserOne[0].id, 1);
        (, AmmTypes.Swap[] memory swapsUserTwo) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userThree,
            TestConstants.ZERO,
            10
        );
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) = _iporProtocol.ammStorage.getSwapIds(
            _userThree,
            TestConstants.ZERO,
            10
        );
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }

    function testShouldFixLastByteDifferenceWhenTwoPositionsAreOpenedAndClosedAndArithmeticOverflowCase1() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(2 * TestConstants.USD_28_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(2, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.stopPrank();

        // then
        (, AmmTypes.Swap[] memory swapsUserOne) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            10
        );
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) = _iporProtocol.ammStorage.getSwapIds(
            _userTwo,
            TestConstants.ZERO,
            10
        );
        assertEq(swapsUserOne.length, 0);
        assertEq(swapsUserOneIds.length, 0);
        assertEq(swapsUserOneCount, 0);
        (, AmmTypes.Swap[] memory swapsUserTwo) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userThree,
            TestConstants.ZERO,
            10
        );
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) = _iporProtocol.ammStorage.getSwapIds(
            _userThree,
            TestConstants.ZERO,
            10
        );
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }

    function testShouldFixLastByteDifferenceWhenTwoPositionsAreOpenedAndClosedAndArithmeticOverflowCase1Minus3()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(2 * TestConstants.USD_28_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        uint256 threeDaysInSeconds = 259200;

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS - threeDaysInSeconds,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(2, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        // then
        (, AmmTypes.Swap[] memory swapsUserOne) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            10
        );
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) = _iporProtocol.ammStorage.getSwapIds(
            _userTwo,
            TestConstants.ZERO,
            10
        );
        assertEq(swapsUserOne.length, 0);
        assertEq(swapsUserOneIds.length, 0);
        assertEq(swapsUserOneCount, 0);
        (, AmmTypes.Swap[] memory swapsUserTwo) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userThree,
            TestConstants.ZERO,
            10
        );
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) = _iporProtocol.ammStorage.getSwapIds(
            _userThree,
            TestConstants.ZERO,
            10
        );
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }

    function testShouldHaveLastByteDifferenceWhenTwoPositionsAreOpenedAndClosedAndArithmeticOverflowCase1() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(2 * TestConstants.USD_28_000_18DEC);

        vm.prank(_userThree);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userThree);
        _iporProtocol.ammTreasury.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        vm.startPrank(_userThree);
        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(2, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.stopPrank();

        // then
        (, AmmTypes.Swap[] memory swapsUserOne) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            10
        );
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) = _iporProtocol.ammStorage.getSwapIds(
            _userTwo,
            TestConstants.ZERO,
            10
        );
        assertEq(swapsUserOne.length, 0);
        assertEq(swapsUserOneIds.length, 0);
        assertEq(swapsUserOneCount, 0);
        (, AmmTypes.Swap[] memory swapsUserTwo) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userThree,
            TestConstants.ZERO,
            10
        );
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) = _iporProtocol.ammStorage.getSwapIds(
            _userThree,
            TestConstants.ZERO,
            10
        );
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }
}
