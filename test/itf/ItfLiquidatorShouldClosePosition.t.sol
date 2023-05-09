// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/itf/ItfDataProvider.sol";
import "../../contracts/itf/types/ItfDataProviderTypes.sol";
import "../../contracts/itf/ItfLiquidator.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase3MiltonDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/interfaces/IIporRiskManagementOracle.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/interfaces/types/MiltonTypes.sol";

contract ItfLiquidatorShouldClosePositionTest is TestCommons, DataUtils, SwapUtils {
    MockSpreadModel internal _miltonSpreadModel;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;

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
        /// @notice asset amount after closing swap that has been transferred from Milton to the Buyer. Value represented in 18 decimals.
        uint256 transferredToBuyer,
        /// @notice asset amount after closing swap that has been transferred from Milton to the Liquidator. Value represented in 18 decimals.
        uint256 transferredToLiquidator,
        /// @notice incomeFeeValue value transferred to treasury
        uint256 incomeFeeValue
    );

    struct VolumeSwaps {
        uint256 volumePayFixedSwaps;
        uint256 volumeReceiveFixedSwaps;
        uint256 volumePayFixedSwapsOpenLater;
        uint256 volumeReceiveFixedSwapsOpenLater;
    }

    struct ActualBalances {
        uint256 actualIncomeFeeValue;
        uint256 actualSumOfBalances;
        uint256 actualMiltonBalance;
        int256 actualPayoff;
        int256 actualOpenerUserBalance;
        int256 actualCloserUserBalance;
    }

    function setUp() public {
        _miltonSpreadModel = new MockSpreadModel(
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT
        );
        _daiMockedToken = getTokenDai();
        _usdtMockedToken = getTokenUsdt();
        _usdcMockedToken = getTokenUsdc();
        _ipTokenDai = getIpTokenDai(address(_daiMockedToken));
        _ipTokenUsdt = getIpTokenUsdt(address(_usdtMockedToken));
        _ipTokenUsdc = getIpTokenUsdc(address(_usdcMockedToken));
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
    }

    function testShouldEmitCloseSwapEventWhenPayFixed() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );

        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );

        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();

        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );

        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase0MiltonDai),
            address(miltonStorageDai)
        );

        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );

        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));

        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);

        vm.startPrank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.USD_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.USD_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
        vm.stopPrank();

        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;
        uint256[] memory payFixedSwapIds = new uint256[](2);
        payFixedSwapIds[0] = 1;
        payFixedSwapIds[1] = 2;
        uint256[] memory receiveFixedSwapIds = new uint256[](0);

        mockCase0MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        vm.expectEmit(true, true, true, true);
        emit CloseSwap(
            1,
            address(_daiMockedToken),
            endTimestamp,
            address(itfLiquidator),
            18937318804358692392282,
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC,
            TestConstants.TC_INCOME_TAX_18DEC
        );

        vm.expectEmit(true, true, true, true);
        emit CloseSwap(
            2,
            address(_daiMockedToken),
            endTimestamp,
            address(itfLiquidator),
            18937318804358692392282,
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC,
            TestConstants.TC_INCOME_TAX_18DEC
        );

        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);
    }

    function testShouldEmitCloseSwapEventWhenReceiveFixed() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );

        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );

        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();

        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );

        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase0MiltonDai),
            address(miltonStorageDai)
        );

        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );

        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);

        vm.startPrank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.USD_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        mockCase0MiltonDai.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.USD_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
        vm.stopPrank();

        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;
        uint256[] memory payFixedSwapIds = new uint256[](0);
        uint256[] memory receiveFixedSwapIds = new uint256[](2);
        receiveFixedSwapIds[0] = 1;
        receiveFixedSwapIds[1] = 2;

        mockCase0MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        vm.expectEmit(true, true, true, true);
        emit CloseSwap(
            1,
            address(_daiMockedToken),
            endTimestamp,
            address(itfLiquidator),
            TestConstants.ZERO,
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC,
            TestConstants.TC_INCOME_TAX_18DEC
        );
        vm.expectEmit(true, true, true, true);
        emit CloseSwap(
            2,
            address(_daiMockedToken),
            endTimestamp,
            address(itfLiquidator),
            TestConstants.ZERO,
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC,
            TestConstants.TC_INCOME_TAX_18DEC
        );

        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);
    }

    function testShouldClose10PayFixedSwapsAnd10ReceiveFixedSwapsInOneTransactionCase1WhenAllAreOpened()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );

        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );

        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();

        MockCase3MiltonDai mockCase3MiltonDai = getMockCase3MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );

        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase3MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase3MiltonDai),
            address(miltonStorageDai)
        );

        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase3MiltonDai)
        );

        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));

        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 10;
        volumeSwaps.volumeReceiveFixedSwaps = 10;
        uint256 expectedSwapStatus = TestConstants.ZERO;
        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);

        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(
            (volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) *
                TestConstants.USD_28_000_18DEC,
            block.timestamp
        );

        vm.startPrank(_userTwo);
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            mockCase3MiltonDai.itfOpenSwapPayFixed(
                block.timestamp,
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
            mockCase3MiltonDai.itfOpenSwapReceiveFixed(
                block.timestamp,
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            receiveFixedSwapIds[i - volumeSwaps.volumePayFixedSwaps] = i + 1;
        }
        vm.stopPrank();

        mockCase3MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            IporTypes.IporSwapMemory memory iporPayFixedSwap = miltonStorageDai.getSwapPayFixed(
                i + 1
            );
            assertEq(iporPayFixedSwap.state, expectedSwapStatus);
        }

        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps;
            i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps;
            ++i
        ) {
            IporTypes.IporSwapMemory memory iporReceiveFixedSwap = miltonStorageDai
                .getSwapReceiveFixed(i + 1);
            assertEq(iporReceiveFixedSwap.state, expectedSwapStatus);
        }
    }

    function testShouldClose5PayFixedSwapsAndLeaveAnother5OpenAndClose5ReceiveFixedSwapsAndLeaveAnother5OpenInOneTransactionCase2WhenSomeOfThemAreAlreadyClosedAndSomeExpired()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );

        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );

        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();

        MockCase3MiltonDai mockCase3MiltonDai = getMockCase3MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );

        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase3MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase3MiltonDai),
            address(miltonStorageDai)
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

        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase3MiltonDai)
        );

        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));

        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(
            (volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) *
                TestConstants.USD_28_000_18DEC,
            block.timestamp
        );

        vm.startPrank(_userTwo);
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            mockCase3MiltonDai.itfOpenSwapPayFixed(
                block.timestamp,
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
            mockCase3MiltonDai.itfOpenSwapReceiveFixed(
                block.timestamp,
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
            mockCase3MiltonDai.itfOpenSwapPayFixed(
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
            mockCase3MiltonDai.itfOpenSwapReceiveFixed(
                openLaterTimestamp,
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            receiveFixedSwapIds[
                i - (volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps)
            ] = i + 1;
        }
        vm.stopPrank();

        mockCase3MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            IporTypes.IporSwapMemory memory iporPayFixedSwap = miltonStorageDai.getSwapPayFixed(
                i + 1
            );
            assertEq(iporPayFixedSwap.state, expectedSwapStatus);
        }
        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps;
            i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps;
            ++i
        ) {
            IporTypes.IporSwapMemory memory iporReceiveFixedSwap = miltonStorageDai
                .getSwapReceiveFixed(i + 1);
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
            IporTypes.IporSwapMemory memory iporPayFixedSwapOpenedLater = miltonStorageDai
                .getSwapPayFixed(i + 1);
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
            IporTypes.IporSwapMemory memory iporReceiveFixedSwapOpenedLater = miltonStorageDai
                .getSwapReceiveFixed(i + 1);
            assertEq(iporReceiveFixedSwapOpenedLater.state, expectedSwapStatusOpenLater);
        }
    }

    function testShouldClose5PayFixedSwapsAndClose5ReceiveFixedSwapsInOneTransactionCase2WhenSomeOfThemAreAlreadyClosed()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );

        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );

        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();

        MockCase3MiltonDai mockCase3MiltonDai = getMockCase3MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );

        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase3MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase3MiltonDai),
            address(miltonStorageDai)
        );

        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 5;
        volumeSwaps.volumeReceiveFixedSwaps = 5;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;
        uint256 expectedSwapStatus = TestConstants.ZERO;

        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase3MiltonDai)
        );

        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));

        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(
            (volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) *
                TestConstants.USD_28_000_18DEC,
            block.timestamp
        );

        vm.startPrank(_userTwo);
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            mockCase3MiltonDai.itfOpenSwapPayFixed(
                block.timestamp,
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
            mockCase3MiltonDai.itfOpenSwapReceiveFixed(
                block.timestamp,
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            receiveFixedSwapIds[i - volumeSwaps.volumePayFixedSwaps] = i + 1;
        }

        mockCase3MiltonDai.itfCloseSwapPayFixed(3, endTimestamp);
        mockCase3MiltonDai.itfCloseSwapReceiveFixed(8, endTimestamp);
        vm.stopPrank();

        mockCase3MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            IporTypes.IporSwapMemory memory iporPayFixedSwap = miltonStorageDai.getSwapPayFixed(
                i + 1
            );
            assertEq(iporPayFixedSwap.state, expectedSwapStatus);
        }
        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps;
            i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps;
            ++i
        ) {
            IporTypes.IporSwapMemory memory iporReceiveFixedSwap = miltonStorageDai
                .getSwapReceiveFixed(i + 1);
            assertEq(iporReceiveFixedSwap.state, expectedSwapStatus);
        }
        IporTypes.IporSwapMemory memory closedPayFixedSwap = miltonStorageDai.getSwapPayFixed(3);
        assertEq(closedPayFixedSwap.state, expectedSwapStatus);
        IporTypes.IporSwapMemory memory closedReceiveFixedSwap = miltonStorageDai
            .getSwapReceiveFixed(8);
        assertEq(closedReceiveFixedSwap.state, expectedSwapStatus);
    }

    function testShouldClose10PayFixedSwapsAnd10ReceiveFixedSwapsInOneTransactionWhenLiquidationDepositAmountNotTransferredToLiquidator()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase3MiltonDai mockCase3MiltonDai = getMockCase3MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase3MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase3MiltonDai),
            address(miltonStorageDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase3MiltonDai)
        );
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 10;
        volumeSwaps.volumeReceiveFixedSwaps = 10;
        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;
        uint256 expectedBalanceTrader = 9997046420320479199074780;
        uint256 expectedBalanceLiquidator = (volumeSwaps.volumePayFixedSwaps +
            volumeSwaps.volumeReceiveFixedSwaps) *
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(
            (volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) *
                TestConstants.USD_28_000_18DEC,
            block.timestamp
        );
        vm.startPrank(_userTwo);
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            mockCase3MiltonDai.itfOpenSwapPayFixed(
                block.timestamp,
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
            mockCase3MiltonDai.itfOpenSwapReceiveFixed(
                block.timestamp,
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            receiveFixedSwapIds[i - volumeSwaps.volumePayFixedSwaps] = i + 1;
        }
        vm.stopPrank();

        mockCase3MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);
        // then
        uint256 actualBalanceLiquidator = _daiMockedToken.balanceOf(address(itfLiquidator));
        assertEq(actualBalanceLiquidator, expectedBalanceLiquidator);
        uint256 actualBalanceTrader = _daiMockedToken.balanceOf(address(_userTwo));
        assertEq(actualBalanceTrader, expectedBalanceTrader);
    }

    function testShouldClose2PayFixedAnd0ReceiveFixedPositionsInOneTransactionWhenAllReceiveFixedPositionsAreAlreadyClosed()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase3MiltonDai mockCase3MiltonDai = getMockCase3MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase3MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase3MiltonDai),
            address(miltonStorageDai)
        );
        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 10;
        volumeSwaps.volumeReceiveFixedSwaps = 10;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;
        uint256 expectedBalanceTrader = 9997246420320479199074780;
        uint256 expectedBalanceLiquidator = volumeSwaps.volumePayFixedSwaps *
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase3MiltonDai)
        );
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(
            (volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) *
                TestConstants.USD_28_000_18DEC,
            block.timestamp
        );
        vm.startPrank(_userTwo);
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            mockCase3MiltonDai.itfOpenSwapPayFixed(
                block.timestamp,
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
            mockCase3MiltonDai.itfOpenSwapReceiveFixed(
                block.timestamp,
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
            mockCase3MiltonDai.itfCloseSwapReceiveFixed(i + 1, endTimestamp);
        }
        vm.stopPrank();

        mockCase3MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        uint256 actualBalanceLiquidator = _daiMockedToken.balanceOf(address(itfLiquidator));
        assertEq(actualBalanceLiquidator, expectedBalanceLiquidator);
        uint256 actualBalanceTrader = _daiMockedToken.balanceOf(address(_userTwo));
        assertEq(actualBalanceTrader, expectedBalanceTrader);
    }

    function testShouldClose0PayFixedAnd2ReceiveFixedPositionsInOneTransactionWhenAllPayFixedPositionsAreAlreadyClosed()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );

        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );

        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();

        MockCase3MiltonDai mockCase3MiltonDai = getMockCase3MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );

        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase3MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase3MiltonDai),
            address(miltonStorageDai)
        );

        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 10;
        volumeSwaps.volumeReceiveFixedSwaps = 10;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;
        uint256 expectedBalanceTrader = 9997046420320479199074780;
        uint256 expectedBalanceLiquidator = volumeSwaps.volumeReceiveFixedSwaps *
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;

        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase3MiltonDai)
        );
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));

        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(
            (volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) *
                TestConstants.USD_28_000_18DEC,
            block.timestamp
        );

        vm.startPrank(_userTwo);
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            mockCase3MiltonDai.itfOpenSwapPayFixed(
                block.timestamp,
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
            mockCase3MiltonDai.itfOpenSwapReceiveFixed(
                block.timestamp,
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            receiveFixedSwapIds[i - volumeSwaps.volumePayFixedSwaps] = i + 1;
        }
        vm.stopPrank();

        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            mockCase3MiltonDai.itfCloseSwapPayFixed(i + 1, endTimestamp);
        }

        mockCase3MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        uint256 actualBalanceLiquidator = _daiMockedToken.balanceOf(address(itfLiquidator));
        assertEq(
            actualBalanceLiquidator,
            expectedBalanceLiquidator,
            "actualBalanceLiquidator != expectedBalanceLiquidator"
        );
        uint256 actualBalanceTrader = _daiMockedToken.balanceOf(address(_userTwo));
        assertEq(
            actualBalanceTrader,
            expectedBalanceTrader,
            "actualBalanceTrader != expectedBalanceTrader"
        );
    }

    function testShouldCommitTransactionWhenTryToClose2PayFixedSwapsAnd2ReceiveFixedSwapsInOneTransactionWhenAllPositionsAreAlreadyClosed()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase3MiltonDai mockCase3MiltonDai = getMockCase3MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase3MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase3MiltonDai),
            address(miltonStorageDai)
        );
        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 2;
        volumeSwaps.volumeReceiveFixedSwaps = 2;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;
        uint256 expectedBalanceLiquidator = 0;
        uint256 expectedBalanceTrader = 9999489284064095839814956;
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase3MiltonDai)
        );
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(
            (volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) *
                TestConstants.USD_28_000_18DEC,
            block.timestamp
        );
        vm.startPrank(_userTwo);
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            mockCase3MiltonDai.itfOpenSwapPayFixed(
                block.timestamp,
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
            mockCase3MiltonDai.itfOpenSwapReceiveFixed(
                block.timestamp,
                TestConstants.USD_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            receiveFixedSwapIds[i - volumeSwaps.volumePayFixedSwaps] = i + 1;
        }
        for (uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i) {
            mockCase3MiltonDai.itfCloseSwapPayFixed(i + 1, endTimestamp);
        }
        for (
            uint256 i = volumeSwaps.volumePayFixedSwaps;
            i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps;
            ++i
        ) {
            mockCase3MiltonDai.itfCloseSwapReceiveFixed(i + 1, endTimestamp);
        }
        vm.stopPrank();

        mockCase3MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        uint256 actualBalanceLiquidator = _daiMockedToken.balanceOf(address(itfLiquidator));
        assertEq(actualBalanceLiquidator, expectedBalanceLiquidator);
        uint256 actualBalanceTrader = _daiMockedToken.balanceOf(address(_userTwo));
        assertEq(actualBalanceTrader, expectedBalanceTrader);
    }

    function testShouldCommitTransactionEvenIfListsForClosingAreEmpty() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase3MiltonDai mockCase3MiltonDai = getMockCase3MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase3MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase3MiltonDai),
            address(miltonStorageDai)
        );
        uint256[] memory payFixedSwapIds = new uint256[](TestConstants.ZERO);
        uint256[] memory receiveFixedSwapIds = new uint256[](TestConstants.ZERO);
        uint256 endTimestamp = block.timestamp;
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase3MiltonDai)
        );
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        // when
        (
            MiltonTypes.IporSwapClosingResult[] memory payFixedClosedSwaps,
            MiltonTypes.IporSwapClosingResult[] memory receiveFixedClosedSwaps
        ) = itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);
        // then
        assertEq(payFixedClosedSwaps.length, TestConstants.ZERO);
        assertEq(receiveFixedClosedSwaps.length, TestConstants.ZERO);
    }

    function testShouldClosePositionDAIPayFixedWhenLiquidatorLostAndUserEarnedMoreThanCollateralBeforeMaturity18Decimals()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_1_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase0MiltonDai),
            address(miltonStorageDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs) +
            int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs +
            expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants
            .TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
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

        mockCase0MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            endTimestamp,
            1
        );
        actualBalances.actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(
            actualBalances.actualPayoff
        );
        actualBalances.actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(address(itfLiquidator));
        actualBalances.actualMiltonBalance = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        actualBalances.actualOpenerUserBalance = int256(_daiMockedToken.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(
            _daiMockedToken.balanceOf(address(itfLiquidator))
        );
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(
            actualBalances.actualSumOfBalances,
            expectedBalances.expectedSumOfBalancesBeforePayout
        );
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(
            actualBalances.actualOpenerUserBalance,
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(
            actualBalances.actualCloserUserBalance,
            expectedBalances.expectedCloserUserBalance
        );
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIPayFixedWhenLiquidatorLostAndUserEarnedBetween99And100PercentOfCollateralBeforeMaturity18Decimals()
        public
    {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase0MiltonDai),
            address(miltonStorageDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_151_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 9898742705955336652531;
        expectedBalances.expectedIncomeFeeValue = 989874270595533665253;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs) +
            int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs +
            expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants
            .TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
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

        mockCase0MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            endTimestamp,
            1
        );
        actualBalances.actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(
            actualBalances.actualPayoff
        );
        actualBalances.actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(address(itfLiquidator));
        actualBalances.actualMiltonBalance = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        actualBalances.actualOpenerUserBalance = int256(_daiMockedToken.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(
            _daiMockedToken.balanceOf(address(itfLiquidator))
        );
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(
            actualBalances.actualSumOfBalances,
            expectedBalances.expectedSumOfBalancesBeforePayout
        );
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(
            actualBalances.actualOpenerUserBalance,
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(
            actualBalances.actualCloserUserBalance,
            expectedBalances.expectedCloserUserBalance
        );
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(soap, TestConstants.ZERO_INT);
        assertLt(int256(expectedBalances.expectedPayoffAbs), TestConstants.TC_COLLATERAL_18DEC_INT);
    }

    function testShouldClosePositionDAIPayFixedWhenLiquidatorLostAndUserEarnedMoreThanCollateralAfterMaturity18Decimals()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_1_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase0MiltonDai),
            address(miltonStorageDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs) +
            int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs +
            expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants
            .TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
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

        mockCase0MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            endTimestamp,
            1
        );
        actualBalances.actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(
            actualBalances.actualPayoff
        );
        actualBalances.actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(address(itfLiquidator));
        actualBalances.actualMiltonBalance = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        actualBalances.actualOpenerUserBalance = int256(_daiMockedToken.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(
            _daiMockedToken.balanceOf(address(itfLiquidator))
        );
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(
            actualBalances.actualSumOfBalances,
            expectedBalances.expectedSumOfBalancesBeforePayout
        );
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(
            actualBalances.actualOpenerUserBalance,
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(
            actualBalances.actualCloserUserBalance,
            expectedBalances.expectedCloserUserBalance
        );
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIPayFixedWhenLiquidatorLostAndUserEarnedLessThanCollateralAfterMaturity18Decimals()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase0MiltonDai),
            address(miltonStorageDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_50_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 6007512814648756073133;
        expectedBalances.expectedIncomeFeeValue = 600751281464875607313;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs) +
            int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs +
            expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants
            .TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
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

        mockCase0MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            endTimestamp,
            1
        );
        actualBalances.actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(
            actualBalances.actualPayoff
        );
        actualBalances.actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(address(itfLiquidator));
        actualBalances.actualMiltonBalance = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        actualBalances.actualOpenerUserBalance = int256(_daiMockedToken.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(
            _daiMockedToken.balanceOf(address(itfLiquidator))
        );
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(
            actualBalances.actualSumOfBalances,
            expectedBalances.expectedSumOfBalancesBeforePayout
        );
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(
            actualBalances.actualOpenerUserBalance,
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(
            actualBalances.actualCloserUserBalance,
            expectedBalances.expectedCloserUserBalance
        );
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(soap, TestConstants.ZERO_INT);
        assertLt(int256(expectedBalances.expectedPayoffAbs), TestConstants.TC_COLLATERAL_18DEC_INT);
    }

    function testShouldClosePositionDAIPayFixedWhenLiquidatorEarnedAndUserLostMoreThanCollateralBeforeMaturity18Decimals()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_161_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_160_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase0MiltonDai),
            address(miltonStorageDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_161_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants
            .TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs -
            expectedBalances.expectedIncomeFeeValue;
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

        mockCase0MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1
        );
        actualBalances.actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(
            actualBalances.actualPayoff
        );
        actualBalances.actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(address(itfLiquidator));
        actualBalances.actualMiltonBalance = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        actualBalances.actualOpenerUserBalance = int256(_daiMockedToken.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(
            _daiMockedToken.balanceOf(address(itfLiquidator))
        );
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            mockCase0MiltonDai
        );
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(
            actualBalances.actualSumOfBalances,
            expectedBalances.expectedSumOfBalancesBeforePayout
        );
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(
            actualBalances.actualOpenerUserBalance,
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(
            actualBalances.actualCloserUserBalance,
            expectedBalances.expectedCloserUserBalance
        );
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIPayFixedWhenLiquidatorEarnedAndUserLostBetween99And100PercentOfCollateralBeforeMaturity18Decimals()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_151_18DEC);

        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_150_EMA_18DEC_64UINT
        );

        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );

        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();

        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );

        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase0MiltonDai),
            address(miltonStorageDai)
        );

        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );

        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_151_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );

        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_6_18DEC,
            block.timestamp
        );

        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 9898742705955336727625;
        expectedBalances.expectedIncomeFeeValue = 989874270595533672763;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants
            .TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs -
            expectedBalances.expectedIncomeFeeValue;
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

        mockCase0MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            endTimestamp,
            1
        );
        actualBalances.actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(
            actualBalances.actualPayoff
        );
        actualBalances.actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(address(itfLiquidator));
        actualBalances.actualMiltonBalance = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        actualBalances.actualOpenerUserBalance = int256(_daiMockedToken.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(
            _daiMockedToken.balanceOf(address(itfLiquidator))
        );
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(
            actualBalances.actualSumOfBalances,
            expectedBalances.expectedSumOfBalancesBeforePayout
        );
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(
            actualBalances.actualOpenerUserBalance,
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(
            actualBalances.actualCloserUserBalance,
            expectedBalances.expectedCloserUserBalance
        );
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(soap, TestConstants.ZERO_INT);
        assertLt(int256(expectedBalances.expectedPayoffAbs), TestConstants.TC_COLLATERAL_18DEC_INT);
    }

    function testShouldClosePositionDAIPayFixedWhenLiquidatorEarnedAndUserLostLessThanCollateralAfterMaturity18Decimals()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_10_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_120_EMA_18DEC_64UINT
        );

        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );

        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();

        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );

        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase0MiltonDai),
            address(miltonStorageDai)
        );

        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );

        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );

        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 682671910755540429746;
        expectedBalances.expectedIncomeFeeValue = 68267191075554042975;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT *
            Constants.D18_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants
            .TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs -
            expectedBalances.expectedIncomeFeeValue;
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

        mockCase0MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            endTimestamp,
            1
        );
        actualBalances.actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(
            actualBalances.actualPayoff
        );
        actualBalances.actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(address(itfLiquidator));
        actualBalances.actualMiltonBalance = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        actualBalances.actualOpenerUserBalance = int256(_daiMockedToken.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(
            _daiMockedToken.balanceOf(address(itfLiquidator))
        );
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(
            actualBalances.actualSumOfBalances,
            expectedBalances.expectedSumOfBalancesBeforePayout
        );
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(
            actualBalances.actualOpenerUserBalance,
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(
            actualBalances.actualCloserUserBalance,
            expectedBalances.expectedCloserUserBalance
        );
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIPayFixedWhenLiquidatorEarnedAndUserLostMoreThanCollateralAfterMaturity18Decimals()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_161_18DEC);

        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_160_EMA_18DEC_64UINT
        );

        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );

        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );

        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase0MiltonDai),
            address(miltonStorageDai)
        );

        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );

        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_161_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );

        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT *
            Constants.D18_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants
            .TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs -
            expectedBalances.expectedIncomeFeeValue;
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

        mockCase0MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            endTimestamp,
            1
        );
        actualBalances.actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(
            actualBalances.actualPayoff
        );
        actualBalances.actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(address(itfLiquidator));
        actualBalances.actualMiltonBalance = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        actualBalances.actualOpenerUserBalance = int256(_daiMockedToken.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(
            _daiMockedToken.balanceOf(address(itfLiquidator))
        );
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(
            actualBalances.actualSumOfBalances,
            expectedBalances.expectedSumOfBalancesBeforePayout
        );
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(
            actualBalances.actualOpenerUserBalance,
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(
            actualBalances.actualCloserUserBalance,
            expectedBalances.expectedCloserUserBalance
        );
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIReceiveFixedWhenLiquidatorLostAndUserEarnedBetween99And100PercentOfCollateralBeforeMaturity18Decimals()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_150_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_151_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase0MiltonDai),
            address(miltonStorageDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_150_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 9898742705955336720799;
        expectedBalances.expectedIncomeFeeValue = 989874270595533672080;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs) +
            int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs +
            expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants
            .TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
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

        mockCase0MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(
            endTimestamp,
            1
        );
        actualBalances.actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(
            actualBalances.actualPayoff
        );
        actualBalances.actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(address(itfLiquidator));
        actualBalances.actualMiltonBalance = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        actualBalances.actualOpenerUserBalance = int256(_daiMockedToken.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(
            _daiMockedToken.balanceOf(address(itfLiquidator))
        );
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(
            actualBalances.actualSumOfBalances,
            expectedBalances.expectedSumOfBalancesBeforePayout
        );
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(
            actualBalances.actualOpenerUserBalance,
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(
            actualBalances.actualCloserUserBalance,
            expectedBalances.expectedCloserUserBalance
        );
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(soap, TestConstants.ZERO_INT);
        assertLt(int256(expectedBalances.expectedPayoffAbs), TestConstants.TC_COLLATERAL_18DEC_INT);
    }

    function testShouldClosePositionDAIReceiveFixedWhenLiquidatorEarnedAndUserLostMoreThanCollateralBeforeMaturity18Decimals()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase0MiltonDai),
            address(miltonStorageDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants
            .TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs -
            expectedBalances.expectedIncomeFeeValue;
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

        mockCase0MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1
        );
        actualBalances.actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(
            actualBalances.actualPayoff
        );
        actualBalances.actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(address(itfLiquidator));
        actualBalances.actualMiltonBalance = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        actualBalances.actualOpenerUserBalance = int256(_daiMockedToken.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(
            _daiMockedToken.balanceOf(address(itfLiquidator))
        );
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            mockCase0MiltonDai
        );
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(
            actualBalances.actualSumOfBalances,
            expectedBalances.expectedSumOfBalancesBeforePayout
        );
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(
            actualBalances.actualOpenerUserBalance,
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(
            actualBalances.actualCloserUserBalance,
            expectedBalances.expectedCloserUserBalance
        );
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIReceiveFixedWhenLiquidatorEarnedAndUserLostBetween99And100PercentOfCollateralBeforeMaturity18Decimals()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase0MiltonDai),
            address(miltonStorageDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_150_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 9967009897030890705473;
        expectedBalances.expectedIncomeFeeValue = 996700989703089070547;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants
            .TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs -
            expectedBalances.expectedIncomeFeeValue;
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

        mockCase0MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(
            endTimestamp,
            1
        );
        actualBalances.actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(
            actualBalances.actualPayoff
        );
        actualBalances.actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(address(itfLiquidator));
        actualBalances.actualMiltonBalance = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        actualBalances.actualOpenerUserBalance = int256(_daiMockedToken.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(
            _daiMockedToken.balanceOf(address(itfLiquidator))
        );
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(
            actualBalances.actualSumOfBalances,
            expectedBalances.expectedSumOfBalancesBeforePayout
        );
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(
            actualBalances.actualOpenerUserBalance,
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(
            actualBalances.actualCloserUserBalance,
            expectedBalances.expectedCloserUserBalance
        );
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(soap, TestConstants.ZERO_INT);
        assertLt(int256(expectedBalances.expectedPayoffAbs), TestConstants.TC_COLLATERAL_18DEC_INT);
    }

    function testShouldClosePositionDAIReceiveFixedWhenLiquidatorLostAndUserEarnedMoreThanCollateralAfterMaturity18Decimals()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_159_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_160_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase0MiltonDai),
            address(miltonStorageDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_159_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs) +
            int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs +
            expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants
            .TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
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

        mockCase0MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(
            endTimestamp,
            1
        );
        actualBalances.actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(
            actualBalances.actualPayoff
        );
        actualBalances.actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(address(itfLiquidator));
        actualBalances.actualMiltonBalance = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        actualBalances.actualOpenerUserBalance = int256(_daiMockedToken.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(
            _daiMockedToken.balanceOf(address(itfLiquidator))
        );
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(
            actualBalances.actualSumOfBalances,
            expectedBalances.expectedSumOfBalancesBeforePayout
        );
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(
            actualBalances.actualOpenerUserBalance,
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(
            actualBalances.actualCloserUserBalance,
            expectedBalances.expectedCloserUserBalance
        );
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIReceiveFixedWhenLiquidatorLostAndUserEarnedLessThanCollateralAfterMaturity18Decimals()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_10_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_120_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase0MiltonDai),
            address(miltonStorageDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 682671910755540429746;
        expectedBalances.expectedIncomeFeeValue = 68267191075554042975;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs) +
            int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs +
            expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants
            .TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
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

        mockCase0MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(
            endTimestamp,
            1
        );
        actualBalances.actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(
            actualBalances.actualPayoff
        );
        actualBalances.actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(address(itfLiquidator));
        actualBalances.actualMiltonBalance = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        actualBalances.actualOpenerUserBalance = int256(_daiMockedToken.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(
            _daiMockedToken.balanceOf(address(itfLiquidator))
        );
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(
            actualBalances.actualSumOfBalances,
            expectedBalances.expectedSumOfBalancesBeforePayout
        );
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(
            actualBalances.actualOpenerUserBalance,
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(
            actualBalances.actualCloserUserBalance,
            expectedBalances.expectedCloserUserBalance
        );
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(soap, TestConstants.ZERO_INT);
        assertLt(int256(expectedBalances.expectedPayoffAbs), TestConstants.TC_COLLATERAL_18DEC_INT);
    }

    function testShouldClosePositionDAIReceiveFixedWhenLiquidatorEarnedAndUserLostMoreThanCollateralAfterMaturity18Decimals()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase0MiltonDai),
            address(miltonStorageDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT *
            Constants.D18_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants
            .TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs -
            expectedBalances.expectedIncomeFeeValue;
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

        mockCase0MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(
            endTimestamp,
            1
        );
        actualBalances.actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(
            actualBalances.actualPayoff
        );
        actualBalances.actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(address(itfLiquidator));
        actualBalances.actualMiltonBalance = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        actualBalances.actualOpenerUserBalance = int256(_daiMockedToken.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(
            _daiMockedToken.balanceOf(address(itfLiquidator))
        );
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(
            actualBalances.actualSumOfBalances,
            expectedBalances.expectedSumOfBalancesBeforePayout
        );
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(
            actualBalances.actualOpenerUserBalance,
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(
            actualBalances.actualCloserUserBalance,
            expectedBalances.expectedCloserUserBalance
        );
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIReceiveFixedWhenLiquidatorEarnedAndUserLostLessThanCollateralAfterMaturity18Decimals()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        ItfLiquidator itfLiquidator = new ItfLiquidator(
            address(mockCase0MiltonDai),
            address(miltonStorageDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_50_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 6280581578950972257592;
        expectedBalances.expectedIncomeFeeValue = 628058157895097225759;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT *
            Constants.D18_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants
            .TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs -
            expectedBalances.expectedIncomeFeeValue;
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

        mockCase0MiltonDai.addSwapLiquidator(address(itfLiquidator));

        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(
            endTimestamp,
            1
        );
        actualBalances.actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(
            actualBalances.actualPayoff
        );
        actualBalances.actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(address(itfLiquidator));
        actualBalances.actualMiltonBalance = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        actualBalances.actualOpenerUserBalance = int256(_daiMockedToken.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(
            _daiMockedToken.balanceOf(address(itfLiquidator))
        );
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(
            actualBalances.actualSumOfBalances,
            expectedBalances.expectedSumOfBalancesBeforePayout
        );
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(
            actualBalances.actualOpenerUserBalance,
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(
            actualBalances.actualCloserUserBalance,
            expectedBalances.expectedCloserUserBalance
        );
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(soap, TestConstants.ZERO_INT);
        assertLt(int256(expectedBalances.expectedPayoffAbs), TestConstants.TC_COLLATERAL_18DEC_INT);
    }
}
