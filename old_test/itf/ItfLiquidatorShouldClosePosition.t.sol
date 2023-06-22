// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@ipor-protocol/test/TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "@ipor-protocol/test/mocks/spread/MockSpreadModel.sol";
import "@ipor-protocol/contracts/amm/AmmStorage.sol";
import "@ipor-protocol/contracts/itf/ItfLiquidator.sol";
import "@ipor-protocol/contracts/interfaces/types/IporTypes.sol";
import "@ipor-protocol/contracts/interfaces/types/AmmTypes.sol";
import "../utils/builder/BuilderUtils.sol";
import {MockCaseBaseAssetManagement} from "@ipor-protocol/test/mocks/assetManagement/MockCaseBaseAssetManagement.sol";

contract ItfLiquidatorShouldClosePositionTest is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

    /// @notice Emmited when trader closes Swap.
    event CloseSwap(
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice underlying asset
        address asset,
        /// @notice the moment when swap was closed
        uint256 closeTimestamp,
        /// @notice account that liquidated the swap
        address liquidator,
        /// @notice asset amount after closing swap that has been transferred from AmmTreasury to the Buyer. Value represented in 18 decimals.
        uint256 transferredToBuyer,
        /// @notice asset amount after closing swap that has been transferred from AmmTreasury to the Liquidator. Value represented in 18 decimals.
        uint256 transferredToLiquidator
    );

    struct VolumeSwaps {
        uint256 volumePayFixedSwaps;
        uint256 volumeReceiveFixedSwaps;
        uint256 volumePayFixedSwapsOpenLater;
        uint256 volumeReceiveFixedSwapsOpenLater;
    }

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
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.PERCENTAGE_4_18DEC,
                TestConstants.ZERO_INT,
                TestConstants.ZERO_INT
            )
        );
    }

    function testShouldEmitCloseSwapEventWhenPayFixed() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;

        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_18DEC);

        vm.startPrank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.USD_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.USD_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
        vm.stopPrank();

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;
        uint256[] memory payFixedSwapIds = new uint256[](2);
        payFixedSwapIds[0] = 1;
        payFixedSwapIds[1] = 2;
        uint256[] memory receiveFixedSwapIds = new uint256[](0);

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        vm.expectEmit(true, true, true, true);
        emit CloseSwap(
            1,
            address(_iporProtocol.asset),
            endTimestamp,
            address(itfLiquidator),
            19935412124333030204016,
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC
        );

        vm.expectEmit(true, true, true, true);
        emit CloseSwap(
            2,
            address(_iporProtocol.asset),
            endTimestamp,
            address(itfLiquidator),
            19935412124333030204016,
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC
        );

        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);
    }

    function testShouldEmitCloseSwapEventWhenReceiveFixed() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_18DEC);

        vm.startPrank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.USD_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.USD_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
        vm.stopPrank();

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;
        uint256[] memory payFixedSwapIds = new uint256[](0);
        uint256[] memory receiveFixedSwapIds = new uint256[](2);
        receiveFixedSwapIds[0] = 1;
        receiveFixedSwapIds[1] = 2;

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        vm.expectEmit(true, true, true, true);
        emit CloseSwap(
            1,
            address(_iporProtocol.asset),
            endTimestamp,
            address(itfLiquidator),
            TestConstants.ZERO,
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC
        );
        vm.expectEmit(true, true, true, true);
        emit CloseSwap(
            2,
            address(_iporProtocol.asset),
            endTimestamp,
            address(itfLiquidator),
            TestConstants.ZERO,
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC
        );

        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);
    }

    function testShouldClose10PayFixedSwapsAnd10ReceiveFixedSwapsInOneTransactionCase1WhenAllAreOpened() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;

        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 10;
        volumeSwaps.volumeReceiveFixedSwaps = 10;
        uint256 expectedSwapStatus = TestConstants.ZERO;
        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(
            (volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) * TestConstants.USD_28_000_18DEC
        );

        vm.startPrank(_userTwo);
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            _iporProtocol.ammTreasury.openSwapPayFixed(
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            payFixedSwapIds[i] = i + 1;
        }

        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps;
            i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps;
            ++i
        ) {
            _iporProtocol.ammTreasury.openSwapReceiveFixed(
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            receiveFixedSwapIds[i - volumeSwaps.volumePayFixedSwaps] = i + 1;
        }
        vm.stopPrank();

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            AmmTypes.Swap memory iporPayFixedSwap = _iporProtocol.ammStorage.getSwapPayFixed(i + 1);
            assertEq(iporPayFixedSwap.state, expectedSwapStatus);
        }

        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps;
            i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps;
            ++i
        ) {
            AmmTypes.Swap memory iporReceiveFixedSwap = _iporProtocol.ammStorage.getSwapReceiveFixed(
                i + 1
            );
            assertEq(iporReceiveFixedSwap.state, expectedSwapStatus);
        }
    }

    function testShouldClose5PayFixedSwapsAndLeaveAnother5OpenAndClose5ReceiveFixedSwapsAndLeaveAnother5OpenInOneTransactionCase2WhenSomeOfThemAreAlreadyClosedAndSomeExpired()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 5;
        volumeSwaps.volumeReceiveFixedSwaps = 5;
        volumeSwaps.volumePayFixedSwapsOpenLater = 5;
        volumeSwaps.volumeReceiveFixedSwapsOpenLater = 5;

        uint256[] memory payFixedSwapIds = new uint256[](
            volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumePayFixedSwapsOpenLater
        );
        uint256[] memory receiveFixedSwapIds = new uint256[](
            volumeSwaps.volumeReceiveFixedSwaps + volumeSwaps.volumeReceiveFixedSwapsOpenLater
        );

        uint256 openLaterTimestamp = block.timestamp + TestConstants.PERIOD_14_DAYS_IN_SECONDS;
        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;
        uint256 expectedSwapStatus = TestConstants.ZERO;
        uint256 expectedSwapStatusOpenLater = 1;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(
            (volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) * TestConstants.USD_28_000_18DEC
        );

        vm.startPrank(_userTwo);
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            _iporProtocol.ammTreasury.openSwapPayFixed(
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            payFixedSwapIds[i] = i + 1;
        }

        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps;
            i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps;
            ++i
        ) {
            _iporProtocol.ammTreasury.openSwapReceiveFixed(
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            receiveFixedSwapIds[i - volumeSwaps.volumePayFixedSwaps] = i + 1;
        }

        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps;
            i <
            volumeSwaps.volumePayFixedSwaps +
                volumeSwaps.volumeReceiveFixedSwaps +
                volumeSwaps.volumePayFixedSwapsOpenLater;
            ++i
        ) {
            _iporProtocol.ammTreasury.itfOpenSwapPayFixed(
                openLaterTimestamp,
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            payFixedSwapIds[i - volumeSwaps.volumeReceiveFixedSwaps] = i + 1;
        }

        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps +
                volumeSwaps.volumeReceiveFixedSwaps +
                volumeSwaps.volumePayFixedSwapsOpenLater;
            i <
            volumeSwaps.volumePayFixedSwaps +
                volumeSwaps.volumeReceiveFixedSwaps +
                volumeSwaps.volumePayFixedSwapsOpenLater +
                volumeSwaps.volumeReceiveFixedSwapsOpenLater;
            ++i
        ) {
            _iporProtocol.ammTreasury.itfOpenSwapReceiveFixed(
                openLaterTimestamp,
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            receiveFixedSwapIds[i - (volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps)] = i + 1;
        }
        vm.stopPrank();

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            AmmTypes.Swap memory iporPayFixedSwap = _iporProtocol.ammStorage.getSwapPayFixed(i + 1);
            assertEq(iporPayFixedSwap.state, expectedSwapStatus);
        }
        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps;
            i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps;
            ++i
        ) {
            AmmTypes.Swap memory iporReceiveFixedSwap = _iporProtocol.ammStorage.getSwapReceiveFixed(
                i + 1
            );
            assertEq(iporReceiveFixedSwap.state, expectedSwapStatus);
        }
        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps;
            i <
            volumeSwaps.volumePayFixedSwaps +
                volumeSwaps.volumeReceiveFixedSwaps +
                volumeSwaps.volumePayFixedSwapsOpenLater;
            ++i
        ) {
            AmmTypes.Swap memory iporPayFixedSwapOpenedLater = _iporProtocol.ammStorage.getSwapPayFixed(
                i + 1
            );
            assertEq(iporPayFixedSwapOpenedLater.state, expectedSwapStatusOpenLater);
        }
        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps +
                volumeSwaps.volumeReceiveFixedSwaps +
                volumeSwaps.volumePayFixedSwapsOpenLater;
            i <
            volumeSwaps.volumePayFixedSwaps +
                volumeSwaps.volumeReceiveFixedSwaps +
                volumeSwaps.volumePayFixedSwapsOpenLater +
                volumeSwaps.volumeReceiveFixedSwapsOpenLater;
            ++i
        ) {
            AmmTypes.Swap memory iporReceiveFixedSwapOpenedLater = _iporProtocol
                .ammStorage
                .getSwapReceiveFixed(i + 1);
            assertEq(iporReceiveFixedSwapOpenedLater.state, expectedSwapStatusOpenLater);
        }
    }

    function testShouldClose5PayFixedSwapsAndClose5ReceiveFixedSwapsInOneTransactionCase2WhenSomeOfThemAreAlreadyClosed()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 5;
        volumeSwaps.volumeReceiveFixedSwaps = 5;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;
        uint256 expectedSwapStatus = TestConstants.ZERO;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(
            (volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) * TestConstants.USD_28_000_18DEC
        );

        vm.startPrank(_userTwo);
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            _iporProtocol.ammTreasury.openSwapPayFixed(
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            payFixedSwapIds[i] = i + 1;
        }

        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps;
            i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps;
            ++i
        ) {
            _iporProtocol.ammTreasury.openSwapReceiveFixed(
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            receiveFixedSwapIds[i - volumeSwaps.volumePayFixedSwaps] = i + 1;
        }

        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(3, endTimestamp);
        _iporProtocol.ammTreasury.itfCloseSwapReceiveFixed(8, endTimestamp);
        vm.stopPrank();

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            AmmTypes.Swap memory iporPayFixedSwap = _iporProtocol.ammStorage.getSwapPayFixed(i + 1);
            assertEq(iporPayFixedSwap.state, expectedSwapStatus);
        }
        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps;
            i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps;
            ++i
        ) {
            AmmTypes.Swap memory iporReceiveFixedSwap = _iporProtocol.ammStorage.getSwapReceiveFixed(
                i + 1
            );
            assertEq(iporReceiveFixedSwap.state, expectedSwapStatus);
        }
        AmmTypes.Swap memory closedPayFixedSwap = _iporProtocol.ammStorage.getSwapPayFixed(3);
        assertEq(closedPayFixedSwap.state, expectedSwapStatus);
        AmmTypes.Swap memory closedReceiveFixedSwap = _iporProtocol.ammStorage.getSwapReceiveFixed(8);
        assertEq(closedReceiveFixedSwap.state, expectedSwapStatus);
    }

    function testShouldClose10PayFixedSwapsAnd10ReceiveFixedSwapsInOneTransactionWhenLiquidationDepositAmountNotTransferredToLiquidator()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 10;
        volumeSwaps.volumeReceiveFixedSwaps = 10;
        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;

        uint256 expectedBalanceTrader = 9997824829354340370956010;

        uint256 expectedBalanceLiquidator = (volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) *
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(
            (volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) * TestConstants.USD_28_000_18DEC
        );
        vm.startPrank(_userTwo);
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            _iporProtocol.ammTreasury.openSwapPayFixed(
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            payFixedSwapIds[i] = i + 1;
        }
        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps;
            i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps;
            ++i
        ) {
            _iporProtocol.ammTreasury.openSwapReceiveFixed(
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            receiveFixedSwapIds[i - volumeSwaps.volumePayFixedSwaps] = i + 1;
        }
        vm.stopPrank();

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);
        // then
        uint256 actualBalanceLiquidator = _iporProtocol.asset.balanceOf(address(itfLiquidator));
        assertEq(actualBalanceLiquidator, expectedBalanceLiquidator);
        uint256 actualBalanceTrader = _iporProtocol.asset.balanceOf(address(_userTwo));
        assertEq(actualBalanceTrader, expectedBalanceTrader);
    }

    function testShouldClose2PayFixedAnd0ReceiveFixedPositionsInOneTransactionWhenAllReceiveFixedPositionsAreAlreadyClosed()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );
        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 10;
        volumeSwaps.volumeReceiveFixedSwaps = 10;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;

        uint256 expectedBalanceTrader = 9998024829354340370956010;

        uint256 expectedBalanceLiquidator = volumeSwaps.volumePayFixedSwaps *
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(
            (volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) * TestConstants.USD_28_000_18DEC
        );
        vm.startPrank(_userTwo);
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            _iporProtocol.ammTreasury.openSwapPayFixed(
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            payFixedSwapIds[i] = i + 1;
        }
        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps;
            i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps;
            ++i
        ) {
            _iporProtocol.ammTreasury.openSwapReceiveFixed(
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            receiveFixedSwapIds[i - volumeSwaps.volumePayFixedSwaps] = i + 1;
        }
        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps;
            i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps;
            ++i
        ) {
            _iporProtocol.ammTreasury.itfCloseSwapReceiveFixed(i + 1, endTimestamp);
        }
        vm.stopPrank();

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        uint256 actualBalanceLiquidator = _iporProtocol.asset.balanceOf(address(itfLiquidator));
        assertEq(actualBalanceLiquidator, expectedBalanceLiquidator);
        uint256 actualBalanceTrader = _iporProtocol.asset.balanceOf(address(_userTwo));
        assertEq(actualBalanceTrader, expectedBalanceTrader);
    }

    function testShouldClose0PayFixedAnd2ReceiveFixedPositionsInOneTransactionWhenAllPayFixedPositionsAreAlreadyClosed()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 10;
        volumeSwaps.volumeReceiveFixedSwaps = 10;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;

        uint256 expectedBalanceTrader = 9997824829354340370956010;

        uint256 expectedBalanceLiquidator = volumeSwaps.volumeReceiveFixedSwaps *
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(
            (volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) * TestConstants.USD_28_000_18DEC
        );

        vm.startPrank(_userTwo);
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            _iporProtocol.ammTreasury.openSwapPayFixed(
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            payFixedSwapIds[i] = i + 1;
        }

        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps;
            i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps;
            ++i
        ) {
            _iporProtocol.ammTreasury.openSwapReceiveFixed(
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            receiveFixedSwapIds[i - volumeSwaps.volumePayFixedSwaps] = i + 1;
        }
        vm.stopPrank();

        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            _iporProtocol.ammTreasury.itfCloseSwapPayFixed(i + 1, endTimestamp);
        }

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        uint256 actualBalanceLiquidator = _iporProtocol.asset.balanceOf(address(itfLiquidator));
        assertEq(
            actualBalanceLiquidator,
            expectedBalanceLiquidator,
            "actualBalanceLiquidator != expectedBalanceLiquidator"
        );
        uint256 actualBalanceTrader = _iporProtocol.asset.balanceOf(address(_userTwo));
        assertEq(actualBalanceTrader, expectedBalanceTrader, "actualBalanceTrader != expectedBalanceTrader");
    }

    function testShouldCommitTransactionWhenTryToClose2PayFixedSwapsAnd2ReceiveFixedSwapsInOneTransactionWhenAllPositionsAreAlreadyClosed()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );
        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 2;
        volumeSwaps.volumeReceiveFixedSwaps = 2;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;
        uint256 expectedBalanceLiquidator = 0;
        uint256 expectedBalanceTrader = 9999644965870868074191202;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(
            (volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) * TestConstants.USD_28_000_18DEC,
            block.timestamp
        );
        vm.startPrank(_userTwo);
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            _iporProtocol.ammTreasury.openSwapPayFixed(
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            payFixedSwapIds[i] = i + 1;
        }
        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps;
            i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps;
            ++i
        ) {
            _iporProtocol.ammTreasury.openSwapReceiveFixed(
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            receiveFixedSwapIds[i - volumeSwaps.volumePayFixedSwaps] = i + 1;
        }
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            _iporProtocol.ammTreasury.itfCloseSwapPayFixed(i + 1, endTimestamp);
        }
        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps;
            i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps;
            ++i
        ) {
            _iporProtocol.ammTreasury.itfCloseSwapReceiveFixed(i + 1, endTimestamp);
        }
        vm.stopPrank();

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        uint256 actualBalanceLiquidator = _iporProtocol.asset.balanceOf(address(itfLiquidator));
        assertEq(actualBalanceLiquidator, expectedBalanceLiquidator);
        uint256 actualBalanceTrader = _iporProtocol.asset.balanceOf(address(_userTwo));
        assertEq(actualBalanceTrader, expectedBalanceTrader);
    }

    function testShouldCommitTransactionEvenIfListsForClosingAreEmpty() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );
        uint256[] memory payFixedSwapIds = new uint256[](TestConstants.ZERO);
        uint256[] memory receiveFixedSwapIds = new uint256[](TestConstants.ZERO);
        uint256 endTimestamp = block.timestamp;

        // when
        (
            AmmTypes.IporSwapClosingResult[] memory payFixedClosedSwaps,
            AmmTypes.IporSwapClosingResult[] memory receiveFixedClosedSwaps
        ) = itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);
        // then
        assertEq(payFixedClosedSwaps.length, TestConstants.ZERO);
        assertEq(receiveFixedClosedSwaps.length, TestConstants.ZERO);
    }

    function testShouldClosePositionDAIPayFixedWhenLiquidatorLostAndUserEarnedMoreThanCollateralBeforeMaturity18Decimals()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_1_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );
        ExpectedAmmTreasuryBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedAmmTreasuryBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 1;
        volumeSwaps.volumeReceiveFixedSwaps = 0;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        payFixedSwapIds[0] = 1;

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(address(itfLiquidator));
        actualBalances.actualAmmTreasuryBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(address(itfLiquidator)));
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualAmmTreasuryBalance, expectedBalances.expectedAmmTreasuryBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIPayFixedWhenLiquidatorLostAndUserEarnedBetween99And100PercentOfCollateralBeforeMaturity18Decimals()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_151_18DEC,
            block.timestamp
        );

        ExpectedAmmTreasuryBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = 9899434102836607430187;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedAmmTreasuryBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 1;
        volumeSwaps.volumeReceiveFixedSwaps = 0;

        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);

        payFixedSwapIds[0] = 1;

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;

        actualBalances.actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(address(itfLiquidator));
        actualBalances.actualAmmTreasuryBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(address(itfLiquidator)));
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));

        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualAmmTreasuryBalance, expectedBalances.expectedAmmTreasuryBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
        assertLt(int256(expectedBalances.expectedPayoffAbs), TestConstants.TC_COLLATERAL_18DEC_INT);
    }

    function testShouldClosePositionDAIPayFixedWhenLiquidatorLostAndUserEarnedMoreThanCollateralAfterMaturity18Decimals()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_1_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        ExpectedAmmTreasuryBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedAmmTreasuryBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 1;
        volumeSwaps.volumeReceiveFixedSwaps = 0;

        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);

        payFixedSwapIds[0] = 1;

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;

        actualBalances.actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(address(itfLiquidator));
        actualBalances.actualAmmTreasuryBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(address(itfLiquidator)));
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualAmmTreasuryBalance, expectedBalances.expectedAmmTreasuryBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIPayFixedWhenLiquidatorLostAndUserEarnedLessThanCollateralAfterMaturity18Decimals()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_50_18DEC,
            block.timestamp
        );

        ExpectedAmmTreasuryBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = 6007932421031872131299;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedAmmTreasuryBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 1;
        volumeSwaps.volumeReceiveFixedSwaps = 0;

        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);

        payFixedSwapIds[0] = 1;

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;

        actualBalances.actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(address(itfLiquidator));
        actualBalances.actualAmmTreasuryBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(address(itfLiquidator)));
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));

        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualAmmTreasuryBalance, expectedBalances.expectedAmmTreasuryBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
        assertLt(int256(expectedBalances.expectedPayoffAbs), TestConstants.TC_COLLATERAL_18DEC_INT);
    }

    function testShouldClosePositionDAIPayFixedWhenLiquidatorEarnedAndUserLostMoreThanCollateralBeforeMaturity18Decimals()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_161_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_161_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        ExpectedAmmTreasuryBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedAmmTreasuryBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 1;
        volumeSwaps.volumeReceiveFixedSwaps = 0;

        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);

        payFixedSwapIds[0] = 1;

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1
        );

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(address(itfLiquidator));
        actualBalances.actualAmmTreasuryBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(address(itfLiquidator)));
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            _iporProtocol.ammTreasury
        );
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));

        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualAmmTreasuryBalance, expectedBalances.expectedAmmTreasuryBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIPayFixedWhenLiquidatorEarnedAndUserLostBetween99And100PercentOfCollateralBeforeMaturity18Decimals()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_151_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_151_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            block.timestamp
        );

        ExpectedAmmTreasuryBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 9899434102836607505286;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedAmmTreasuryBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 1;
        volumeSwaps.volumeReceiveFixedSwaps = 0;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        payFixedSwapIds[0] = 1;

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(address(itfLiquidator));
        actualBalances.actualAmmTreasuryBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(address(itfLiquidator)));
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualAmmTreasuryBalance, expectedBalances.expectedAmmTreasuryBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
        assertLt(int256(expectedBalances.expectedPayoffAbs), TestConstants.TC_COLLATERAL_18DEC_INT);
    }

    function testShouldClosePositionDAIPayFixedWhenLiquidatorEarnedAndUserLostLessThanCollateralAfterMaturity18Decimals()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_10_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        ExpectedAmmTreasuryBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 682719593299076345445;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedAmmTreasuryBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT *
            1e18 +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 1;
        volumeSwaps.volumeReceiveFixedSwaps = 0;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        payFixedSwapIds[0] = 1;

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(address(itfLiquidator));
        actualBalances.actualAmmTreasuryBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(address(itfLiquidator)));
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualAmmTreasuryBalance, expectedBalances.expectedAmmTreasuryBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIPayFixedWhenLiquidatorEarnedAndUserLostMoreThanCollateralAfterMaturity18Decimals()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_161_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_161_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        ExpectedAmmTreasuryBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedAmmTreasuryBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT *
            1e18 +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 1;
        volumeSwaps.volumeReceiveFixedSwaps = 0;

        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);

        payFixedSwapIds[0] = 1;

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(address(itfLiquidator));
        actualBalances.actualAmmTreasuryBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(address(itfLiquidator)));
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualAmmTreasuryBalance, expectedBalances.expectedAmmTreasuryBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIReceiveFixedWhenLiquidatorLostAndUserEarnedBetween99And100PercentOfCollateralBeforeMaturity18Decimals()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_150_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_150_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        ExpectedAmmTreasuryBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = 9899434102836607498459;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedAmmTreasuryBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 0;
        volumeSwaps.volumeReceiveFixedSwaps = 1;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        receiveFixedSwapIds[0] = 1;

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(address(itfLiquidator));
        actualBalances.actualAmmTreasuryBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(address(itfLiquidator)));
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualAmmTreasuryBalance, expectedBalances.expectedAmmTreasuryBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
        assertLt(int256(expectedBalances.expectedPayoffAbs), TestConstants.TC_COLLATERAL_18DEC_INT);
    }

    function testShouldClosePositionDAIReceiveFixedWhenLiquidatorEarnedAndUserLostMoreThanCollateralBeforeMaturity18Decimals()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        ExpectedAmmTreasuryBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedAmmTreasuryBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 0;
        volumeSwaps.volumeReceiveFixedSwaps = 1;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        receiveFixedSwapIds[0] = 1;

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapReceiveFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1
        );
        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(address(itfLiquidator));
        actualBalances.actualAmmTreasuryBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(address(itfLiquidator)));
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            _iporProtocol.ammTreasury
        );
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualAmmTreasuryBalance, expectedBalances.expectedAmmTreasuryBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIReceiveFixedWhenLiquidatorEarnedAndUserLostBetween99And100PercentOfCollateralBeforeMaturity18Decimals()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_150_18DEC,
            block.timestamp
        );

        ExpectedAmmTreasuryBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = 9967706062166515074699;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedAmmTreasuryBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 0;
        volumeSwaps.volumeReceiveFixedSwaps = 1;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        receiveFixedSwapIds[0] = 1;

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(address(itfLiquidator));
        actualBalances.actualAmmTreasuryBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(address(itfLiquidator)));
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));

        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualAmmTreasuryBalance, expectedBalances.expectedAmmTreasuryBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);

        assertEq(soap, TestConstants.ZERO_INT);
        assertLt(int256(expectedBalances.expectedPayoffAbs), TestConstants.TC_COLLATERAL_18DEC_INT);
    }

    function testShouldClosePositionDAIReceiveFixedWhenLiquidatorLostAndUserEarnedMoreThanCollateralAfterMaturity18Decimals()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_159_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_159_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        ExpectedAmmTreasuryBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedAmmTreasuryBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 0;
        volumeSwaps.volumeReceiveFixedSwaps = 1;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        receiveFixedSwapIds[0] = 1;

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(address(itfLiquidator));
        actualBalances.actualAmmTreasuryBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(address(itfLiquidator)));
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));

        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualAmmTreasuryBalance, expectedBalances.expectedAmmTreasuryBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIReceiveFixedWhenLiquidatorLostAndUserEarnedLessThanCollateralAfterMaturity18Decimals()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_10_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        ExpectedAmmTreasuryBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = 682719593299076345445;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedAmmTreasuryBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 0;
        volumeSwaps.volumeReceiveFixedSwaps = 1;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        receiveFixedSwapIds[0] = 1;

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(address(itfLiquidator));
        actualBalances.actualAmmTreasuryBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(address(itfLiquidator)));
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualAmmTreasuryBalance, expectedBalances.expectedAmmTreasuryBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);

        assertEq(soap, TestConstants.ZERO_INT);
        assertLt(int256(expectedBalances.expectedPayoffAbs), TestConstants.TC_COLLATERAL_18DEC_INT);
    }

    function testShouldClosePositionDAIReceiveFixedWhenLiquidatorEarnedAndUserLostMoreThanCollateralAfterMaturity18Decimals()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        ExpectedAmmTreasuryBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedAmmTreasuryBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT *
            1e18 +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 0;
        volumeSwaps.volumeReceiveFixedSwaps = 1;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        receiveFixedSwapIds[0] = 1;

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(address(itfLiquidator));
        actualBalances.actualAmmTreasuryBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(address(itfLiquidator)));
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));

        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualAmmTreasuryBalance, expectedBalances.expectedAmmTreasuryBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);

        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIReceiveFixedWhenLiquidatorEarnedAndUserLostLessThanCollateralAfterMaturity18Decimals()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _cfg.assetManagementImplementation = address(new MockCaseBaseAssetManagement());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.ammStorage)
        );

        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_50_18DEC,
            block.timestamp
        );

        ExpectedAmmTreasuryBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = 6281020258351502682039;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedAmmTreasuryBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT *
            1e18 +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 0;
        volumeSwaps.volumeReceiveFixedSwaps = 1;

        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        receiveFixedSwapIds[0] = 1;

        _iporProtocol.ammTreasury.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(address(itfLiquidator));
        actualBalances.actualAmmTreasuryBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(address(itfLiquidator)));
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualAmmTreasuryBalance, expectedBalances.expectedAmmTreasuryBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
        assertLt(int256(expectedBalances.expectedPayoffAbs), TestConstants.TC_COLLATERAL_18DEC_INT);
    }
}
