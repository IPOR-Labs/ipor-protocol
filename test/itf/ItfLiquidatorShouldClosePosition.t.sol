// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
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
import "../../contracts/interfaces/types/IporTypes.sol";

contract ItfLiquidatorShouldClosePositionTest is TestCommons, DataUtils {
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
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);
        vm.startPrank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(block.timestamp, TestConstants.USD_10_000_18DEC, TestConstants.PERCENTAGE_6_18DEC, TestConstants.LEVERAGE_18DEC);
        mockCase0MiltonDai.itfOpenSwapPayFixed(block.timestamp, TestConstants.USD_10_000_18DEC, TestConstants.PERCENTAGE_6_18DEC, TestConstants.LEVERAGE_18DEC);
        vm.stopPrank();
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;
        uint256[] memory payFixedSwapIds = new uint256[](2);
        payFixedSwapIds[0] = 1;
        payFixedSwapIds[1] = 2;
        uint256[] memory receiveFixedSwapIds = new uint256[](0);
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
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);
        vm.startPrank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapReceiveFixed(block.timestamp, TestConstants.USD_10_000_18DEC, TestConstants.D16, TestConstants.LEVERAGE_18DEC);
        mockCase0MiltonDai.itfOpenSwapReceiveFixed(block.timestamp, TestConstants.USD_10_000_18DEC, TestConstants.D16, TestConstants.LEVERAGE_18DEC);
        vm.stopPrank();
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;
        uint256[] memory payFixedSwapIds = new uint256[](0);
        uint256[] memory receiveFixedSwapIds = new uint256[](2);
        receiveFixedSwapIds[0] = 1;
        receiveFixedSwapIds[1] = 2;
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

    function testShouldClose10PayFixedSwapsAnd10ReceiveFixedSwapsInOneTransactionCase1WhenAllAreOpened() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase3MiltonDai mockCase3MiltonDai = getMockCase3MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
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
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity((volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) * TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.startPrank(_userTwo);
        for(uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i){
            mockCase3MiltonDai.itfOpenSwapPayFixed(block.timestamp, TestConstants.USD_10_000_18DEC, TestConstants.PERCENTAGE_6_18DEC, TestConstants.LEVERAGE_18DEC);
            payFixedSwapIds[i] = i + 1;
        }
        for(uint256 i = volumeSwaps.volumePayFixedSwaps; i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps; ++i){
            mockCase3MiltonDai.itfOpenSwapReceiveFixed(block.timestamp, TestConstants.USD_10_000_18DEC, TestConstants.D16, TestConstants.LEVERAGE_18DEC);
            receiveFixedSwapIds[i - volumeSwaps.volumePayFixedSwaps] = i + 1;
        }
        vm.stopPrank();
        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);
        // then
        for(uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i){
            IporTypes.IporSwapMemory memory iporPayFixedSwap = miltonStorageDai.getSwapPayFixed(i + 1);
            assertEq(iporPayFixedSwap.state, expectedSwapStatus);
        }
        for(uint256 i = volumeSwaps.volumePayFixedSwaps; i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps; ++i){
            IporTypes.IporSwapMemory memory iporReceiveFixedSwap = miltonStorageDai.getSwapReceiveFixed(i + 1);
            assertEq(iporReceiveFixedSwap.state, expectedSwapStatus);
        }
    }

    function testShouldClose5PayFixedSwapsAndLeaveAnother5OpenAndClose5ReceiveFixedSwapsAndLeaveAnother5OpenInOneTransactionCase2WhenSomeOfThemAreAlreadyClosedAndSomeExpired() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase3MiltonDai mockCase3MiltonDai = getMockCase3MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
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
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumePayFixedSwapsOpenLater);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps + volumeSwaps.volumeReceiveFixedSwapsOpenLater);
        uint256 openLaterTimestamp = block.timestamp + TestConstants.PERIOD_14_DAYS_IN_SECONDS;
        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;
        uint256 expectedSwapStatus = TestConstants.ZERO;
        uint256 expectedSwapStatusOpenLater = 1;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity((volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) * TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.startPrank(_userTwo);
        for(uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i){
            mockCase3MiltonDai.itfOpenSwapPayFixed(block.timestamp, TestConstants.USD_10_000_18DEC, TestConstants.PERCENTAGE_6_18DEC, TestConstants.LEVERAGE_18DEC);
            payFixedSwapIds[i] = i + 1;
        }
        for(uint256 i = volumeSwaps.volumePayFixedSwaps; i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps; ++i){
            mockCase3MiltonDai.itfOpenSwapReceiveFixed(block.timestamp, TestConstants.USD_10_000_18DEC, TestConstants.D16, TestConstants.LEVERAGE_18DEC);
            receiveFixedSwapIds[i - volumeSwaps.volumePayFixedSwaps] = i + 1;
        }
        for(uint256 i = volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps; i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps + volumeSwaps.volumePayFixedSwapsOpenLater; ++i){
            mockCase3MiltonDai.itfOpenSwapPayFixed(openLaterTimestamp, TestConstants.USD_10_000_18DEC, TestConstants.PERCENTAGE_6_18DEC, TestConstants.LEVERAGE_18DEC);
            payFixedSwapIds[i - volumeSwaps.volumeReceiveFixedSwaps] = i + 1;
        }
        for(uint256 i = volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps + volumeSwaps.volumePayFixedSwapsOpenLater; i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps + volumeSwaps.volumePayFixedSwapsOpenLater + volumeSwaps.volumeReceiveFixedSwapsOpenLater; ++i){
            mockCase3MiltonDai.itfOpenSwapReceiveFixed(openLaterTimestamp, TestConstants.USD_10_000_18DEC, TestConstants.D16, TestConstants.LEVERAGE_18DEC);
            receiveFixedSwapIds[i - (volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps)] = i + 1;
        }
        vm.stopPrank();
        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);
        // then
        for(uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i){
            IporTypes.IporSwapMemory memory iporPayFixedSwap = miltonStorageDai.getSwapPayFixed(i + 1);
            assertEq(iporPayFixedSwap.state, expectedSwapStatus);
        }
        for(uint256 i = volumeSwaps.volumePayFixedSwaps; i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps; ++i){
            IporTypes.IporSwapMemory memory iporReceiveFixedSwap = miltonStorageDai.getSwapReceiveFixed(i + 1);
            assertEq(iporReceiveFixedSwap.state, expectedSwapStatus);
        }
        for(uint256 i = volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps; i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps + volumeSwaps.volumePayFixedSwapsOpenLater; ++i){
            IporTypes.IporSwapMemory memory iporPayFixedSwapOpenedLater = miltonStorageDai.getSwapPayFixed(i + 1);
            assertEq(iporPayFixedSwapOpenedLater.state, expectedSwapStatusOpenLater);
        }
        for(uint256 i = volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps + volumeSwaps.volumePayFixedSwapsOpenLater; i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps + volumeSwaps.volumePayFixedSwapsOpenLater + volumeSwaps.volumeReceiveFixedSwapsOpenLater; ++i){
            IporTypes.IporSwapMemory memory iporReceiveFixedSwapOpenedLater = miltonStorageDai.getSwapReceiveFixed(i + 1);
            assertEq(iporReceiveFixedSwapOpenedLater.state, expectedSwapStatusOpenLater);
        }
    }

    function testShouldClose5PayFixedSwapsAndClose5ReceiveFixedSwapsInOneTransactionCase2WhenSomeOfThemAreAlreadyClosed() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase3MiltonDai mockCase3MiltonDai = getMockCase3MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity((volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) * TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.startPrank(_userTwo);
        for(uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i){
            mockCase3MiltonDai.itfOpenSwapPayFixed(block.timestamp, TestConstants.USD_10_000_18DEC, TestConstants.PERCENTAGE_6_18DEC, TestConstants.LEVERAGE_18DEC);
            payFixedSwapIds[i] = i + 1;
        }
        for(uint256 i = volumeSwaps.volumePayFixedSwaps; i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps; ++i){
            mockCase3MiltonDai.itfOpenSwapReceiveFixed(block.timestamp, TestConstants.USD_10_000_18DEC, TestConstants.D16, TestConstants.LEVERAGE_18DEC);
            receiveFixedSwapIds[i - volumeSwaps.volumePayFixedSwaps] = i + 1;
        }
        mockCase3MiltonDai.itfCloseSwapPayFixed(3, endTimestamp);
        mockCase3MiltonDai.itfCloseSwapReceiveFixed(8, endTimestamp);
        vm.stopPrank();
        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);
        // then
        for(uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i){
            IporTypes.IporSwapMemory memory iporPayFixedSwap = miltonStorageDai.getSwapPayFixed(i + 1);
            assertEq(iporPayFixedSwap.state, expectedSwapStatus);
        }
        for(uint256 i = volumeSwaps.volumePayFixedSwaps; i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps; ++i){
            IporTypes.IporSwapMemory memory iporReceiveFixedSwap = miltonStorageDai.getSwapReceiveFixed(i + 1);
            assertEq(iporReceiveFixedSwap.state, expectedSwapStatus);
        }
        IporTypes.IporSwapMemory memory closedPayFixedSwap = miltonStorageDai.getSwapPayFixed(3);
        assertEq(closedPayFixedSwap.state, expectedSwapStatus);
        IporTypes.IporSwapMemory memory closedReceiveFixedSwap = miltonStorageDai.getSwapReceiveFixed(8);
        assertEq(closedReceiveFixedSwap.state, expectedSwapStatus);
    }

    function testShouldClose10PayFixedSwapsAnd10ReceiveFixedSwapsInOneTransactionWhenLiquidationDepositAmountNotTransferredToLiquidator() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase3MiltonDai mockCase3MiltonDai = getMockCase3MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        VolumeSwaps memory volumeSwaps;
        volumeSwaps.volumePayFixedSwaps = 10;
        volumeSwaps.volumeReceiveFixedSwaps = 10;
        uint256 endTimestamp = block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS;
        uint256 expectedBalanceTrader = 9997046420320479199074790;
        uint256 expectedBalanceLiquidator =  (volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) * TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
        uint256[] memory payFixedSwapIds = new uint256[](volumeSwaps.volumePayFixedSwaps);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeSwaps.volumeReceiveFixedSwaps);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity((volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps) * TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.startPrank(_userTwo);
        for(uint256 i; i < volumeSwaps.volumePayFixedSwaps; ++i){
            mockCase3MiltonDai.itfOpenSwapPayFixed(block.timestamp, TestConstants.USD_10_000_18DEC, TestConstants.PERCENTAGE_6_18DEC, TestConstants.LEVERAGE_18DEC);
            payFixedSwapIds[i] = i + 1;
        }
        for(uint256 i = volumeSwaps.volumePayFixedSwaps; i < volumeSwaps.volumePayFixedSwaps + volumeSwaps.volumeReceiveFixedSwaps; ++i){
            mockCase3MiltonDai.itfOpenSwapReceiveFixed(block.timestamp, TestConstants.USD_10_000_18DEC, TestConstants.D16, TestConstants.LEVERAGE_18DEC);
            receiveFixedSwapIds[i - volumeSwaps.volumePayFixedSwaps] = i + 1;
        }
        vm.stopPrank();
        // when
        itfLiquidator.itfLiquidate(payFixedSwapIds, receiveFixedSwapIds, endTimestamp);
        // then
        uint256 actualBalanceLiquidator = _daiMockedToken.balanceOf(address(itfLiquidator));
        assertEq(actualBalanceLiquidator, expectedBalanceLiquidator);
        uint256 actualBalanceTrader = _daiMockedToken.balanceOf(address(_userTwo));
        assertEq(actualBalanceTrader, expectedBalanceTrader);
    }

}