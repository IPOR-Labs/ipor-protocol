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
import "../../contracts/mocks/tokens/MockTestnetTokenUsdt.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdc.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenDai.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase6MiltonDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";
import "../../contracts/interfaces/types/MiltonStorageTypes.sol";
import "../../contracts/interfaces/types/IporTypes.sol";

contract MiltonUtilisationRateTest is
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

    function setUp() public {
        _miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.ZERO, TestConstants.ZERO, TestConstants.ZERO_INT, TestConstants.ZERO_INT
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

    function testShouldOpenPayFixedPositionWhenLiquidityPoolUtilizationPerLegIsNotExceededAndDefaultUtilization()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldOpenReceiveFixedPositionWhenLiquidityPoolUtilizationPerLegIsNotExceededAndDefaultUtilization()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldOpenPayFixedPositionWhenLiquidityPoolUtilizationPerLegIsNotExceededAndCustomUtilization()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase6MiltonDaiProxy, MockCase6MiltonDai mockCase6MiltonDai) = getMockCase6MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase6MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase6MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase6MiltonDai)
        );
        prepareMockCase6MiltonDai(
            mockCase6MiltonDai, address(mockCase6MiltonDaiProxy), address(mockCase0JosephDai), address(stanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_100_000_18DEC, block.timestamp);
        // when
        vm.prank(_userTwo);
        mockCase6MiltonDai.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldOpenReceiveFixedPositionWhenLiquidityPoolUtilizationPerLegIsNotExceededAndCustomUtilization()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase6MiltonDaiProxy, MockCase6MiltonDai mockCase6MiltonDai) = getMockCase6MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase6MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase6MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase6MiltonDai)
        );
        prepareMockCase6MiltonDai(
            mockCase6MiltonDai, address(mockCase6MiltonDaiProxy), address(mockCase0JosephDai), address(stanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_100_000_18DEC, block.timestamp);
        // when
        vm.prank(_userTwo);
        mockCase6MiltonDai.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPayFixedPositionWhenLiquidityPoolUtilizationPerLegIsExceededAndDefaultUtilization()
        public
    {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp, 14000 * TestConstants.D18, TestConstants.PERCENTAGE_6_18DEC, TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPayFixedPositionWhenLiquidityPoolUtilizationPerLegIsExceededAndCustomUtilization()
        public
    {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase6MiltonDaiProxy, MockCase6MiltonDai mockCase6MiltonDai) = getMockCase6MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase6MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase6MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase6MiltonDai)
        );
        prepareMockCase6MiltonDai(
            mockCase6MiltonDai, address(mockCase6MiltonDaiProxy), address(mockCase0JosephDai), address(stanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        mockCase6MiltonDai.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenReceiveFixedPositionWhenLiquidityPoolUtilizationPerLegIsExceededAndDefaultUtilization()
        public
    {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapReceiveFixed(
            block.timestamp, 14000 * TestConstants.D18, TestConstants.PERCENTAGE_1_18DEC, TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenReceiveFixedPositionWhenLiquidityPoolUtilizationPerLegIsExceededAndCustomUtilization()
        public
    {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 3 * 10 ** 16);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase6MiltonDaiProxy, MockCase6MiltonDai mockCase6MiltonDai) = getMockCase6MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase6MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase6MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase6MiltonDai)
        );
        prepareMockCase6MiltonDai(
            mockCase6MiltonDai, address(mockCase6MiltonDaiProxy), address(mockCase0JosephDai), address(stanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        mockCase6MiltonDai.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }
}
