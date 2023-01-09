// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {ProxyTester} from "foundry-upgrades/ProxyTester.sol";
import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {MiltonUtils} from "../utils/MiltonUtils.sol";
import {MiltonStorageUtils} from "../utils/MiltonStorageUtils.sol";
import {JosephUtils} from "../utils/JosephUtils.sol";
import {StanleyUtils} from "../utils/StanleyUtils.sol";
import {IporOracleUtils} from "../utils/IporOracleUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
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

contract MiltonSoapTest is
    Test,
    TestCommons,
    MiltonUtils,
    MiltonStorageUtils,
    JosephUtils,
    IporOracleUtils,
    DataUtils,
    SwapUtils,
    StanleyUtils
{
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
        _miltonSpreadModel = prepareMockSpreadModel(TestConstants.ZERO, TestConstants.ZERO, TestConstants.ZERO_INT, TestConstants.ZERO_INT);
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
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));

        (, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai)
        );
        // when
        (,, int256 soap) = calculateSoap(_userTwo, block.timestamp, mockCase0MiltonDai);
        // then
         assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateSoapDAIPayFixedWhenAddPositionThenCalculate() public {
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase1StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase1StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp); 
        openSwapPayFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC, mockCase0MiltonDai
        );
        // when
        (,, int256 soap) = calculateSoap(_userTwo, block.timestamp, mockCase0MiltonDai);
        // then
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateSoapDAIPayFixedWhenAddPositionThenCalculateAfter25Days() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed( TestConstants.PERCENTAGE_4_18DEC); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase0StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp); 
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp); 
        openSwapPayFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC, mockCase0MiltonDai
        );
        // when
        (,, int256 soap) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        // then
        assertEq(soap, -68267191075554066594);
    }

    function testShouldCalculateSoapDAIReceiveFixedWhenAddPositionThenCalculate() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.ZERO); 
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase1StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase1StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp); 
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp); 
        openSwapReceiveFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.PERCENTAGE_1_18DEC, TestConstants.LEVERAGE_18DEC, mockCase0MiltonDai
        );
        // when
        (,, int256 soap) = calculateSoap(_userTwo, block.timestamp, mockCase0MiltonDai);
        // then
         assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateSoapDAIReceiveFixedWhenAddPositionThenCalculateAfter25Days() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.ZERO);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase1StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase1StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp); 
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp); 
        openSwapReceiveFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.PERCENTAGE_1_18DEC, TestConstants.LEVERAGE_18DEC, mockCase0MiltonDai
        );
        // when
        (,, int256 soap) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        // then
        assertEq(soap, -68267191075554025634);
    }

    function testShouldCalculateSoapDAIPayFixedWhenAddAndRemovePosition() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.ZERO); 
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase1StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase1StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp); 
        openSwapPayFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC, mockCase0MiltonDai
        );
        // when
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS); 
        (,, int256 soap) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        // then
         assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateSoapDAIReceiveFixedWhenAddAndRemovePosition() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.ZERO); 
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase1StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase1StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp); 
        openSwapReceiveFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.PERCENTAGE_1_18DEC, TestConstants.LEVERAGE_18DEC, mockCase0MiltonDai
        );
        // we are expecting that Milton will lose money, so we add more liquidity
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp); 
        // when
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS); 
        (,, int256 soap) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        // then
         assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndDAIReceiveFixed18Decimals() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed( TestConstants.PERCENTAGE_4_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase1StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase1StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp); 
        // when
        openSwapPayFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC, mockCase0MiltonDai
        );
        openSwapReceiveFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.PERCENTAGE_1_18DEC, TestConstants.LEVERAGE_18DEC, mockCase0MiltonDai
        );
        (,, int256 soap) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        // then
        assertEq(soap, -136534382151108092229);
    }

    function testShouldCalculateSoapWhenUSDTPayFixedAndUSDTReceiveFixed6Decimals() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed( TestConstants.PERCENTAGE_4_18DEC); 
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 3 * 10 ** 16);
        IpToken ipTokenUsdt = getIpTokenUsdt(address(_usdtMockedToken));
        MockCase1Stanley mockCase1StanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        (ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(
            _admin,
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(mockCase1StanleyUsdt)
        );
        (ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(
            _admin,
            address(_usdtMockedToken),
            address(ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(mockCase1StanleyUsdt)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMiltonStorage(
            miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt)
        );
        prepareMockCase0MiltonUsdt(
            mockCase0MiltonUsdt,
            address(mockCase0MiltonUsdtProxy),
            address(mockCase0JosephUsdt),
            address(mockCase1StanleyUsdt)
        );
        prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
        prepareIpTokenUsdt(ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(2 * TestConstants.USD_28_000_6DEC, block.timestamp); 
        openSwapPayFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC, mockCase0MiltonUsdt
        ); //
        openSwapReceiveFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC, TestConstants.PERCENTAGE_1_18DEC, TestConstants.LEVERAGE_18DEC, mockCase0MiltonUsdt
        );
        (,, int256 soap) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonUsdt);
        // then
        assertEq(soap, -136534382151108092229);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndUSDTPayFixed() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed( TestConstants.PERCENTAGE_4_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);
        address[] memory tokenAddresses =
            getTokenAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            getIpTokenAddresses(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        ItfIporOracle iporOracle =
            getIporOracleThreeAssets(_admin, _userOne, tokenAddresses, uint32(block.timestamp), 5 * 10**16, 0);
        address[] memory mockCase1StanleyAddresses =
            getMockCase1StanleyAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages(_admin);
        address[] memory miltonStorageAddresses = getMiltonStorageAddresses(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            _admin,
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = getMockCase0MiltonAddresses(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            _admin,
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = getMockCase0JosephAddresses(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsdt(
            users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersDai(
            users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdt,
            miltonStorages.miltonStorageUsdtProxy,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageDai,
            miltonStorages.miltonStorageDaiProxy,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMockCase0MiltonUsdt(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Miltons.mockCase0MiltonUsdtProxy),
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMockCase0MiltonDai(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Miltons.mockCase0MiltonDaiProxy),
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareMockCase0JosephUsdt(
            mockCase0Josephs.mockCase0JosephUsdt, address(mockCase0Josephs.mockCase0JosephUsdtProxy)
        );
        prepareMockCase0JosephDai(
            mockCase0Josephs.mockCase0JosephDai, address(mockCase0Josephs.mockCase0JosephDaiProxy)
        );
        prepareIpTokenUsdt(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpTokenDai(_ipTokenDai, mockCase0JosephAddresses[2]);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp); 
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp); 
        // when
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            9 * TestConstants.D17,
            10 * Constants.D18,
            mockCase0Miltons.mockCase0MiltonUsdt
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            10 * Constants.D18,
            mockCase0Miltons.mockCase0MiltonDai
        );
        (,, int256 soapUsdt) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0Miltons.mockCase0MiltonUsdt);
        (,, int256 soapDai) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0Miltons.mockCase0MiltonDai);
        // then
        assertEq(soapUsdt, -68267191075554066594);
        assertEq(soapDai, -68267191075554066594);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndDAIReceiveFixedAndClosePayFixed() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed( TestConstants.PERCENTAGE_4_18DEC); 
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase1StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase1StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp); 
        openSwapPayFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC, mockCase0MiltonDai
        );
        openSwapReceiveFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.PERCENTAGE_1_18DEC, TestConstants.LEVERAGE_18DEC, mockCase0MiltonDai
        );
        // when
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS); 
        (,, int256 soap) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        // then
        assertEq(soap, -68267191075554025634);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndDAIReceiveFixedAndCloseReceiveFixed() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed( TestConstants.PERCENTAGE_4_18DEC); 
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase1StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase1StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp); 
        openSwapPayFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC, mockCase0MiltonDai
        );
        openSwapReceiveFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.PERCENTAGE_1_18DEC, TestConstants.LEVERAGE_18DEC, mockCase0MiltonDai
        );
        // when
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(2, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        (,, int256 soap) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        // then
        assertEq(soap, -68267191075554066594);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndUSDTReceiveFixedAndRemoveReceiveFixedPositionAfter25Days()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed( TestConstants.PERCENTAGE_4_18DEC); 
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC); 
        address[] memory tokenAddresses =
            getTokenAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            getIpTokenAddresses(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        ItfIporOracle iporOracle =
            getIporOracleThreeAssets(_admin, _userOne, tokenAddresses, uint32(block.timestamp), 5 * 10**16, 0);
        address[] memory mockCase1StanleyAddresses =
            getMockCase1StanleyAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages(_admin);
        address[] memory miltonStorageAddresses = getMiltonStorageAddresses(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            _admin,
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = getMockCase0MiltonAddresses(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            _admin,
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = getMockCase0JosephAddresses(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsdt(
            users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersDai(
            users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdt,
            miltonStorages.miltonStorageUsdtProxy,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageDai,
            miltonStorages.miltonStorageDaiProxy,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMockCase0MiltonUsdt(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Miltons.mockCase0MiltonUsdtProxy),
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMockCase0MiltonDai(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Miltons.mockCase0MiltonDaiProxy),
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareMockCase0JosephUsdt(
            mockCase0Josephs.mockCase0JosephUsdt, address(mockCase0Josephs.mockCase0JosephUsdtProxy)
        );
        prepareMockCase0JosephDai(
            mockCase0Josephs.mockCase0JosephDai, address(mockCase0Josephs.mockCase0JosephDaiProxy)
        );
        prepareIpTokenUsdt(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpTokenDai(_ipTokenDai, mockCase0JosephAddresses[2]);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp); 
        // when
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0Miltons.mockCase0MiltonUsdt
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0Miltons.mockCase0MiltonDai
        );
        // we are expecting that Milton will lose money on receive fixed, so we add more liquidity
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC, block.timestamp);
        // when
        vm.prank(_userTwo);
        mockCase0Miltons.mockCase0MiltonUsdt.itfCloseSwapReceiveFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        (,, int256 soapUsdt) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0Miltons.mockCase0MiltonUsdt);
        (,, int256 soapDai) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0Miltons.mockCase0MiltonDai);
        // then
        assertEq(soapUsdt, 0);
        assertEq(soapDai, -68267191075554066594);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndChangeIbtPriceAndWait25DaysAndThenCalculateSoap18Decimals()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed( TestConstants.PERCENTAGE_4_18DEC); 
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase0StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp); 
        openSwapPayFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC, mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_120_18DEC, block.timestamp); 
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS); 
            // when
        (,, int256 soap) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        // then
        assertEq(soap, 7918994164764269327487);
    }

    function testShouldCalculateSoapWhenUSDTPayFixedAndChangeIbtPriceAndWait25DaysAndThenCalculateSoap6Decimals()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed( TestConstants.PERCENTAGE_4_18DEC); 
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 3 * 10 ** 16);
        IpToken ipTokenUsdt = getIpTokenUsdt(address(_usdtMockedToken));
        MockCase1Stanley mockCase1StanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        (ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(
            _admin,
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(mockCase1StanleyUsdt)
        );
        (ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(
            _admin,
            address(_usdtMockedToken),
            address(ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(mockCase1StanleyUsdt)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMiltonStorage(
            miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt)
        );
        prepareMockCase0MiltonUsdt(
            mockCase0MiltonUsdt,
            address(mockCase0MiltonUsdtProxy),
            address(mockCase0JosephUsdt),
            address(mockCase1StanleyUsdt)
        );
        prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
        prepareIpTokenUsdt(ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(2 * TestConstants.USD_28_000_6DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC, mockCase0MiltonUsdt
        ); //
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_120_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS); 
        // when
        (,, int256 soap) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonUsdt);
        // then
        assertEq(soap, 7918994164764269327487);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndChangeIbtPriceAndCalculateSoapAfter28DaysAndCalculateSoapAfter50DaysAndCompare(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed( TestConstants.PERCENTAGE_4_18DEC); 
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase0StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp); 
        openSwapPayFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC, mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_120_18DEC, block.timestamp); 
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS); 
        // when
        // then
        (,, int256 soap28Days) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(soap28Days, 7935378290622402313573);
        (,, int256 soap50Days) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(soap50Days, 8055528546915377478426);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndWait25DaysAndDAIPayFixedAndWait25DaysAndThenCalculateSoap()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed( TestConstants.PERCENTAGE_4_18DEC); 
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase0StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
            // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC, mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // then
        (,, int256 soap50Days) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(soap50Days, -205221535441070939561);
    }

    function testShouldCalculateSoapWhenDAYPayFixedAndWait25DaysAndUpdateIPORAndDAIPayFixedAndWait25DaysAndUpdateIPORAndThenCalculateSoap(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed( TestConstants.PERCENTAGE_4_18DEC); 
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase0StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp); 
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC, mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS); 
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            10 * Constants.D18,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS); 
        // then
        (,, int256 soap50Days) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(soap50Days, -205221535441070939561);
    }

    function testShouldCalculateExactlyTheSameSoapWithAndWithoutUpdateIPORWithTheSameIndexValueWhenDAIPayFixed25And50DaysPeriod(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed( TestConstants.PERCENTAGE_4_18DEC); 
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase0StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp); 
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC, mockCase0MiltonDai
        );
        (,, int256 soapBeforeUpdateIndex) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS); 
        (,, int256 soapAfterUpdateIndex25Days) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        (,, int256 soapAfterUpdateIndex50Days) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        // then
        assertEq(soapBeforeUpdateIndex, -136534382151108133189);
        assertEq(soapAfterUpdateIndex25Days, -136534382151108133189);
        assertEq(soapAfterUpdateIndex50Days, -136534382151108133189);
    }

    function testShouldCalculateNegativeSoapWhenDAIPayFixedAndWat25DaysAndUpdateIbtPriceAfterSwapOpened() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed( TestConstants.PERCENTAGE_4_18DEC); 
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase0StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp); 
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC, mockCase0MiltonDai
        );
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp + TestConstants.PERIOD_1_DAY_IN_SECONDS); 
        (,, int256 soapRightAfterOpenedPayFixedSwap) =
            calculateSoap(_userTwo, block.timestamp + 86500, mockCase0MiltonDai);
        // then
        assertLt(soapRightAfterOpenedPayFixedSwap, 0);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAnd2xAndWait50Days() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed( TestConstants.PERCENTAGE_4_18DEC); 
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase0StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp); 
            // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo, block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC, mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS); 
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS); 
        (,, int256 soap50Days) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        // then
        assertEq(soap50Days, -205221535441070939561);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIPayFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndDAIPayFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75DaysComplexTotalAmount(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed( TestConstants.PERCENTAGE_4_18DEC); 
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase0StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp); 
            // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo, block.timestamp, 1000348983489384893923, 9 * TestConstants.D17, 1000 * Constants.D18, mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS); 
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1492747383748202058744,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS); 
        vm.prank(_userOne);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.prank(_userOne);
        mockCase0MiltonDai.itfCloseSwapPayFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        // then
        (,, int256 soap75Days) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(soap75Days, 0);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIPayFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndDAIPayFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75DaysSimpleTotalAmount(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed( TestConstants.PERCENTAGE_4_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase0StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC); 
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
            // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo, block.timestamp, 1040000000000000000000, 9 * TestConstants.D17, 1000 * Constants.D18, mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS); 
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1040000000000000000000,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS); 
        vm.prank(_userOne);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.prank(_userOne);
        mockCase0MiltonDai.itfCloseSwapPayFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        // then
        (,, int256 soap75Days) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(soap75Days, 0);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIPayFixedAtIPOR6PercentAndIPOR3PercentAfter25DaysAndDAIPayFixedAndIPOR3PercentAfter50DaysAndCloseAllSwapsAfter75Days(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_7_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase0StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
            // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp); 
        openSwapPayFixed(
            _userTwo, block.timestamp, 1000348983489384893923, 9 * TestConstants.D17, 1000 * Constants.D18, mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS); 
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1492747383748202058744,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS); 
        vm.prank(_userOne);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.prank(_userOne);
        mockCase0MiltonDai.itfCloseSwapPayFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        // then
        (,, int256 soap75Days) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(soap75Days, 0);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIReceiveFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndDAIReceiveFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75Days(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.ZERO); 
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(2); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase0StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(38877399621396944);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp); 
            // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo, block.timestamp, 1000348983489384893923, TestConstants.PERCENTAGE_1_18DEC, TestConstants.LEVERAGE_1000_18DEC, mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS); 
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1492747383748202058744,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS); 
        vm.prank(_userOne);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.prank(_userOne);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        // then
        (,, int256 soap75Days) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(soap75Days, 0);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIReceiveFixedAtIPOR6PercentAndIPOR3PercentAfter25DaysAndDAIReceiveFixedAndIPOR3PercentAfter50DaysAndCloseAllSwapsAfter75Days(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.ZERO); 
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(5); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase0StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp); 
            // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp); 
        openSwapReceiveFixed(
            _userTwo, block.timestamp, 1000348983489384893923, TestConstants.PERCENTAGE_1_18DEC, TestConstants.LEVERAGE_1000_18DEC, mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS); 
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1492747383748202058744,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS); 
        vm.prank(_userOne);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.prank(_userOne);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        // then
        (,, int256 soap75Days) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(soap75Days, 0);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIReceiveFixedAtIPOR6PercentAndIPOR6PercentAfter25DaysAndDAIReceiveFixedAndIPOR3PercentAfter50DaysAndCloseAllSwapsAfter75Days(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.ZERO); 
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_5_18DEC); 
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai,
            address(mockCase0MiltonDaiProxy),
            address(mockCase0JosephDai),
            address(mockCase0StanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC); 
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp); 
            // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp); 
        openSwapReceiveFixed(
            _userTwo, block.timestamp, 1000348983489384893923, TestConstants.PERCENTAGE_1_18DEC, TestConstants.LEVERAGE_1000_18DEC, mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS); 
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1492747383748202058744,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS); 
        vm.prank(_userOne);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.prank(_userOne);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        // then
        (,, int256 soap75Days) = calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(soap75Days, 0);
    }
}
