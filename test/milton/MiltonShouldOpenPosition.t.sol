// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdt.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdc.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenDai.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase3MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase4MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase5MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/interfaces/types/MiltonTypes.sol";
import "../../contracts/interfaces/types/MiltonStorageTypes.sol";

contract MiltonShouldOpenPositionTest is
    Test,
    TestCommons,
    DataUtils,
    SwapUtils
{
    MockSpreadModel internal _miltonSpreadModel;
    MockTestnetTokenUsdt internal _usdtMockedToken;
    MockTestnetTokenUsdc internal _usdcMockedToken;
    MockTestnetTokenDai internal _daiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;

    function setUp() public {
        _miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.PERCENTAGE_4_18DEC, // 4%
            TestConstants.ZERO, 
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT
        );
        _usdtMockedToken = getTokenUsdt();
        _usdcMockedToken = getTokenUsdc();
        _daiMockedToken = getTokenDai();
        _ipTokenUsdt = getIpTokenUsdt(address(_usdtMockedToken));
        _ipTokenUsdc = getIpTokenUsdc(address(_usdcMockedToken));
        _ipTokenDai = getIpTokenDai(address(_daiMockedToken));
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
    }

	function testShouldOpenPositionPayFixedDAIWhenOwnerSimpleCase18Decimals() public {
		// given
		ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 5 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
		// when 
		vm.prank(_userTwo);
		mockCase0MiltonDai.itfOpenSwapPayFixed(block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.PERCENTAGE_6_18DEC, TestConstants.LEVERAGE_18DEC);
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
		uint256 actualOpenSwapsVolume;
		for (uint256 i = 0; i < swaps.length; i++) {
			if(swaps[i].state == 1){
				actualOpenSwapsVolume++;
			}
		}
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		// then
		assertEq(actualOpenSwapsVolume, 1);
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), TestConstants.USD_28_000_18DEC + TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC);
        assertEq(_daiMockedToken.balanceOf(_userTwo), 9990000 * TestConstants.D18);
        assertEq(balance.totalCollateralPayFixed, TestConstants.TC_COLLATERAL_18DEC);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, TestConstants.USD_28_000_18DEC + TestConstants.TC_OPENING_FEE_18DEC);
        assertEq(balance.treasury, TestConstants.ZERO);
        assertEq(TestConstants.USD_28_000_18DEC + TestConstants.USD_10_000_000_18DEC, _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo));
        assertEq(balance.totalCollateralPayFixed, TestConstants.TC_COLLATERAL_18DEC);
	}

	function testShouldOpenPositionPayFixedUSDTWhenOwnerSimpleCase6Decimals() public {
		// given
		ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_usdtMockedToken), 5 * 10 ** 16);
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
		// when 
		vm.prank(_userTwo);
		mockCase0MiltonUsdt.itfOpenSwapPayFixed(block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC, TestConstants.PERCENTAGE_6_18DEC, TestConstants.LEVERAGE_18DEC);
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
		uint256 actualOpenSwapsVolume;
		for (uint256 i = 0; i < swaps.length; i++) {
			if(swaps[i].state == 1){
				actualOpenSwapsVolume++;
			}
		}
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageUsdt.getExtendedBalance();
		// then
		assertEq(actualOpenSwapsVolume, 1);
		assertEq(_usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)), TestConstants.USD_28_000_6DEC + TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC);
        assertEq(_usdtMockedToken.balanceOf(_userTwo), 9990000000000);
        assertEq(balance.totalCollateralPayFixed, TestConstants.TC_COLLATERAL_18DEC);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, TestConstants.USD_28_000_18DEC + TestConstants.TC_OPENING_FEE_18DEC); 
        assertEq(balance.treasury, TestConstants.ZERO);
        assertEq(TestConstants.USD_28_000_6DEC + TestConstants.USD_10_000_000_6DEC, _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)) + _usdtMockedToken.balanceOf(_userTwo));
        assertEq(balance.totalCollateralPayFixed, TestConstants.TC_COLLATERAL_18DEC);
	}

	function testShouldOpenPositionPayFixedDAIWhenCustomOpeningFeeForTreasuryIs50Percent() public {
		// given
		ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 5 * 10 ** 16);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase4MiltonDai mockCase4MiltonDai = getMockCase4MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase4MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase4MiltonDai));
        prepareMilton(mockCase4MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
		// when 
		vm.prank(_userTwo);
		mockCase4MiltonDai.itfOpenSwapPayFixed(block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.PERCENTAGE_6_18DEC, TestConstants.LEVERAGE_18DEC);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		// then
        assertEq(balance.liquidityPool, 28002840597820653803859);
        assertEq(balance.treasury, 149505148455463361);
	}

	function testShouldOpenPositionPayFixedDAIWhenCustomOpeningFeeForTreasuryIs25Percent() public {
		// given
		ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 5 * 10 ** 16);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase5MiltonDai mockCase5MiltonDai = getMockCase5MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase5MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase5MiltonDai));
        prepareMilton(mockCase5MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
		// when 
		vm.prank(_userTwo);
		mockCase5MiltonDai.itfOpenSwapPayFixed(block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.PERCENTAGE_6_18DEC, TestConstants.LEVERAGE_18DEC);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		// then
        assertEq(balance.liquidityPool, 28002915350394881535539);
        assertEq(balance.treasury, 74752574227731681);
	}

    function testShouldOpenPayFixedDAIWhenCustomLeverageSimpleCase1() public {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        // when 
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, 9 * TestConstants.D17, 15125000000000000000);
        IporTypes.IporSwapMemory memory swapPayFixed = miltonStorageDai.getSwapPayFixed(1);
        // then
        assertEq(swapPayFixed.collateral, 9967009897030890732780);
        assertEq(swapPayFixed.notional, 150751024692592222333298);
    }

    function testShouldArraysHaveCorrectStateWhenOneUserOpensManyPositions() public {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 3 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(3 * TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // then
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsCount, uint256[] memory swapIds) =
            miltonStorageDai.getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swaps.length, 3);
        assertEq(swapIds.length, 3);
        assertEq(swapsCount, 3);
        assertEq(swaps[0].idsIndex, 0);
        assertEq(swaps[1].idsIndex, 1);
        assertEq(swaps[2].idsIndex, 2);
    }

    function testShouldArraysHaveCorrectStateWhenTwoUsersOpenPositions() public {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 3 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(3 * TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userThree,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // then
        (, IporTypes.IporSwapMemory[] memory swapsUserOne) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) =
            miltonStorageDai.getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swapsUserOne.length, 2);
        assertEq(swapsUserOneIds.length, 2);
        assertEq(swapsUserOneCount, 2);
        assertEq(swapsUserOne[0].idsIndex, 0);
        assertEq(swapsUserOne[0].id, 1);
        assertEq(swapsUserOne[1].idsIndex, 1);
        assertEq(swapsUserOne[1].id, 3);
        (, IporTypes.IporSwapMemory[] memory swapsUserTwo) =
            miltonStorageDai.getSwapsPayFixed(_userThree, TestConstants.ZERO, 10);
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) =
            miltonStorageDai.getSwapPayFixedIds(_userThree, TestConstants.ZERO, 10);
        assertEq(swapsUserTwo.length, 1);
        assertEq(swapsUserTwoIds.length, 1);
        assertEq(swapsUserTwoCount, 1);
        assertEq(swapsUserTwo[0].idsIndex, 0);
        assertEq(swapsUserTwo[0].id, 2);
    }

    function testShouldPositionArraysHaveCorrectIdsWhenTwoUsersOpenPositionsAndOnePositionIsClosed () public {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 3 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(3 * TestConstants.USD_28_000_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userThree,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // when
        vm.prank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(2, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        // then
        (, IporTypes.IporSwapMemory[] memory swapsUserOne) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) =
            miltonStorageDai.getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swapsUserOne.length, 2);
        assertEq(swapsUserOneIds.length, 2);
        assertEq(swapsUserOneCount, 2);
        assertEq(swapsUserOne[0].idsIndex, 0);
        assertEq(swapsUserOne[0].id, 1);
        assertEq(swapsUserOne[1].idsIndex, 1);
        assertEq(swapsUserOne[1].id, 3);
        (, IporTypes.IporSwapMemory[] memory swapsUserTwo) =
            miltonStorageDai.getSwapsPayFixed(_userThree, TestConstants.ZERO, 10);
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) =
            miltonStorageDai.getSwapPayFixedIds(_userThree, TestConstants.ZERO, 10);
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }

    function testShouldPositionArraysHaveCorrectIdsWhenTwoUsersOpenPositionsAndAllExceptOnePositionAreClosed () public {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 3 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(3 * TestConstants.USD_28_000_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userThree,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // when
        vm.prank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(2, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfCloseSwapPayFixed(3, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        // then
        (, IporTypes.IporSwapMemory[] memory swapsUserOne) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) =
            miltonStorageDai.getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swapsUserOne.length, 1);
        assertEq(swapsUserOneIds.length, 1);
        assertEq(swapsUserOneCount, 1);
        assertEq(swapsUserOne[0].idsIndex, 0);
        assertEq(swapsUserOne[0].id, 1);
        (, IporTypes.IporSwapMemory[] memory swapsUserTwo) =
            miltonStorageDai.getSwapsPayFixed(_userThree, TestConstants.ZERO, 10);
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) =
            miltonStorageDai.getSwapPayFixedIds(_userThree, TestConstants.ZERO, 10);
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }

    function testShouldFixLastByteDifferenceWhenTwoPositionsAreOpenedAndClosedAndArithmeticOverflowCase1() public {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 3 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // when
        vm.prank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        vm.prank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(2, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        // then
        (, IporTypes.IporSwapMemory[] memory swapsUserOne) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) =
            miltonStorageDai.getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swapsUserOne.length, 0);
        assertEq(swapsUserOneIds.length, 0);
        assertEq(swapsUserOneCount, 0);
        (, IporTypes.IporSwapMemory[] memory swapsUserTwo) =
            miltonStorageDai.getSwapsPayFixed(_userThree, TestConstants.ZERO, 10);
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) =
            miltonStorageDai.getSwapPayFixedIds(_userThree, TestConstants.ZERO, 10);
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }

    function testShouldFixLastByteDifferenceWhenTwoPositionsAreOpenedAndClosedAndArithmeticOverflowCase1Minus3() public {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 3 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS - 259200, // TestConstants.PERIOD_25_DAYS_IN_SECONDS - 3 days
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // when
        vm.prank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        vm.prank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(2, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        // then
        (, IporTypes.IporSwapMemory[] memory swapsUserOne) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) =
            miltonStorageDai.getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swapsUserOne.length, 0);
        assertEq(swapsUserOneIds.length, 0);
        assertEq(swapsUserOneCount, 0);
        (, IporTypes.IporSwapMemory[] memory swapsUserTwo) =
            miltonStorageDai.getSwapsPayFixed(_userThree, TestConstants.ZERO, 10);
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) =
            miltonStorageDai.getSwapPayFixedIds(_userThree, TestConstants.ZERO, 10);
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }

    function testShouldHaveLastByteDifferenceWhenTwoPositionsAreOpenedAndClosedAndArithmeticOverflowCase1() public {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 3 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        openSwapPayFixed(
            _userThree,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userThree,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // when
        vm.prank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        vm.prank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(2, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        // then
        (, IporTypes.IporSwapMemory[] memory swapsUserOne) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) =
            miltonStorageDai.getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swapsUserOne.length, 0);
        assertEq(swapsUserOneIds.length, 0);
        assertEq(swapsUserOneCount, 0);
        (, IporTypes.IporSwapMemory[] memory swapsUserTwo) =
            miltonStorageDai.getSwapsPayFixed(_userThree, TestConstants.ZERO, 10);
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) =
            miltonStorageDai.getSwapPayFixedIds(_userThree, TestConstants.ZERO, 10);
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }

}

