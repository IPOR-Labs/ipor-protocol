
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {ProxyTester} from "foundry-upgrades/ProxyTester.sol";
import "../TestCommons.sol";
import  {DataUtils} from "../utils/DataUtils.sol";
import  {MiltonUtils} from "../utils/MiltonUtils.sol";
import  {MiltonStorageUtils} from "../utils/MiltonStorageUtils.sol";
import  {JosephUtils} from "../utils/JosephUtils.sol";
import  {StanleyUtils} from "../utils/StanleyUtils.sol";
import  {IporOracleUtils} from "../utils/IporOracleUtils.sol";
import  {SwapUtils} from "../utils/SwapUtils.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/UsdtMockedToken.sol";
import "../../contracts/mocks/tokens/UsdcMockedToken.sol";
import "../../contracts/mocks/tokens/DaiMockedToken.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/amm/MiltonStorage.sol";

contract MiltonSoapTest is Test, TestCommons, MiltonUtils, MiltonStorageUtils, JosephUtils, IporOracleUtils, DataUtils, SwapUtils, StanleyUtils {
	MockSpreadModel internal _miltonSpreadModel;
	UsdtMockedToken internal _usdtMockedToken;
	UsdcMockedToken internal _usdcMockedToken;
	DaiMockedToken internal _daiMockedToken;
	IpToken internal _ipTokenUsdt;
	IpToken internal _ipTokenUsdc;
	IpToken internal _ipTokenDai;
	address internal _admin;
	address internal _userOne;
	address internal _userTwo;
	address internal _userThree;
	address internal _liquidityProvider;

    function setUp() public {
		_miltonSpreadModel = prepareMockSpreadModel(0, 0, 0, 0);
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

	function testShouldCalculateSoapWhenNoDerivativesSoapEqualZero() public {
		// given
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3*10**16); 
		MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));




		(, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		(, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(_admin, address(_daiMockedToken), address(iporOracle), address(miltonStorageDai), address(_miltonSpreadModel), address(mockCase1StanleyDai));
		// when 
		(,, int256 soap) =  calculateSoap(_userTwo, block.timestamp, mockCase0MiltonDai);
		// then
		assertEq(soap, 0);
	}

    function testShouldCalculateSoapDAIPayFixedWhenAddPositionThenCalculate() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3*10**16); 
		MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		(ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(_admin, address(_daiMockedToken), address(iporOracle), address(miltonStorageDai), address(_miltonSpreadModel), address(mockCase1StanleyDai));
		(ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(_admin, address(_daiMockedToken), address(_ipTokenDai), address(mockCase0MiltonDai), address(miltonStorageDai), address(mockCase1StanleyDai));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
		prepareMiltonStorage(miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai));
		prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0MiltonDaiProxy), address(mockCase0JosephDai), address(mockCase1StanleyDai));
		prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
		prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 5*10**16, block.timestamp); // 3%, PERCENTAGE_3_18DEC
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // USD_28_000_18DEC
        openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 9*10**17,10*Constants.D18, mockCase0MiltonDai);
        // when
		(,, int256 soap) =  calculateSoap(_userTwo, block.timestamp, mockCase0MiltonDai);
		// then
		assertEq(soap, 0);
    }

    function testShouldCalculateSoapDAIPayFixedWhenAddPositionThenCalculateAfter25Days() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(4*10**16); // 4%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3*10**16); 
		MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		(ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(_admin, address(_daiMockedToken), address(iporOracle), address(miltonStorageDai), address(_miltonSpreadModel), address(mockCase0StanleyDai));
		(ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(_admin, address(_daiMockedToken), address(_ipTokenDai), address(mockCase0MiltonDai), address(miltonStorageDai), address(mockCase0StanleyDai));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
		prepareMiltonStorage(miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai));
		prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0MiltonDaiProxy), address(mockCase0JosephDai), address(mockCase0StanleyDai));
		prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
		prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 3*10**16, block.timestamp); // 3%, PERCENTAGE_3_18DEC
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // USD_28_000_18DEC
        openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 9*10**17,10*Constants.D18, mockCase0MiltonDai); 
        // when
		(,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonDai);
		// then
		assertEq(soap, -68267191075554066594);
    }

    function testShouldCalculateSoapDAIReceiveFixedWhenAddPositionThenCalculate() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(0); // 0%
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(2*10**16); // 2%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3*10**16); 
		MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		(ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(_admin, address(_daiMockedToken), address(iporOracle), address(miltonStorageDai), address(_miltonSpreadModel), address(mockCase1StanleyDai));
		(ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(_admin, address(_daiMockedToken), address(_ipTokenDai), address(mockCase0MiltonDai), address(miltonStorageDai), address(mockCase1StanleyDai));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
		prepareMiltonStorage(miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai));
		prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0MiltonDaiProxy), address(mockCase0JosephDai), address(mockCase1StanleyDai));
		prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
		prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 3*10**16, block.timestamp); // 3%, PERCENTAGE_3_18DEC
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // USD_28_000_18DEC
        openSwapReceiveFixed(_userTwo, block.timestamp, 10000*Constants.D18, 1*10**16,10*Constants.D18, mockCase0MiltonDai); 
        // when
		(,, int256 soap) =  calculateSoap(_userTwo, block.timestamp, mockCase0MiltonDai);
		// then
		assertEq(soap, 0);
    }

    function testShouldCalculateSoapDAIReceiveFixedWhenAddPositionThenCalculateAfter25Days() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(0); // 0%
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(2*10**16); // 2%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3*10**16); 
		MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		(ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(_admin, address(_daiMockedToken), address(iporOracle), address(miltonStorageDai), address(_miltonSpreadModel), address(mockCase1StanleyDai));
		(ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(_admin, address(_daiMockedToken), address(_ipTokenDai), address(mockCase0MiltonDai), address(miltonStorageDai), address(mockCase1StanleyDai));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
		prepareMiltonStorage(miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai));
		prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0MiltonDaiProxy), address(mockCase0JosephDai), address(mockCase1StanleyDai));
		prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
		prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 3*10**16, block.timestamp); // 3%, PERCENTAGE_3_18DEC
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // USD_28_000_18DEC
        openSwapReceiveFixed(_userTwo, block.timestamp, 10000*Constants.D18, 1*10**16,10*Constants.D18, mockCase0MiltonDai); 
        // when
		(,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonDai);
		// then
		assertEq(soap, -68267191075554025634);
    }

    function testShouldCalculateSoapDAIPayFixedWhenAddAndRemovePosition() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(0); // 0%
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(2*10**16); // 2%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3*10**16);
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(_admin, address(_daiMockedToken), address(iporOracle), address(miltonStorageDai), address(_miltonSpreadModel), address(mockCase1StanleyDai));
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(_admin, address(_daiMockedToken), address(_ipTokenDai), address(mockCase0MiltonDai), address(miltonStorageDai), address(mockCase1StanleyDai));
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0MiltonDaiProxy), address(mockCase0JosephDai), address(mockCase1StanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), 3*10**16, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // USD_28_000_18DEC
        openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 9*10**17,10*Constants.D18, mockCase0MiltonDai); 
        // when
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + 2160000); // 25 days
		(,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonDai);
		// then
		assertEq(soap, 0);
    }

    function testShouldCalculateSoapDAIReceiveFixedWhenAddAndRemovePosition() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(0); // 0%
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(2*10**16); // 2%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3*10**16);
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(_admin, address(_daiMockedToken), address(iporOracle), address(miltonStorageDai), address(_miltonSpreadModel), address(mockCase1StanleyDai));
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(_admin, address(_daiMockedToken), address(_ipTokenDai), address(mockCase0MiltonDai), address(miltonStorageDai), address(mockCase1StanleyDai));
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0MiltonDaiProxy), address(mockCase0JosephDai), address(mockCase1StanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), 3*10**16, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // USD_28_000_18DEC
        openSwapReceiveFixed(_userTwo, block.timestamp, 10000*Constants.D18, 1*10**16,10*Constants.D18, mockCase0MiltonDai); 
        // we are expecting that Milton will lose money, so we add more liquidity
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(10000*Constants.D18, block.timestamp); // TC_TOTAL_AMOUNT_10_000_18DEC
        // when
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + 2160000); // 25 days
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonDai);
        // then
        assertEq(soap, 0);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndDaiReceiveFixed18Decimals() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(4*10**16); // 4%
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(2*10**16); // 2%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3*10**16);
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(_admin, address(_daiMockedToken), address(iporOracle), address(miltonStorageDai), address(_miltonSpreadModel), address(mockCase1StanleyDai));
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(_admin, address(_daiMockedToken), address(_ipTokenDai), address(mockCase0MiltonDai), address(miltonStorageDai), address(mockCase1StanleyDai));
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0MiltonDaiProxy), address(mockCase0JosephDai), address(mockCase1StanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), 3*10**16, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2*28000*Constants.D18, block.timestamp); // USD_28_000_18DEC
        // when
        openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 9*10**17,10*Constants.D18, mockCase0MiltonDai);
        openSwapReceiveFixed(_userTwo, block.timestamp, 10000*Constants.D18, 1*10**16,10*Constants.D18, mockCase0MiltonDai); 
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonDai);
        // then
        assertEq(soap, -136534382151108092229);
    }

    function testShouldCalculateSoapWhenUSDTPayFixedAndUsdtReceiveFixed6Decimals() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(4*10**16); // 4%
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(2*10**16); // 2%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 3*10**16);
        IpToken ipTokenUsdt = getIpTokenUsdt(address(_usdtMockedToken));
        MockCase1Stanley mockCase1StanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        (ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(mockCase1StanleyUsdt));
        (ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(mockCase1StanleyUsdt));
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(mockCase1StanleyUsdt));
        prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
        prepareIpTokenUsdt(ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 3*10**16, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(2*28000*10**6, block.timestamp); // 
        openSwapPayFixed(_userTwo, block.timestamp, 10000*10**6, 9*10**17,10*Constants.D18, mockCase0MiltonUsdt); //
        openSwapReceiveFixed(_userTwo, block.timestamp, 10000*10**6, 1*10**16,10*Constants.D18, mockCase0MiltonUsdt); 
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonUsdt);
        // then
        assertEq(soap, -136534382151108092229);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndUsdtPayFixed() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(4*10**16); // 4%
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(0); // 0%
		address[] memory tokenAddresses = getTokenAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
		address[] memory ipTokenAddresses = getIpTokenAddresses(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		ItfIporOracle iporOracle = getIporOracleThreeAssets(_admin, _userOne, tokenAddresses, uint32(block.timestamp), 5*10**16, 0); 
		address[] memory mockCase1StanleyAddresses = getMockCase1StanleyAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
		MiltonStorages memory miltonStorages = getMiltonStorages(_admin);
		address[] memory miltonStorageAddresses = getMiltonStorageAddresses(address(miltonStorages.miltonStorageUsdt), address(miltonStorages.miltonStorageUsdc), address(miltonStorages.miltonStorageDai));
		MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(_admin, address(iporOracle), address(_miltonSpreadModel), address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken), miltonStorageAddresses, mockCase1StanleyAddresses);
		address[] memory mockCase0MiltonAddresses = getMockCase0MiltonAddresses(address(mockCase0Miltons.mockCase0MiltonUsdt), address(mockCase0Miltons.mockCase0MiltonUsdc), address(mockCase0Miltons.mockCase0MiltonDai));
		MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(_admin, tokenAddresses, ipTokenAddresses, mockCase0MiltonAddresses, miltonStorageAddresses, mockCase1StanleyAddresses);
		address[] memory mockCase0JosephAddresses = getMockCase0JosephAddresses(address(mockCase0Josephs.mockCase0JosephUsdt), address(mockCase0Josephs.mockCase0JosephUsdc), address(mockCase0Josephs.mockCase0JosephDai));
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0Josephs.mockCase0JosephUsdt), address(mockCase0Miltons.mockCase0MiltonUsdt));
		prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0Josephs.mockCase0JosephDai), address(mockCase0Miltons.mockCase0MiltonDai));
		prepareMiltonStorage(miltonStorages.miltonStorageUsdt, miltonStorages.miltonStorageUsdtProxy, address(mockCase0Josephs.mockCase0JosephUsdt), address(mockCase0Miltons.mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorages.miltonStorageDai, miltonStorages.miltonStorageDaiProxy, address(mockCase0Josephs.mockCase0JosephDai), address(mockCase0Miltons.mockCase0MiltonDai));
		prepareMockCase0MiltonUsdt(mockCase0Miltons.mockCase0MiltonUsdt, address(mockCase0Miltons.mockCase0MiltonUsdtProxy), address(mockCase0Josephs.mockCase0JosephUsdt), mockCase1StanleyAddresses[0]);
		prepareMockCase0MiltonDai(mockCase0Miltons.mockCase0MiltonDai, address(mockCase0Miltons.mockCase0MiltonDaiProxy), address(mockCase0Josephs.mockCase0JosephDai), mockCase1StanleyAddresses[2]);
		prepareMockCase0JosephUsdt(mockCase0Josephs.mockCase0JosephUsdt, address(mockCase0Josephs.mockCase0JosephUsdtProxy));
		prepareMockCase0JosephDai(mockCase0Josephs.mockCase0JosephDai, address(mockCase0Josephs.mockCase0JosephDaiProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, mockCase0JosephAddresses[0]);
		prepareIpTokenDai(_ipTokenDai, mockCase0JosephAddresses[2]);
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 3*10**16, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_daiMockedToken), 3*10**16, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(28000*10**6, block.timestamp); //
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); //
        // when
        openSwapPayFixed(_userTwo, block.timestamp, 10000*10**6, 9*10**17,10*Constants.D18, mockCase0Miltons.mockCase0MiltonUsdt);
        openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 9*10**17,10*Constants.D18, mockCase0Miltons.mockCase0MiltonDai);
        (,, int256 soapUsdt) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0Miltons.mockCase0MiltonUsdt);
        (,, int256 soapDai) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0Miltons.mockCase0MiltonDai);
        // then
        assertEq(soapUsdt, -68267191075554066594);
        assertEq(soapDai, -68267191075554066594);
    }

}