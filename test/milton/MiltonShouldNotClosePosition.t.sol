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
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/interfaces/types/MiltonTypes.sol";
import "../../contracts/interfaces/types/MiltonStorageTypes.sol";

contract MiltonShouldNotClosePositionTest is
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
    address internal _admin;
    address internal _userOne;
    address internal _userTwo;
    address internal _userThree;
    address internal _liquidityProvider;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        _miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.ZERO,
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

	function testShouldNotClosePositionPayFixedDAIWhenNotOwnerAndMiltonLostAndUserEarnedLessThanCollateralBeforeMaturity() public {
		// given
		_miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
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
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_120_18DEC, block.timestamp);
				vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
		// when
		vm.expectRevert("IPOR_321");
		vm.prank(_userThree);
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
	}

	function testShouldNotClosePositionPayFixedDAIWhenNotOwnerAndMiltonLostAndUserEarnedLessThanCollateral7HoursBeforeMaturity() public {
		// given
		_miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
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
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_120_18DEC, block.timestamp);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp + TestConstants.PERIOD_27_DAYS_17_HOURS_IN_SECONDS);
		// when
		vm.expectRevert("IPOR_321");
		vm.prank(_userThree);
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_27_DAYS_17_HOURS_IN_SECONDS);
	}

	function testShouldNotClosePositionPayFixedDAIWhenNotOwnerAndMiltonEarbedAndUserLostLessThanCollateralBeforeMaturity() public {
		// given
		_miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_121_18DEC);
		ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 120 * 10 ** 16);
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
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_120_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_121_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp + TestConstants.PERIOD_27_DAYS_17_HOURS_IN_SECONDS);
		// when
		vm.expectRevert("IPOR_321");
		vm.prank(_userThree);
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_27_DAYS_17_HOURS_IN_SECONDS);
	}

	function testShouldNotClosePositionReceiveFixedDAIWhenNotOwnerAndMiltonLostAndUserEarnedLessThanCollateralBeforeMaturity() public {
		// given
		_miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_119_18DEC);
		ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 120 * 10 ** 16);
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
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_120_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
		// when
		vm.expectRevert("IPOR_321");
		vm.prank(_userThree);
		mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
	}

	function testShouldNotClosePositionReceiveFixedDAIWhenNotOwnerAndMiltonLostAndUserEarnedLessThanCollateral7HoursBeforeMaturity() public {
		// given
		_miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_119_18DEC);
		ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 120 * 10 ** 16);
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
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_120_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp + TestConstants.PERIOD_27_DAYS_17_HOURS_IN_SECONDS);
		// when
		vm.expectRevert("IPOR_321");
		vm.prank(_userThree);
		mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + TestConstants.PERIOD_27_DAYS_17_HOURS_IN_SECONDS);
	}

	function testShouldNotClosePositionReceiveFixedDAIWhenNotOwnerAndMiltonEarnedAndUserLostLessThanCollateral7HoursBeforeMaturity() public {
		// given
		_miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
		ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 120 * 10 ** 16);
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
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_120_18DEC, block.timestamp);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
		// when
		vm.expectRevert("IPOR_321");
		vm.prank(_userThree);
		mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
	}

	function testShouldNotClosePositionPayFixedWhenIncorrectSwapId() public {
		// given
		_miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
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
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
		// when
		vm.expectRevert("IPOR_306");
		vm.prank(_userThree);
		mockCase0MiltonDai.itfCloseSwapPayFixed(0, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
	}

	function testShouldNotClosePositionPayFixedWhenIncorrectStatus() public {
		// given
		_miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
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
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
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
		vm.expectRevert("IPOR_307");
		vm.prank(_userThree);
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
	}

	function testShouldNotClosePositionReceiveFixedWhenIncorrectStatus() public {
		_miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
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
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
		// when
		vm.prank(_userThree);
		mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
		vm.expectRevert("IPOR_307");
		vm.prank(_userThree);
		mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
	}

	function testShouldNotClosepositionWhenSwapDoesNotExist() public {
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
		prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		// when
		vm.expectRevert("IPOR_306");
		vm.prank(_userThree);
		mockCase0MiltonDai.itfCloseSwapPayFixed(0, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
	}

	function testShouldNotClosePositionPayFixedWhenContractIsPaused() public {
		// given
		_miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 5 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
		openSwapPayFixed(
			_userTwo,
			block.timestamp,
			TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
			TestConstants.PERCENTAGE_9_18DEC,
			TestConstants.LEVERAGE_18DEC,
			mockCase3MiltonDai
		);
        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
		// when
		vm.prank(_admin);
		mockCase3MiltonDai.pause();
		// then
		vm.expectRevert("Pausable: paused");
		mockCase3MiltonDai.closeSwapPayFixed(1);
	}

	function testShouldNotClosePositionsPayFixedWhenContractIsPaused() public {
		// given
		_miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 5 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
		iterateOpenSwapsPayFixed(_userTwo, mockCase3MiltonDai, 2, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.LEVERAGE_18DEC);
        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
		uint256[] memory payFixedSwapIds = new uint256[](2);
		payFixedSwapIds[0] = 1;
		payFixedSwapIds[1] = 2;
		uint256[] memory receiveFixedSwapIds;	
		// when
		vm.prank(_admin);
		mockCase3MiltonDai.pause();
		// then
		vm.expectRevert("Pausable: paused");
		mockCase3MiltonDai.closeSwaps(payFixedSwapIds, receiveFixedSwapIds);
	}

	function testShouldNotClosePositionReceiveFixedWhenContractIsPaused() public {
		// given
		_miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 5 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
		openSwapReceiveFixed(
			_userTwo,
			block.timestamp,
			TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
			TestConstants.ZERO,
			TestConstants.LEVERAGE_18DEC,
			mockCase3MiltonDai
		);
        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
		// when
		vm.prank(_admin);
		mockCase3MiltonDai.pause();
		// then
		vm.expectRevert("Pausable: paused");
		mockCase3MiltonDai.closeSwapReceiveFixed(1);
	}

	function testShouldNotClosePositionsReceiveFixedWhenContractIsPaused() public {
		// given
		_miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 5 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase3MiltonDai, 2, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.LEVERAGE_18DEC);
        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
		uint256[] memory receiveFixedSwapIds = new uint256[](2);
		receiveFixedSwapIds[0] = 1;
		receiveFixedSwapIds[1] = 2;
		uint256[] memory payFixedSwapIds;	
		// when
		vm.prank(_admin);
		mockCase3MiltonDai.pause();
		// then
		vm.expectRevert("Pausable: paused");
		mockCase3MiltonDai.closeSwaps(payFixedSwapIds, receiveFixedSwapIds);
	}

	function testShouldNotClosePositionPayFixedWithEmergencyFunctionWhenContractIsPaused() public {
		// given
		_miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 5 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
		openSwapPayFixed(
			_userTwo,
			block.timestamp,
			TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
			TestConstants.PERCENTAGE_9_18DEC,
			TestConstants.LEVERAGE_18DEC,
			mockCase3MiltonDai
		);
        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
		// when
		vm.prank(_admin);
		mockCase3MiltonDai.pause();
		// then
		vm.expectRevert("Ownable: caller is not the owner");
		vm.prank(_userTwo);
		mockCase3MiltonDai.emergencyCloseSwapPayFixed(1);
	}

	function testShouldNotClosePositionsPayFixedWithEmergencyFunctionWhenContractIsPaused() public {
		// given
		_miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 5 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
		iterateOpenSwapsPayFixed(_userTwo, mockCase3MiltonDai, 2, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.LEVERAGE_18DEC);
        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
		uint256[] memory payFixedSwapIds = new uint256[](2);
		payFixedSwapIds[0] = 1;
		payFixedSwapIds[1] = 2;
		// when
		vm.prank(_admin);
		mockCase3MiltonDai.pause();
		// then
		vm.expectRevert("Ownable: caller is not the owner");
		vm.prank(_userTwo);
		mockCase3MiltonDai.emergencyCloseSwapsPayFixed(payFixedSwapIds);
	}

	function testShouldNotClosePositionReceiveFixedWithEmergencyFunctionWhenContractIsPaused() public {
		// given
		_miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 5 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
		openSwapReceiveFixed(
			_userTwo,
			block.timestamp,
			TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
			TestConstants.ZERO,
			TestConstants.LEVERAGE_18DEC,
			mockCase3MiltonDai
		);
        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
		// when
		vm.prank(_admin);
		mockCase3MiltonDai.pause();
		// then
		vm.expectRevert("Ownable: caller is not the owner");
		vm.prank(_userTwo);
		mockCase3MiltonDai.emergencyCloseSwapReceiveFixed(1);
	}

	function testShouldNotClosePositionsReceiveFixedWithEmergencyFunctionWhenContractIsPaused() public {
		// given
		_miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 5 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase3MiltonDai, 2, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.LEVERAGE_18DEC);
        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
		uint256[] memory receiveFixedSwapIds = new uint256[](2);
		receiveFixedSwapIds[0] = 1;
		receiveFixedSwapIds[1] = 2;
		// when
		vm.prank(_admin);
		mockCase3MiltonDai.pause();
		// then
		vm.expectRevert("Ownable: caller is not the owner");
		vm.prank(_userTwo);
		mockCase3MiltonDai.emergencyCloseSwapsReceiveFixed(receiveFixedSwapIds);
	}

	function testShouldNotClosePositionPayFixedWithEmergencyFunctionWhenContractIsNotPausedAndNotOwner() public {
		// given
		_miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 5 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
		openSwapPayFixed(
			_userTwo,
			block.timestamp,
			TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
			TestConstants.PERCENTAGE_9_18DEC,
			TestConstants.LEVERAGE_18DEC,
			mockCase3MiltonDai
		);
        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
		// when
		vm.expectRevert("Pausable: not paused");
		vm.prank(_admin);
		mockCase3MiltonDai.emergencyCloseSwapPayFixed(1);
	}

	function testShouldNotClosePositionsPayFixedWithEmergencyFunctionWhenContractIsNotPausedAndNotOwner() public {
		// given
		_miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 5 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
		iterateOpenSwapsPayFixed(_userTwo, mockCase3MiltonDai, 2, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.LEVERAGE_18DEC);
        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
		uint256[] memory payFixedSwapIds = new uint256[](2);
		payFixedSwapIds[0] = 1;
		payFixedSwapIds[1] = 2;
		// when
		vm.expectRevert("Pausable: not paused");
		vm.prank(_admin);
		mockCase3MiltonDai.emergencyCloseSwapsPayFixed(payFixedSwapIds);
	}

	function testShouldNotClosePositionReceiveFixedWithEmergencyFunctionWhenContractIsNotPausedAndNotOwner() public {
		// given
		_miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 5 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
		openSwapReceiveFixed(
			_userTwo,
			block.timestamp,
			TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
			TestConstants.ZERO,
			TestConstants.LEVERAGE_18DEC,
			mockCase3MiltonDai
		);
        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
		// when
		vm.expectRevert("Pausable: not paused");
		vm.prank(_admin);
		mockCase3MiltonDai.emergencyCloseSwapReceiveFixed(1);
	}

	function testShouldNotClosePositionsReceiveFixedWithEmergencyFunctionWhenContractIsNotPausedAndNotOwner() public {
		// given
		_miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 5 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase3MiltonDai, 2, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.LEVERAGE_18DEC);
        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
		uint256[] memory receiveFixedSwapIds = new uint256[](2);
		receiveFixedSwapIds[0] = 1;
		receiveFixedSwapIds[1] = 2;
		// when
		vm.expectRevert("Pausable: not paused");
		vm.prank(_admin);
		mockCase3MiltonDai.emergencyCloseSwapsReceiveFixed(receiveFixedSwapIds);
	}

	function testShouldNotClosePositionDAIWhenAmountExceedsMiltonBalance() public {
		// given
		_miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
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
		_daiMockedToken.approve(address(mockCase0MiltonDai), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
		openSwapPayFixed(
			_userTwo,
			block.timestamp,
			TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
			TestConstants.PERCENTAGE_9_18DEC,
			TestConstants.LEVERAGE_18DEC,
			mockCase0MiltonDai
		);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_120_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp + TestConstants.PERIOD_27_DAYS_17_HOURS_IN_SECONDS);
		vm.prank(address(mockCase0MiltonDai));
		// when
		vm.expectRevert("ERC20: transfer amount exceeds balance");
		_daiMockedToken.transfer(_admin, 6044629098073145873530880);
	}

}

